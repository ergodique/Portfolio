#!/usr/bin/env python3
"""
TEFAS Fon Verisi İndirme Script'i (Merged - Seri & Paralel)
===========================================================

Bu script TEFAS'ta bulunan tüm fonların geçmiş fiyat verilerini indirir
ve tek bir parquet dosyasında birleştirir. Hem seri hem paralel mod destekler.

Seri mod: Fonları tek tek sırayla indirir
Paralel mod: Fonları batch'ler halinde paralel indirir (daha hızlı)

Kullanım:
    python tefas_download_data_merged.py --test --codes ABC,XYZ --workers 1  # Seri
    python tefas_download_data_merged.py --test --codes ABC,XYZ --workers 4  # Paralel  
    python tefas_download_data_merged.py --full --months 1 --workers 6       # Paralel full
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
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import List, Dict, Any, Optional

# ---------------------------------------------------------------------------
# LOGGING SETUP – tek dosya, çoklama problemi yok
# ---------------------------------------------------------------------------
log_dir = Path("log")
log_dir.mkdir(exist_ok=True)
_log_file = log_dir / f"tefas_download_merged_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"

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

# Gerekli modülleri import et
import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq

from providers.tefas_provider import TefasProvider
from tls12_adapter import TLS12Adapter


class TefasDataDownloaderMerged:
    """TEFAS fon verilerini hem seri hem paralel olarak indiren birleşik sınıf"""
    
    def __init__(self, test_mode=True, years_back=0, months_back=0, codes_list=None, 
                 output_filename=None, workers=1, parallel_mode=None):
        """
        Args:
            test_mode (bool): True ise sadece belirtilen fon listesi, False ise tüm fonlar
            years_back (int): Kaç yıl geriye gidilecek (opsiyonel)
            months_back (int): Kaç ay geriye gidilecek (opsiyonel)
            codes_list (list[str]|None): Test modunda indirilecek fon kodları listesi
            output_filename (str|None): Parquet çıktısının dosya adı/yolu (varsayılan otomatik)
            workers (int): Paralel işleme için worker sayısı (1 = seri mod)
            parallel_mode (bool|None): Paralel mod zorlaması (None = workers'a göre otomatik)
        """
        self.test_mode = test_mode
        self.years_back = years_back or 0
        self.months_back = months_back or 0
        self.workers = max(1, workers)  # En az 1 worker
        
        # Paralel mod belirleme
        if parallel_mode is not None:
            self.parallel_mode = parallel_mode
        else:
            self.parallel_mode = self.workers > 1
            
        # Test modu için kullanıcı tarafından verilen fon kodları
        if codes_list:
            self.codes_list = [c.strip().upper() for c in codes_list if c.strip()]
        else:
            self.codes_list = []
            
        self.provider = self._setup_provider()
        self.chunk_size_days = 60  # Her istekte 60 günlük veri
        self.request_delay = 3  # İstekler arası bekleme süresi (saniye)
        
        # Dosya yolları
        self.output_dir = Path("data")
        self.output_dir.mkdir(exist_ok=True)

        # Çıktı dosyası
        if output_filename and str(output_filename).strip():
            filename_only = Path(str(output_filename).strip()).name
            self.output_file = self.output_dir / filename_only
        else:
            mode_suffix = "parallel" if self.parallel_mode else "serial"
            self.output_file = self.output_dir / f"tefas_{'test' if test_mode else 'all'}_{mode_suffix}.parquet"
            
        self.progress_file = self.output_dir / "download_progress.json"
        
    def _setup_provider(self):
        """TefasProvider'ı yapılandır"""
        logger.debug("TefasProvider yapılandırılıyor...")
        
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
                    logger.debug("Session başarıyla başlatıldı")
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
        """Fon listesini al (test modu veya tam liste)"""
        logger.info("Fon listesi alınıyor...")
        
        try:
            all_funds = self.provider._get_takasbank_fund_list()
            if not all_funds:
                logger.error("Fon listesi alınamadı!")
                return []
            
            logger.info(f"Toplam {len(all_funds)} fon bulundu")
            
            # Test modu için filtreleme
            if self.test_mode and self.codes_list:
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
                    logger.error("Belirtilen fon kodlarından hiçbiri Takasbank listesinde bulunamadı")
                    return []
                
                logger.info(f"Test modu: {len(selected_funds)} fon seçildi: {', '.join(self.codes_list)}")
                return selected_funds
            elif self.test_mode:
                # Kod listesi verilmemişse ilk 5 fonu al
                return all_funds[:5]
            else:
                return all_funds
                
        except Exception as e:
            logger.error(f"Fon listesi alma hatası: {e}")
            return []

    def fetch_fund_chunk(self, fund_code, start_date, end_date, retries=2):
        """Belirli bir tarih aralığında fon verisi al"""
        for attempt in range(retries + 1):
            try:
                time.sleep(self.request_delay)
                
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
                    logger.debug(f"[CHUNK OK] {fund_code}: {len(price_history)} kayıt ({start_date} - {end_date})")
                    return price_history
                else:
                    logger.warning(f"[CHUNK EMPTY] {fund_code}: Veri yok ({start_date} - {end_date})")
                    return []
                    
            except Exception as e:
                error_msg = str(e)
                
                # Connection Reset hatası için session'ı tamamen yenile
                if "ConnectionResetError" in error_msg or "Connection aborted" in error_msg:
                    logger.warning(f"{fund_code}: Bağlantı kesildi, session tamamen yenileniyor...")
                    self.provider = self._setup_provider()
                
                if attempt < retries:
                    wait_time = 3 + attempt
                    logger.warning(f"[RETRY {attempt+1}/{retries}] {fund_code}: {e}")
                    time.sleep(wait_time)
                else:
                    logger.error(f"[CHUNK FAIL] {fund_code}: {e}")
                    return []
        
        return []

    def get_fund_category(self, fund_code, fund_name):
        """Fon kategorisini API'den al, başarısız olursa adından tahmin et"""
        try:
            # API'den kategori bilgisini al
            details = self.provider.get_fund_detail_alternative(fund_code)
            if details and 'fon_kategori' in details:
                category = details['fon_kategori']
                if category and category.strip():
                    return category.strip()
        except Exception as e:
            logger.error(f"Error getting fund detail (alternative) for {fund_code}: {e}")
        
        # API başarısız olursa isimden tahmin et
        guessed_category = self._guess_category_from_name(fund_name)
        logger.info(f"{fund_code}: Fon adından tahmin edilen kategori: {guessed_category}")
        return guessed_category

    def _normalize_turkish_text(self, text):
        """Türkçe karakter normalizasyonu"""
        if not text:
            return ""
        replacements = {
            'Ğ': 'G', 'ğ': 'g', 'Ü': 'U', 'ü': 'u', 'Ş': 'S', 'ş': 's',
            'İ': 'I', 'ı': 'i', 'Ö': 'O', 'ö': 'o', 'Ç': 'C', 'ç': 'c'
        }
        for tr, en in replacements.items():
            text = text.replace(tr, en)
        return text.upper()

    def _guess_category_from_name(self, fund_name):
        """Fon adından kategori tahmini - priorite sıralı kurallar"""
        if not fund_name:
            return "Bilinmeyen Şemsiye Fonu"
        
        name_normalized = self._normalize_turkish_text(fund_name)
        
        # ÖNCELIK SIRALI KURALLAR (Kullanıcı gereksinimleri)
        # 1. SERBEST geçiyorsa kesinlikle serbest (SERBEST + DEĞİŞKEN veya SERBEST + KATILIM olsa bile)
        if any(keyword in name_normalized for keyword in ["SERBEST", "FLEXIBLE"]):
            return "Serbest Şemsiye Fonu"
        
        # 2. DEĞİŞKEN geçiyorsa kesinlikle değişken (DEĞİŞKEN + KATILIM olsa bile)
        elif any(keyword in name_normalized for keyword in ["DEGISKEN", "VARIABLE"]):
            return "Değişken Şemsiye Fonu"
        
        # 3. KATILIM geçiyorsa kesinlikle katılım (KATILIM + HİSSE olsa bile)
        elif any(keyword in name_normalized for keyword in ["KATILIM", "PARTICIPATION", "SUKUK"]):
            return "Katılım Şemsiye Fonu"
        
        # DİĞER KATEGORI TANIMLARı (mevcut mantık)
        # 4. YABANCI + HİSSE kombinasyonu (hem YABANCI hem HİSSE geçmeli)
        elif all(keyword in name_normalized for keyword in ["YABANCI", "HISSE"]):
            return "Yabancı Hisse Senedi Şemsiye Fonu"
        elif any(keyword in name_normalized for keyword in ["HISSE", "EQUITY", "STOCK"]):
            return "Hisse Senedi Şemsiye Fonu"
        elif any(keyword in name_normalized for keyword in ["PARA PIYASASI", "MONEY MARKET"]):
            return "Para Piyasası Şemsiye Fonu"
        elif any(keyword in name_normalized for keyword in ["FON SEPETI", "FUND BASKET"]):
            return "Fon Sepeti Şemsiye Fonu"
        elif any(keyword in name_normalized for keyword in ["ALTIN", "GOLD", "GUMUSH", "SILVER", "KIYMETLI"]):
            return "Kıymetli Madenler Şemsiye Fonu"
        elif any(keyword in name_normalized for keyword in ["EURO", "EUROBOND"]):
            return "Eurobond Şemsiye Fonu"
        elif any(keyword in name_normalized for keyword in ["BORCLANMA", "BOND", "TAHVIL"]):
            return "Borçlanma Araçları Şemsiye Fonu"

        else:
            return "Diğer Şemsiye Fonu"

    def fetch_fund_history(self, fund_code, fund_name):
        """Bir fonun tüm geçmiş verilerini al"""
        logger.debug(f"[FETCH] {fund_code} ({fund_name}) verisi alınıyor...")
        
        # Tarih aralığı hesapla
        end_date = datetime.now()
        
        if self.months_back > 0:
            start_date = end_date - relativedelta(months=self.months_back)
        elif self.years_back > 0:
            start_date = end_date - relativedelta(years=self.years_back)
        else:
            start_date = end_date - relativedelta(years=2)  # Varsayılan 2 yıl
        
        # Önce belirlenen tarih aralığını dene
        all_data = self._fetch_date_range(fund_code, start_date, end_date, allow_gaps=True)
        
        # Eğer veri yoksa (yeni fon olabilir), geriye doğru arama yap
        if not all_data:
            logger.info(f"{fund_code}: Belirlenen tarih aralığında veri yok, geriye doğru aranıyor...")
            all_data = self._fetch_all_available_data(fund_code)
        
        if all_data:
            logger.info(f"[OK] {fund_code}: {len(all_data)} toplam kayıt alındı")
        else:
            logger.warning(f"[FAIL] {fund_code}: Hiç veri alınamadı")
            
        return all_data

    def _fetch_date_range(self, fund_code, start_date, end_date, allow_gaps=False):
        """Belirli tarih aralığındaki veriyi chunk'lar halinde al"""
        all_data = []
        current_start = start_date
        
        while current_start < end_date:
            chunk_end = min(current_start + timedelta(days=self.chunk_size_days), end_date)
            
            chunk_data = self.fetch_fund_chunk(fund_code, current_start, chunk_end)
            
            if chunk_data:
                all_data.extend(chunk_data)
            elif not allow_gaps:
                # Boşluk toleransı yoksa dur
                logger.warning(f"{fund_code}: Veri boşluğu tespit edildi, durduruldu")
                break
            
            current_start = chunk_end + timedelta(days=1)
        
        return all_data

    def _fetch_all_available_data(self, fund_code):
        """Fonun mevcut olan tüm verisini al (yeni fonlar için)"""
        # Geriye doğru küçük aralıklarla dene
        search_periods = [30, 90, 180, 365, 730]  # 1 ay, 3 ay, 6 ay, 1 yıl, 2 yıl
        
        for days in search_periods:
            end_date = datetime.now()
            start_date = end_date - timedelta(days=days)
            
            data = self._fetch_date_range(fund_code, start_date, end_date, allow_gaps=True)
            
            if data:
                logger.info(f"{fund_code}: {days} günlük aralıkta {len(data)} kayıt bulundu")
                
                # En eski tarihi bul ve oradan başlayarak tüm veriyi al
                earliest_date = min(pd.to_datetime(record['tarih']) for record in data)
                
                # En eski tarihten bugüne kadar tüm veriyi al
                full_data = self._fetch_date_range(
                    fund_code, 
                    earliest_date - timedelta(days=30),  # Biraz daha erken başla
                    datetime.now(),
                    allow_gaps=True
                )
                
                return full_data
        
        return []

    def _fetch_single_fund_data(self, fund: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Tek bir fonu indir ve kayıt listesini döndür (paralel mod için)"""
        code = fund["fon_kodu"]
        name = fund["fon_adi"]

        # Her thread için yeni provider oluştur
        temp_downloader = TefasDataDownloaderMerged(
            test_mode=True,
            years_back=self.years_back,
            months_back=self.months_back,
            codes_list=[code],
            workers=1,  # Thread içinde seri mod
            parallel_mode=False
        )

        try:
            history = temp_downloader.fetch_fund_history(code, name)
            if history:
                category = temp_downloader.get_fund_category(code, name)
                for rec in history:
                    rec["fon_kodu"] = code
                    rec["fon_kategorisi"] = category
                logger.info(f"[OK] {code} ({len(history)} kayıt)")
            else:
                logger.warning(f"[FAIL] {code} veri alınamadı")
            return history or []
        except Exception as exc:
            logger.error(f"[ERROR] {code}: {exc}")
            return []

    def _chunked(self, seq: List[Dict[str, Any]], n: int):
        """Liste chunk'lara böl"""
        for i in range(0, len(seq), n):
            yield seq[i : i + n]

    def process_all_funds_parallel(self):
        """Fonları paralel olarak işle"""
        logger.info("[PARALEL MOD] Başlıyor...")
        
        try:
            funds = self.get_fund_list()
            if not funds:
                logger.error("Fon listesi alınamadı!")
                return
                
            logger.info(f"[START] {len(funds)} fon paralel indirme başlıyor...")
            logger.info(f"Hedef dosya: {self.output_file}")
            logger.info(f"Worker sayısı: {self.workers}")
            
            all_records: List[Dict[str, Any]] = []
            successful_funds: List[str] = []
            failed_funds: List[str] = []
            
            total_batches = (len(funds) + self.workers - 1) // self.workers

            for batch_idx, batch in enumerate(self._chunked(funds, self.workers), 1):
                logger.info(f"[BATCH {batch_idx}] {len(batch)} fon işleniyor")

                with ThreadPoolExecutor(max_workers=len(batch)) as executor:
                    future_to_code = {
                        executor.submit(self._fetch_single_fund_data, fund): fund["fon_kodu"]
                        for fund in batch
                    }

                    for future in as_completed(future_to_code):
                        code = future_to_code[future]
                        try:
                            data = future.result()
                            if data:
                                all_records.extend(data)
                                successful_funds.append(code)
                            else:
                                failed_funds.append(code)
                        except Exception as exc:
                            logger.error(f"[EXCEPTION] {code}: {exc}")
                            failed_funds.append(code)

                percent = batch_idx / total_batches * 100
                logger.info(f"[BATCH {batch_idx}/{total_batches} (%{percent:.1f})] Tamamlandı. Şu ana kadar başarı: {len(successful_funds)}, hata: {len(failed_funds)}")
                time.sleep(2)

            # Sonuçları işle ve kaydet
            if all_records:
                self.save_data(all_records, len(successful_funds), failed_funds)
            else:
                logger.error("[ERROR] Hiç veri alınamadı!")

        except Exception as e:
            logger.error(f"Paralel işlem hatası: {e}")
            raise

    def process_all_funds_serial(self):
        """Fonları seri olarak işle"""
        logger.info("[SERİ MOD] Başlıyor...")
        
        try:
            funds = self.get_fund_list()
            if not funds:
                logger.error("Fon listesi alınamadı!")
                return
                
            logger.info(f"[START] {len(funds)} fon seri indirme başlıyor...")
            logger.info(f"Hedef dosya: {self.output_file}")
            
            all_data = []
            successful_funds = 0
            failed_funds = []
            
            for i, fund in enumerate(funds, 1):
                # Her fon için yeni oturum aç
                self.provider = self._setup_provider()
                time.sleep(1)  # Oturuma nefes aldır

                fund_code = fund['fon_kodu']
                fund_name = fund['fon_adi']
                
                logger.info(f"[{i}/{len(funds)}] İşleniyor: {fund_code}")
                
                try:
                    fund_history = self.fetch_fund_history(fund_code, fund_name)
                    
                    if fund_history:
                        # Kategori bilgisini al
                        fund_category = self.get_fund_category(fund_code, fund_name)
                        if fund_category:
                            logger.debug(f"[CATEGORY] {fund_code}: {fund_category}")
                        
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
            logger.error(f"Seri işlem hatası: {e}")
            raise

    def process_all_funds(self):
        """Ana işlem metodu - mod seçimine göre paralel veya seri"""
        if self.parallel_mode:
            self.process_all_funds_parallel()
        else:
            self.process_all_funds_serial()

    def save_data(self, all_data, successful_funds, failed_funds):
        """Veriyi parquet dosyasına kaydet"""
        logger.info(f"[SAVE] {len(all_data)} kayıt parquet dosyasına yazılıyor...")
        
        try:
            # DataFrame oluştur
            df = pd.DataFrame(all_data)
            
            # borsa_bulten_fiyat sütununu kaldır (eğer varsa)
            if 'borsa_bulten_fiyat' in df.columns:
                df = df.drop(columns=['borsa_bulten_fiyat'])
            
            # Tarih sütununu datetime'a çevir
            df['tarih'] = pd.to_datetime(df['tarih'])
            
            # Sırala ve duplikatları temizle
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
            
            # Kategori başına fon sayısı
            category_counts = df.groupby('fon_kategorisi')['fon_kodu'].nunique().sort_values(ascending=False)  # type: ignore
            
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
                    if category:
                        logger.info(f"  {category}: {count} fon")
            
            if failed_funds:
                logger.warning(f"Başarısız fonlar: {', '.join(failed_funds[:10])}{'...' if len(failed_funds) > 10 else ''}")
            
        except Exception as e:
            logger.error(f"Kaydetme hatası: {e}")
            raise


def main():
    """Ana fonksiyon"""
    parser = argparse.ArgumentParser(description="TEFAS fon verilerini indir (Seri & Paralel)")
    parser.add_argument("--test", action="store_true", help="Test modu (özel fon listesi gerekli)")
    parser.add_argument("--full", action="store_true", help="Tüm fonları indir")
    parser.add_argument("--years", type=int, default=0, help="Kaç yıl geriye gidilecek")
    parser.add_argument("--months", type=int, default=0, help="Kaç ay geriye gidilecek (örn: 1, 6)")
    parser.add_argument("--codes", type=str, default="", help="Virgülle ayrılmış fon kodları (sadece test modu)")
    parser.add_argument("--outfile", type=str, default="", help="Özel çıktı dosyası adı/yolu (opsiyonel)")
    parser.add_argument("--workers", type=int, default=1, help="Eşzamanlı worker sayısı (1=seri, >1=paralel)")
    
    args = parser.parse_args()
    
    if not (args.test or args.full):
        parser.error("--test veya --full seçeneklerinden birini belirtmelisiniz")
    
    # Ay / yıl parametre kontrolü
    if args.months > 0 and args.years > 0:
        parser.error("--years ve --months aynı anda kullanılamaz")

    months_back = args.months if args.months > 0 else 0
    years_back = args.years if (args.years > 0 and months_back == 0) else 0
    test_mode = args.test
    
    # Test modu için fon kodları
    codes_list = []
    if test_mode:
        if not args.codes:
            parser.error("--test modunda --codes parametresi ile en az bir fon kodu belirtmelisiniz")
        codes_list = [c.strip().upper() for c in args.codes.split(',') if c.strip()]

    # Çalışma modu belirleme
    parallel_mode = args.workers > 1
    mode_text = f"Paralel ({args.workers} worker)" if parallel_mode else "Seri"
    
    logger.info("=" * 60)
    logger.info("TEFAS Fon Verisi İndirme Script'i (Merged)")
    logger.info("=" * 60)
    logger.info(f"Mod: {'Test' if test_mode else 'Tam'} - {mode_text}")
    if months_back > 0:
        logger.info(f"Tarih aralığı: Son {months_back} ay")
    else:
        years_back_log = years_back if years_back > 0 else 2
        logger.info(f"Tarih aralığı: Son {years_back_log} yıl")
    logger.info("=" * 60)
    
    try:
        downloader = TefasDataDownloaderMerged(
            test_mode=test_mode,
            years_back=years_back,
            months_back=months_back,
            codes_list=codes_list,
            output_filename=args.outfile if args.outfile else None,
            workers=args.workers
        )
        downloader.process_all_funds()
        
    except KeyboardInterrupt:
        logger.info("[STOP] Kullanıcı tarafından durduruldu")
    except Exception as e:
        logger.error(f"[ERROR] Beklenmedik hata: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main() 