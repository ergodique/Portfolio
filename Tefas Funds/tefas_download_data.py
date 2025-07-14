#!/usr/bin/env python3
"""
TEFAS Fon Verisi İndirme Script'i
=================================

Bu script TEFAS'ta bulunan tüm fonların geçmiş fiyat verilerini indirir
ve tek bir parquet dosyasında birleştirir.

Test modunda: İlk 5 fon ile çalışır
Üretim modunda: Tüm fonları işler

Kullanım:
    python tefas_download_data.py --test         # İlk 5 fon
    python tefas_download_data.py --full         # Tüm fonlar
    python tefas_download_data.py --resume       # Yarım kalan işi devam ettir
"""

import sys
import os
import time
import logging
import argparse
import certifi
from datetime import datetime, timedelta
from dateutil.relativedelta import relativedelta
from pathlib import Path

# ---------------------------------------------------------------------------
# LOGGING SETUP – her çalıştırma için ayrı dosya
# ---------------------------------------------------------------------------
# log/ klasörü oluştur ve zaman damgalı bir dosya adı hazırla
log_dir = Path("log")
log_dir.mkdir(exist_ok=True)
_log_file = log_dir / f"tefas_download_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"

# Gerekli modülleri import et
import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq

# borsa-mcp-main klasörünü path'e ekle
# current_dir = Path(__file__).parent
# project_root = current_dir.parent / "borsa-mcp-main"
# sys.path.insert(0, str(project_root))

from providers.tefas_provider import TefasProvider
from tls12_adapter import TLS12Adapter

# Logging ayarları – hem dosya hem stdout
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(_log_file, encoding='utf-8'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Komut satırını logla
logger.info("CMD: %s", " ".join(sys.argv))

class TefasDataDownloader:
    """TEFAS fon verilerini toplu olarak indiren sınıf"""
    
    def __init__(self, test_mode=True, years_back=0, months_back=0, codes_list=None, output_filename=None):
        """
        Args:
            test_mode (bool): True ise sadece ilk 5 fon, False ise tüm fonlar
            years_back (int): Kaç yıl geriye gidilecek (opsiyonel)
            months_back (int): Kaç ay geriye gidilecek (opsiyonel)
            codes_list (list[str]|None): Test modunda indirilecek fon kodları listesi
            output_filename (str|None): Parquet çıktısının dosya adı/yolu (varsayılan otomatik)
        """
        self.test_mode = test_mode
        self.years_back = years_back or 0
        self.months_back = months_back or 0
        # Test modu için kullanıcı tarafından verilen fon kodları
        if codes_list:
            self.codes_list = [c.strip().upper() for c in codes_list if c.strip()]
        else:
            self.codes_list = []
        self.provider = self._setup_provider()
        self.chunk_size_days = 60  # Her istekte 60 günlük veri - TEFAS sunucusu için daha hafif
        self.request_delay = 3  # İstekler arası bekleme süresi (saniye) - artırıldı
        
        # Dosya yolları
        self.output_dir = Path("data")
        self.output_dir.mkdir(exist_ok=True)

        # Çıktı dosyası kullanıcı tarafından belirtilmiş mi?
        if output_filename and str(output_filename).strip():
            # Kullanıcı yalnızca dosya adını parametre olarak verebilir.
            # Verilen değerde dizin bilgisi olsa bile yoksayılır; daima data/ altında yazılır.
            filename_only = Path(str(output_filename).strip()).name
            self.output_file = self.output_dir / filename_only
        else:
            # Varsayılan isimler
            self.output_file = self.output_dir / ("tefas_test_data.parquet" if test_mode else "tefas_all_data.parquet")
        self.progress_file = self.output_dir / "download_progress.json"
        
    def _setup_provider(self):
        """TefasProvider'ı yapılandır"""
        logger.info("TefasProvider yapılandırılıyor...")
        
        tp = TefasProvider()
        
        # TLS 1.2 adapter ekle
        try:
            tp.session.mount("https://", TLS12Adapter())
            tp.session.verify = certifi.where()
        except Exception as e:
            logger.warning(f"TLS adapter ayarlanamadı: {e}")
        
        # Headers ayarla
        tp.session.headers.update({
            "User-Agent": ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                          "AppleWebKit/537.36 (KHTML, like Gecko) "
                          "Chrome/126.0 Safari/537.36"),
            "X-Requested-With": "XMLHttpRequest",
            "Origin": tp.base_url,
            "Referer": f"{tp.base_url}/TarihselVeriler.aspx"
        })
        
        # İlk session başlatma - birkaç kez dene
        for attempt in range(3):
            try:
                response = tp.session.get(tp.base_url, timeout=15)
                if response.status_code == 200:
                    logger.info("Session başarıyla başlatıldı")
                    break
                else:
                    logger.warning(f"Session başlatma: HTTP {response.status_code}")
            except Exception as e:
                logger.warning(f"Session başlatma deneme {attempt+1}/3: {e}")
                if attempt < 2:
                    time.sleep(2)
                else:
                    logger.error("Session başlatılamadı, devam ediliyor...")
        
        return tp
    
    def get_fund_list(self):
        """Tüm fonların listesini al"""
        logger.info("Fon listesi alınıyor...")
        
        try:
            all_funds = self.provider._get_takasbank_fund_list()
            if not all_funds:
                raise RuntimeError("Fon listesi alınamadı")
            
            logger.info(f"Toplam {len(all_funds)} fon bulundu")
            
            if self.test_mode:
                if not self.codes_list:
                    raise ValueError("Test modu için --codes parametresi ile en az bir fon kodu belirtmelisiniz")

                # Fon kodlarını sözlükten seç
                fund_map = {f['fon_kodu']: f for f in all_funds}
                selected_funds = []
                for code in self.codes_list:
                    if code in fund_map:
                        selected_funds.append(fund_map[code])
                        logger.info(f"[LIST] {code} - Listeden seçildi")
                    else:
                        logger.warning(f"[LIST] {code} - Fon listesinde bulunamadı, atlanıyor")

                if not selected_funds:
                    raise ValueError("Belirtilen fon kodlarından hiçbiri Takasbank listesinde bulunamadı")

                all_funds = selected_funds
                logger.info(f"Test modu: {len(all_funds)} fon seçildi: {', '.join(self.codes_list)}")
            
            return all_funds
            
        except Exception as e:
            logger.error(f"Fon listesi alma hatası: {e}")
            raise
    
    def fetch_fund_chunk(self, fund_code, start_date, end_date, retries=2):
        """Bir fon için belirli tarih aralığında veri al"""
        for attempt in range(retries):
            try:
                # Her denemede session'ı yenile
                if attempt > 0:
                    logger.debug(f"{fund_code}: Session yenileniyor...")
                    self.provider.session.get(self.provider.base_url, timeout=10)
                    time.sleep(1)
                
                result = self.provider.get_fund_performance(
                    fund_code, 
                    start_date.strftime("%Y-%m-%d"), 
                    end_date.strftime("%Y-%m-%d")
                )
                
                # Error message kontrolü
                if result.get("error_message"):
                    logger.warning(f"{fund_code}: API hatası: {result['error_message']}")
                    if "No historical data found" in result["error_message"]:
                        logger.warning(f"{fund_code}: {start_date} - {end_date} = veri yok")
                        return []
                    else:
                        raise Exception(result["error_message"])
                
                price_history = result.get("fiyat_geçmisi", [])
                if price_history:
                    logger.debug(f"{fund_code}: {start_date} - {end_date} = {len(price_history)} kayıt")
                    return price_history
                else:
                    logger.warning(f"{fund_code}: {start_date} - {end_date} = veri yok")
                    return []
                    
            except Exception as e:
                wait_time = 3 + attempt  # Daha basit bekleme süresi
                error_msg = str(e)
                
                # Connection Reset hatası için session'ı tamamen yenile
                if "ConnectionResetError" in error_msg or "Connection aborted" in error_msg:
                    logger.warning(f"{fund_code}: Bağlantı kesildi, session tamamen yenileniyor...")
                    self._setup_provider()  # Session'ı tamamen yenile
                elif "Expecting value" in error_msg or "JSON" in error_msg:
                    logger.warning(f"{fund_code}: JSON parse hatası, session yenileniyor...")
                    self.provider.session.get(self.provider.base_url, timeout=10)
                else:
                    logger.warning(f"{fund_code}: Deneme {attempt+1}/{retries} başarısız: {error_msg}")
                
                if attempt < retries - 1:
                    logger.info(f"{wait_time} saniye bekleniyor...")
                    time.sleep(wait_time)
                else:
                    logger.error(f"{fund_code}: Tüm denemeler başarısız")
                    return []
        
        return []
    
    def get_fund_category(self, fund_code, fund_name):
        """Fon kategorisini TEFAS API'sinden al, başarısızsa fon adından tahmin et"""
        try:
            fund_detail = self.provider.get_fund_detail_alternative(fund_code)
            category = fund_detail.get('fon_kategori', '')
            if category:
                return category
        except Exception as e:
            logger.warning(f"{fund_code}: API'den kategori alınamadı: {e}")
        
        # API'den alınamazsa fon adından tahmin et
        category = self._guess_category_from_name(fund_name)
        if category:
            logger.info(f"{fund_code}: Fon adından tahmin edilen kategori: {category}")
        else:
            logger.warning(f"{fund_code}: Kategori tahmin edilemedi")
        return category
    
    def _normalize_turkish_text(self, text):
        """Türkçe karakterleri normalize et"""
        replacements = {
            'ı': 'i', 'ğ': 'g', 'ü': 'u', 'ş': 's', 'ö': 'o', 'ç': 'c',
            'İ': 'i', 'Ğ': 'g', 'Ü': 'u', 'Ş': 's', 'Ö': 'o', 'Ç': 'c'
        }
        for tr_char, latin_char in replacements.items():
            text = text.replace(tr_char, latin_char)
        return text.lower()
    
    def _guess_category_from_name(self, fund_name):
        """Fon adından kategori tahmin et"""
        # Türkçe karakterleri normalize et
        name_normalized = self._normalize_turkish_text(fund_name)

        # Kategori anahtar kelimeleri - normalize edilmiş ve genişletilmiş
        category_keywords = {
            # Yabancı hisse senedi fonları mutlaka genel hisse fonlarından önce kontrol edilmeli
            'Yabancı Hisse Senedi Şemsiye Fonu': [
                # Anahtar kelime dizileri: Tüm elemanların isme dahil olması gerekir
                ('yabanci', 'hisse'),
                ('yabanci', 'borsa'),
                'yabanci hisse', 'yabanci hisse senedi', 'foreign equity', 'foreign stock',
                'uluslararasi hisse', 'global equity', 'global hisse'
            ],
            'Fon Sepeti Şemsiye Fonu': [
                'fon sepeti', 'sepet', 'basket', 'cok fonlu'
            ],
            'Kıymetli Madenler Şemsiye Fonu': [
                'altin', 'gumus', 'kiymetli maden', 'precious metal',
                'gold', 'silver', 'maden'
            ],
            'Hisse Senedi Şemsiye Fonu': [
                'hisse', 'equity', 'endeks', 'index', 'teknoloji', 'sektor',
                'bist', 'yogun fon', 'buyume', 'hisse senedi'
            ],
            # Önemli: Eurobond anahtar kelimeleri bu kategoride tanımlı;
            # aşağıdaki Borçlanma Araçları kategorisinde bu kelimeler tekrar edilmemeli
            'Eurobond Şemsiye Fonu': [
                'yabanci borclanma', 'eurobond', 'foreign bond', 'dis borclanma'
            ],
            'Borçlanma Araçları Şemsiye Fonu': [
                'borclanma', 'tahvil', 'bond', 'devlet', 'ozel sektor'
            ],
            'Karma Şemsiye Fonu': [
                'karma', 'mixed', 'dengeli', 'esnek'
            ],
            'Para Piyasası Şemsiye Fonu': [
                'para piyasasi', 'money market', 'kisa vadeli', 'likit',
                'para piyasasi'
            ],
            'Serbest Şemsiye Fonu': [
                'serbest', 'flexible', 'cok amacli', 'multi', 'birinci'
            ],
            'Değişken Şemsiye Fonu': [
                'degisken', 'variable'
            ],
            'Katılım Şemsiye Fonu': [
                'katilim', 'participation', 'kira sertifikasi',
                'sukuk', 'islami', 'faizsiz'
            ],
            'Gayrimenkul Şemsiye Fonu': [
                'gayrimenkul', 'real estate', 'reit', 'emlak'
            ],
            'Emtia Şemsiye Fonu': [
                'emtia', 'commodity', 'petrol', 'dogalgaz', 'tarim'
            ]
        }
        
        logger.debug(f"Kategori tahmin ediliyor: {fund_name} -> {name_normalized}")
        
        for category, keywords in category_keywords.items():
            for kw in keywords:
                # Eğer tuple ise tüm token'ların geçmesi gerekiyor
                if isinstance(kw, tuple):
                    if all(token in name_normalized for token in kw):
                        logger.debug(f"Eslesen birleşik anahtar: {kw} -> {category}")
                        return category
                else:
                    if kw in name_normalized:
                        logger.debug(f"Eslesen anahtar kelime: '{kw}' -> {category}")
                        return category
        
        logger.debug("Hicbir kategori eslesmedi")
        return ''
    
    def fetch_fund_history(self, fund_code, fund_name):
        """Bir fonun tüm geçmişini al"""
        logger.info(f"[FETCH] {fund_code} ({fund_name}) verisi alınıyor...")
        
        end_date = datetime.now().date()
        # Tarih aralığını ay veya yıl bazında belirle
        if self.months_back > 0:
            start_date = end_date - relativedelta(months=self.months_back)
        else:
            years_back = self.years_back if self.years_back > 0 else 2  # Varsayılan 2 yıl
            start_date = end_date.replace(year=end_date.year - years_back)
        
        # İlk olarak belirtilen tarih aralığını dene
        all_records = self._fetch_date_range(fund_code, start_date, end_date)
        
        # Eğer hiç veri alınamadıysa ve "historical data" hatası varsa, mevcut tüm veriyi al
        if not all_records:
            logger.info(f"{fund_code}: Belirtilen tarih aralığında veri yok, tüm mevcut veri alınıyor...")
            all_records = self._fetch_all_available_data(fund_code)
        
        logger.info(f"[OK] {fund_code}: {len(all_records)} toplam kayıt alındı")
        return all_records
    
    def _fetch_date_range(self, fund_code, start_date, end_date, allow_gaps=False):
        """Belirli tarih aralığında veri al"""
        current_date = start_date
        all_records = []
        consecutive_failures = 0
        max_consecutive_failures = 3 if not allow_gaps else 10  # Boşluklar varsa daha toleranslı ol
        
        while current_date <= end_date:
            chunk_end = min(current_date + timedelta(days=self.chunk_size_days), end_date)
            
            chunk_data = self.fetch_fund_chunk(fund_code, current_date, chunk_end)
            
            if chunk_data:
                all_records.extend(chunk_data)
                consecutive_failures = 0
            else:
                consecutive_failures += 1
                if not allow_gaps:  # Normal arama modunda ardışık başarısızlıkları say
                    logger.warning(f"{fund_code}: Ardışık {consecutive_failures} chunk başarısız")
                
                if consecutive_failures >= max_consecutive_failures:
                    if not allow_gaps:
                        logger.error(f"{fund_code}: {max_consecutive_failures} ardışık başarısızlık, durduruluyor")
                    break
            
            current_date = chunk_end + timedelta(days=1)
            time.sleep(self.request_delay)
        
        return all_records
    
    def _fetch_all_available_data(self, fund_code):
        """Fonun tüm mevcut verisini al (geriye doğru arayarak)"""
        logger.info(f"{fund_code}: Fonun başlangıç tarihi aranıyor...")
        
        end_date = datetime.now().date()
        all_records = []
        
        # Geriye doğru farklı zaman aralıklarında ara
        search_periods = [30, 90, 180, 365, 730, 1095]  # 1ay, 3ay, 6ay, 1yıl, 2yıl, 3yıl
        
        for days_back in search_periods:
            start_date = end_date - timedelta(days=days_back)
            logger.debug(f"{fund_code}: {start_date} tarihinden itibaren aranıyor...")
            
            try:
                result = self.provider.get_fund_performance(
                    fund_code, 
                    start_date.strftime("%Y-%m-%d"), 
                    end_date.strftime("%Y-%m-%d")
                )
                
                if result.get("error_message"):
                    if "No historical data found" in result["error_message"]:
                        continue  # Bu tarih aralığında veri yok, daha geriye git
                    else:
                        logger.warning(f"{fund_code}: API hatası: {result['error_message']}")
                        continue
                
                price_history = result.get("fiyat_geçmisi", [])
                if price_history:
                    logger.info(f"{fund_code}: {len(price_history)} kayıt bulundu ({start_date} - {end_date})")
                    # En eski tarihi bul ve o tarihten itibaren tüm veriyi al
                    oldest_date = min(pd.to_datetime(record['tarih']).date() for record in price_history)
                    logger.info(f"{fund_code}: En eski veri tarihi: {oldest_date}")
                    
                    # En eski tarihten bugüne kadar tüm veriyi al (boşluklara toleranslı)
                    return self._fetch_date_range(fund_code, oldest_date, end_date, allow_gaps=True)
                    
            except Exception as e:
                logger.debug(f"{fund_code}: {days_back} gün geriye arama hatası: {e}")
                continue
        
        # Hiçbir zaman aralığında veri bulunamadı
        logger.warning(f"{fund_code}: Hiçbir tarih aralığında veri bulunamadı")
        return []
    
    def process_all_funds(self):
        """Tüm fonları işle ve birleştirilmiş veri oluştur"""
        try:
            # Fon listesini al
            funds = self.get_fund_list()
            
            logger.info(f"[START] {len(funds)} fon için veri indirme başlıyor...")
            logger.info(f"Hedef dosya: {self.output_file}")
            
            all_data = []
            successful_funds = 0
            failed_funds = []
            
            for i, fund in enumerate(funds, 1):
                # her fon için tamamen yeni bir oturum aç
                self.provider = self._setup_provider()
                time.sleep(1)            # oturuma nefes aldır

                fund_code = fund['fon_kodu']
                fund_name = fund['fon_adi']
                
                logger.info(f"[{i}/{len(funds)}] İşleniyor: {fund_code}")
                
                try:
                    fund_history = self.fetch_fund_history(fund_code, fund_name)
                    
                    if fund_history:
                        # Kategori bilgisini API'den al
                        logger.info(f"[INFO] {fund_code} kategori bilgisi alınıyor...")
                        fund_category = self.get_fund_category(fund_code, fund_name)
                        if fund_category:
                            logger.info(f"[CATEGORY] {fund_code}: {fund_category}")
                        
                        # Her kayda fon_kodu ve fon_kategorisi ekle
                        for record in fund_history:
                            record['fon_kodu'] = fund_code
                            record['fon_kategorisi'] = fund_category
                        
                        all_data.extend(fund_history)
                        successful_funds += 1
                        logger.info(f"[OK] {fund_code} başarılı")
                    else:
                        failed_funds.append(fund_code)
                        logger.warning(f"[FAIL] {fund_code} veri alınamadı")
                        
                except Exception as e:
                    failed_funds.append(fund_code)
                    logger.error(f"[ERROR] {fund_code} işlem hatası: {e}")
                
                # Her 5 fondan sonra durum raporu
                if i % 5 == 0:
                    logger.info(f"Durum: {successful_funds}/{i} başarılı, {len(all_data)} toplam kayıt")
            
            # Sonuçları işle ve kaydet
            if all_data:
                self.save_data(all_data, successful_funds, failed_funds)
                
            else:
                logger.error("[ERROR] Hiç veri alınamadı!")
                
        except Exception as e:
            logger.error(f"Genel hata: {e}")
            raise
    
    def save_data(self, all_data, successful_funds, failed_funds):
        """Veriyi parquet dosyasına kaydet"""
        logger.info(f"[SAVE] {len(all_data)} kayıt parquet dosyasına yazılıyor...")
        
        try:
            # DataFrame oluştur
            df = pd.DataFrame(all_data)
            
            # borsa_bulten_fiyat sütununu kaldır (eğer varsa)
            if 'borsa_bulten_fiyat' in df.columns:
                df = df.drop(columns=['borsa_bulten_fiyat'])
                logger.info("borsa_bulten_fiyat sütunu kaldırıldı")
            
            # Tarih sütununu datetime'a çevir
            df['tarih'] = pd.to_datetime(df['tarih'])
            
            # Sırala ve duplikatları temizle (fon_kodu ile beraber)
            df = df.sort_values(['fon_kodu', 'tarih']).drop_duplicates(['fon_kodu', 'tarih']).reset_index(drop=True)
            
            # Parquet dosyasına yaz
            pq.write_table(
                pa.Table.from_pandas(df),
                self.output_file,
                compression="zstd"
            )
            
            # Özet bilgi
            unique_funds = df['fon_kodu'].nunique()
            date_range = f"{df['tarih'].min().strftime('%Y-%m-%d')} - {df['tarih'].max().strftime('%Y-%m-%d')}"
            
            # Kategori başına benzersiz fon sayısı
            category_counts = (
                df.groupby('fon_kategorisi')['fon_kodu']
                .nunique()
                .sort_values(ascending=False)  # type: ignore[arg-type]
            )
            
            logger.info("[SUCCESS] İNDİRME TAMAMLANDI!")
            logger.info(f"[FILE] Dosya: {self.output_file}")
            logger.info(f"[STATS] Kayıt sayısı: {len(df):,}")
            logger.info(f"[FUNDS] Fon sayısı: {unique_funds}")
            logger.info(f"[DATE] Tarih aralığı: {date_range}")
            logger.info(f"[OK] Başarılı fonlar: {successful_funds}")
            logger.info(f"[FAIL] Başarısız fonlar: {len(failed_funds)}")
            
            # Kategori dağılımını göster
            if not category_counts.empty:
                logger.info("[CATEGORIES] Fon kategorileri:")
                for category, count in category_counts.head(10).items():
                    if category:  # Boş kategorileri gösterme
                        logger.info(f"  {category}: {count} fon")
            
            if failed_funds:
                logger.warning(f"Başarısız fonlar: {', '.join(failed_funds[:10])}{'...' if len(failed_funds) > 10 else ''}")
            
        except Exception as e:
            logger.error(f"Kaydetme hatası: {e}")
            raise

    def repair_existing_data(self, input_file: Path, codes_list: list[str] | None = None, start_date: datetime | None = None, end_date: datetime | None = None, output_file: Path | None = None):
        """Var olan parquet dosyasındaki eksik/güncel verileri tamamlar.

        Args:
            input_file (Path): Mevcut parquet veri dosyası.
            codes_list (list[str]|None): Sadece belirtilen fon kodları için onarım yapılacaksa.
            start_date (datetime|None): Başlangıç tarihi (opsiyonel).
            end_date (datetime|None): Bitiş tarihi (opsiyonel, varsayılan bugün).
            output_file (Path|None): Çıktı dosyası (varsayılan input_file üzerine yazar).
        """
        logger.info("[REPAIR] Başlatıldı: %s", input_file)

        if not input_file.exists():
            raise FileNotFoundError(f"Giriş dosyası bulunamadı: {input_file}")

        df_existing = pq.read_table(input_file).to_pandas()
        logger.info("[REPAIR] Var olan kayıt: %d", len(df_existing))

        # Fon listesi – Takasbank'tan çek
        all_funds = {f['fon_kodu']: f for f in self.provider._get_takasbank_fund_list()}

        # Hedef fon kodları
        if codes_list:
            target_codes = [c.strip().upper() for c in codes_list if c.strip()]
        else:
            target_codes = sorted(df_existing['fon_kodu'].unique())

        # Tarih aralığı
        # Kullanıcı yalnızca başlangıç verdi ise bitiş 'bugün' olsun (datetime)
        if start_date and not end_date:
            end_date = datetime.today()
        if end_date and not start_date:
            # Sadece bitiş tarihi verilmişse her fon için kendi son tarihinden başlanır
            start_date = None  # Fon bazlı belirlenecek

        all_new_records: list[dict] = []
        successful = 0
        failed: list[str] = []

        for code in target_codes:
            fund_name = all_funds.get(code, {}).get('fon_adi', code)
            logger.info("[REPAIR] %s işleniyor", code)
            try:
                # Fon dataset'te var mı?
                if code in df_existing['fon_kodu'].values:
                    fund_df = df_existing[df_existing['fon_kodu'] == code]
                    last_dt = fund_df['tarih'].max().date()
                    # Kullanıcı başlangıç verdi mi? Eğer vermediyse last_dt+1 kullan
                    sd = start_date.date() if start_date else (last_dt + timedelta(days=1))
                else:
                    # Fon hiç yok, tamamen indir
                    sd = start_date.date() if start_date else None

                ed = end_date.date() if end_date else datetime.today().date()

                if sd is None:
                    # Tüm geçmişi çek
                    history = self.fetch_fund_history(code, fund_name)
                else:
                    history = self._fetch_date_range(code, sd, ed, allow_gaps=True)

                if history:
                    category = self.get_fund_category(code, fund_name)
                    for rec in history:
                        rec['fon_kodu'] = code
                        rec['fon_kategorisi'] = category
                    all_new_records.extend(history)
                    successful += 1
                else:
                    logger.warning("[REPAIR] %s için yeni veri bulunamadı", code)
            except Exception as e:
                failed.append(code)
                logger.error("[REPAIR-ERROR] %s: %s", code, e)

        if not all_new_records:
            logger.warning("[REPAIR] Hiç yeni kayıt eklenmedi")
            return

        df_new = pd.DataFrame(all_new_records)
        df_new['tarih'] = pd.to_datetime(df_new['tarih'])

        # Birleştir
        df_combined = pd.concat([df_existing, df_new], ignore_index=True)
        df_combined = (
            df_combined
            .sort_values(['fon_kodu', 'tarih'])
            .drop_duplicates(['fon_kodu', 'tarih'])
            .reset_index(drop=True)
        )

        out_file = output_file if output_file else input_file
        out_file.parent.mkdir(exist_ok=True, parents=True)
        pq.write_table(pa.Table.from_pandas(df_combined), out_file, compression="zstd")

        logger.info("[REPAIR] Tamamlandı ➜ %s | Toplam kayıt: %d | Yeni eklenen: %d | Başarılı fon: %d | Hatalı fon: %d", out_file, len(df_combined), len(df_new), successful, len(failed))

def main():
    """Ana fonksiyon"""
    parser = argparse.ArgumentParser(description="TEFAS fon verilerini indir")
    parser.add_argument("--test", action="store_true", help="Test modu (özel fon listesi gerekli)")
    parser.add_argument("--full", action="store_true", help="Tüm fonları indir")
    parser.add_argument("--years", type=int, default=0, help="Kaç yıl geriye gidilecek")
    parser.add_argument("--months", type=int, default=0, help="Kaç ay geriye gidilecek (örn: 1, 6)")
    parser.add_argument("--codes", type=str, default="", help="Virgülle ayrılmış fon kodları (sadece test modu)")
    parser.add_argument("--outfile", type=str, default="", help="Özel çıktı dosyası adı/yolu (opsiyonel)")
    parser.add_argument("--infile", type=str, default="", help="Var olan parquet dosyası (repair modu)")
    parser.add_argument("--repair", action="store_true", help="Repair/onarma modu")
    parser.add_argument("--dates", nargs=2, metavar=("START", "END"), help="Başlangıç ve bitiş tarihleri YYYYMMDD (repair modu)")
    
    args = parser.parse_args()
    
    if not (args.test or args.full or args.repair):
        parser.error("--test, --full veya --repair seçeneklerinden birini belirtmelisiniz")
    
    # Ay / yıl parametre kontrolü
    if args.months > 0 and args.years > 0:
        parser.error("--years ve --months aynı anda kullanılamaz")

    months_back = args.months if args.months > 0 else 0
    years_back = args.years if (args.years > 0 and months_back == 0) else 0

    test_mode = args.test
    
    logger.info("=" * 60)
    logger.info("TEFAS Fon Verisi İndirme Script'i")
    logger.info("=" * 60)
    logger.info(f"Mod: {'Test (özel fon listesi)' if test_mode else 'Tam (tüm fonlar)'}")
    if months_back > 0:
        logger.info(f"Tarih aralığı: Son {months_back} ay")
    else:
        years_back_log = years_back if years_back > 0 else 2
        logger.info(f"Tarih aralığı: Son {years_back_log} yıl")
    logger.info("=" * 60)
    
    # Test modu için fon kodlarını liste olarak hazırla
    codes_list = []
    if test_mode:
        if not args.codes:
            parser.error("--test modunda --codes parametresi ile en az bir fon kodu belirtmelisiniz")
        codes_list = [c.strip().upper() for c in args.codes.split(',') if c.strip()]

    if args.repair:
        if not args.infile:
            parser.error("--repair için --infile zorunlu")

        # Kod listesi hazırla (opsiyonel)
        repair_codes = [c.strip().upper() for c in args.codes.split(',') if c.strip()] if args.codes else []

        # Tarih aralığı parse
        sd = ed = None
        if args.dates:
            try:
                sd = datetime.strptime(args.dates[0], "%Y%m%d")
                ed = datetime.strptime(args.dates[1], "%Y%m%d")
            except Exception:
                parser.error("--dates YYYYMMDD YYYYMMDD formatında olmalı")

        downloader = TefasDataDownloader(test_mode=False)
        downloader.repair_existing_data(Path(args.infile), codes_list=repair_codes if repair_codes else None, start_date=sd, end_date=ed, output_file=Path(args.outfile) if args.outfile else None)
        return

    try:
        downloader = TefasDataDownloader(test_mode=test_mode, years_back=years_back, months_back=months_back, codes_list=codes_list, output_filename=args.outfile if args.outfile else None)
        downloader.process_all_funds()
        
    except KeyboardInterrupt:
        logger.info("[STOP] Kullanıcı tarafından durduruldu")
    except Exception as e:
        logger.error(f"[ERROR] Beklenmedik hata: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main() 