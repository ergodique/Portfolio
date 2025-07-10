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
from pathlib import Path

# Gerekli modülleri import et
import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq

# borsa-mcp-main klasörünü path'e ekle
current_dir = Path(__file__).parent
project_root = current_dir.parent / "borsa-mcp-main"
sys.path.insert(0, str(project_root))

from providers.tefas_provider import TefasProvider
from tls12_adapter import TLS12Adapter

# Logging ayarları
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('tefas_download.log', encoding='utf-8'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class TefasDataDownloader:
    """TEFAS fon verilerini toplu olarak indiren sınıf"""
    
    def __init__(self, test_mode=True, years_back=2, codes_list=None):
        """
        Args:
            test_mode (bool): True ise sadece ilk 5 fon, False ise tüm fonlar
            years_back (int): Kaç yıl geriye gidilecek (varsayılan: 2 yıl)
            codes_list (list[str]|None): Test modunda indirilecek fon kodları listesi
        """
        self.test_mode = test_mode
        self.years_back = years_back
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
            'Borçlanma Araçları Şemsiye Fonu': [
                'borclanma', 'tahvil', 'bond', 'devlet', 'ozel sektor',
                'eurobond', 'dis borclanma'
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
                'degisken', 'variable', 'robotik', 'teknoloji',
                'yapay zeka', 'inovasyon', 'surdurulebilirlik'
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
            for keyword in keywords:
                if keyword in name_normalized:
                    logger.debug(f"Eslesen anahtar kelime: '{keyword}' -> {category}")
                    return category
        
        logger.debug("Hicbir kategori eslesmedi")
        return ''
    
    def fetch_fund_history(self, fund_code, fund_name):
        """Bir fonun tüm geçmişini al"""
        logger.info(f"[FETCH] {fund_code} ({fund_name}) verisi alınıyor...")
        
        end_date = datetime.now().date()
        start_date = end_date.replace(year=end_date.year - self.years_back)
        
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
            
            # Kategori dağılımı
            category_counts = df['fon_kategorisi'].value_counts()
            
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

def main():
    """Ana fonksiyon"""
    parser = argparse.ArgumentParser(description="TEFAS fon verilerini indir")
    parser.add_argument("--test", action="store_true", help="Test modu (özel fon listesi gerekli)")
    parser.add_argument("--full", action="store_true", help="Tüm fonları indir")
    parser.add_argument("--years", type=int, default=2, help="Kaç yıl geriye gidilecek (varsayılan: 2)")
    parser.add_argument("--codes", type=str, default="", help="Virgülle ayrılmış fon kodları (sadece test modu)")
    
    args = parser.parse_args()
    
    if not (args.test or args.full):
        parser.error("--test veya --full seçeneklerinden birini belirtmelisiniz")
    
    test_mode = args.test
    years_back = args.years
    
    logger.info("=" * 60)
    logger.info("TEFAS Fon Verisi İndirme Script'i")
    logger.info("=" * 60)
    logger.info(f"Mod: {'Test (özel fon listesi)' if test_mode else 'Tam (tüm fonlar)'}")
    logger.info(f"Tarih aralığı: Son {years_back} yıl")
    logger.info("=" * 60)
    
    # Test modu için fon kodlarını liste olarak hazırla
    codes_list = []
    if test_mode:
        if not args.codes:
            parser.error("--test modunda --codes parametresi ile en az bir fon kodu belirtmelisiniz")
        codes_list = [c.strip().upper() for c in args.codes.split(',') if c.strip()]

    try:
        downloader = TefasDataDownloader(test_mode=test_mode, years_back=years_back, codes_list=codes_list)
        downloader.process_all_funds()
        
    except KeyboardInterrupt:
        logger.info("[STOP] Kullanıcı tarafından durduruldu")
    except Exception as e:
        logger.error(f"[ERROR] Beklenmedik hata: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main() 