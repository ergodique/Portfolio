import argparse
import logging
import sys
import time
import urllib3
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import pandas as pd
import yfinance as yf
from dateutil.relativedelta import relativedelta

# SSL warning'lerini kapat
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Logging ayarları
log_file = Path("log") / f"yahoo_download_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"
log_file.parent.mkdir(exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler(log_file, encoding="utf-8"),
        logging.StreamHandler()
    ],
)
logger = logging.getLogger(__name__)


class YahooFinanceDownloader:
    """Yahoo Finance'den borsa verilerini indiren class"""
    
    # Varsayılan ticker listesi - Türkiye ve dünya borsaları
    DEFAULT_TICKERS = [
        # Türkiye Borsası
        "XU100.IS",     # BIST 100 Endeksi
        "XU030.IS",     # BIST 30 Endeksi  
        "XBANK.IS",     # BIST Banka Endeksi  
        
        # ABD Borsası
        "SPY",          # S&P 500 ETF
        "QQQ",          # NASDAQ 100 ETF  
        "IWM",          # Russell 2000 ETF

        
        # Avrupa Borsası
        "EFA",          # MSCI EAFE ETF
        "VEA",          # FTSE Developed Markets ETF
        "EWG",          # Germany ETF
        "EWU",          # United Kingdom ETF
        
        # Gelişen Piyasalar
        "EEM",          # Emerging Markets ETF
        "VWO",          # FTSE Emerging Markets ETF
        "FXI",          # China Large-Cap ETF
        
        
        # Kripto (Yahoo'da mevcut olanlar)
        "BTC-USD",      # Bitcoin
        "ETH-USD",      # Ethereum
        
        # Döviz Kurları
        "USDTRY=X",     # USD/TRY
        "EURTRY=X",     # EUR/TRY
        
        # ABD Tahvil Getirileri
        "^TNX",         # 10 Yıllık ABD Tahvil Getirisi
        "^FVX",         # 5 Yıllık ABD Tahvil Getirisi

        # Emtia Fiyatları
        "GC=F",         # Altın (XAU/USD)
        "SI=F",         # Gümüş (XAG/USD)
        "CL=F",         # Ham Petrol (WTI)
        
        # Risk Göstergeleri
        "^VIX",         # VIX Volatilite Endeksi
    ]
    
    def __init__(
        self,
        test_mode: bool = False,
        years_back: int = 0,
        months_back: int = 0,
        ticker_list: Optional[List[str]] = None,
        workers: int = 1,
        output_filename: str = "data/yahoo_finance_data.parquet",
        parallel_mode: Optional[bool] = None,
        repair_mode: bool = False,
        input_file: Optional[str] = None,
        start_date: Optional[str] = None,
        end_date: Optional[str] = None
    ):
        """
        Yahoo Finance Downloader
        
        Args:
            test_mode: Test modu (ticker listesini kısıtlar)
            years_back: Kaç yıl geriye git
            months_back: Kaç ay geriye git  
            ticker_list: İndirilecek ticker listesi
            workers: Paralel thread sayısı
            output_filename: Çıktı dosya adı
            parallel_mode: Paralel mod (None ise worker sayısına göre otomatik)
            repair_mode: Repair modu - eksik verileri tamamla
            input_file: Repair için input parquet dosyası
            start_date: Başlangıç tarihi (YYYYMMDD formatında, örn: 20230101)
            end_date: Bitiş tarihi (YYYYMMDD formatında, örn: 20250701)
        """
        self.test_mode = test_mode
        self.years_back = years_back
        self.months_back = months_back
        self.workers = max(1, workers)
        self.output_filename = output_filename
        self.repair_mode = repair_mode
        self.input_file = input_file
        self.start_date = start_date
        self.end_date = end_date
        
        # Data klasörünü oluştur (varsa dokunma)
        output_dir = Path(self.output_filename).parent
        if not output_dir.exists():
            output_dir.mkdir(parents=True, exist_ok=True)
            logger.info(f"Data klasörü oluşturuldu: {output_dir}")
        else:
            logger.debug(f"Data klasörü mevcut: {output_dir}")
            
        # Paralel mod belirleme
        if parallel_mode is None:
            self.parallel_mode = self.workers > 1
        else:
            self.parallel_mode = parallel_mode
            
        # Ticker listesi belirleme
        if ticker_list:
            self.ticker_list = ticker_list
        elif test_mode:
            # Test modunda sadece birkaç ticker
            self.ticker_list = ["XU100.IS", "SPY", "GLD", "USDTRY=X"]
        else:
            self.ticker_list = self.DEFAULT_TICKERS.copy()
            
        logger.info(f"Yahoo Finance Downloader başlatıldı")
        logger.info(f"Mod: {'Paralel' if self.parallel_mode else 'Seri'}")
        logger.info(f"Worker sayısı: {self.workers}")
        logger.info(f"Ticker sayısı: {len(self.ticker_list)}")
        logger.info(f"Çıktı dosyası: {self.output_filename}")

    def calculate_date_range(self) -> tuple[datetime, datetime]:
        """Tarih aralığını hesapla"""
        
        # Önce custom tarih aralığını kontrol et
        if self.start_date and self.end_date:
            try:
                start_date = datetime.strptime(self.start_date, '%Y%m%d')
                end_date = datetime.strptime(self.end_date, '%Y%m%d')
                
                logger.info(f"Custom tarih aralığı: {start_date.strftime('%Y-%m-%d')} → {end_date.strftime('%Y-%m-%d')}")
                return start_date, end_date
                
            except ValueError as e:
                logger.error(f"Tarih formatı hatası: {e}")
                logger.error("Tarih formatı YYYYMMDD olmalı (örn: 20230101)")
                raise
        
        # Custom tarih yoksa eski mantık: bugünden geriye doğru
        end_date = datetime.now()
        
        # Years parametresi öncelikli - eğer years verilmişse months'u görmezden gel
        if self.years_back > 0:
            start_date = end_date - relativedelta(years=self.years_back)
        elif self.months_back > 0:
            start_date = end_date - relativedelta(months=self.months_back)
        else:
            start_date = end_date - relativedelta(years=1)  # Varsayılan 1 yıl
            
        logger.info(f"Relative tarih aralığı: {start_date.strftime('%Y-%m-%d')} → {end_date.strftime('%Y-%m-%d')}")
        return start_date, end_date

    def fetch_ticker_data(self, ticker: str, start_date: datetime, end_date: datetime, retries: int = 3) -> List[Dict[str, Any]]:
        """Tek bir ticker için veri indir"""
        logger.debug(f"[FETCH] {ticker} verisi alınıyor...")
        
        for attempt in range(retries):
            try:
                # Yahoo Finance'den veri al
                yf_ticker = yf.Ticker(ticker)
                hist_data = yf_ticker.history(
                    start=start_date.strftime('%Y-%m-%d'),
                    end=end_date.strftime('%Y-%m-%d'),
                    auto_adjust=True,  # Splits ve dividends için ayarlama
                    back_adjust=True
                )
                
                if hist_data.empty:
                    logger.warning(f"[EMPTY] {ticker}: Veri bulunamadı")
                    return []
                
                # DataFrame'i liste formatına çevir - sadece istenen kolonlar
                hist_data.reset_index(inplace=True)
                hist_data['tarih'] = hist_data['Date'].dt.strftime('%Y-%m-%d')
                hist_data['ticker'] = ticker
                hist_data['fiyat'] = hist_data['Close']
                hist_data['hacim'] = hist_data['Volume'].fillna(0).astype(int)
                
                # Sadece istenen kolonları seç
                final_cols = ['tarih', 'ticker', 'fiyat', 'hacim']
                result_df = hist_data[final_cols]
                
                # Dictionary listesine çevir
                records = result_df.to_dict(orient='records')
                
                logger.info(f"[OK] {ticker}: {len(records)} kayıt")
                return records
                
            except Exception as e:
                if attempt < retries - 1:
                    wait_time = 2 ** attempt  # Exponential backoff
                    logger.warning(f"[RETRY {attempt+1}/{retries}] {ticker}: {e}")
                    time.sleep(wait_time)
                else:
                    logger.error(f"[FAIL] {ticker}: {e}")
                    return []
        
        return []

    def _fetch_single_ticker_data(self, ticker: str) -> List[Dict[str, Any]]:
        """Tek bir ticker'ı indir (paralel mod için)"""
        start_date, end_date = self.calculate_date_range()
        
        try:
            return self.fetch_ticker_data(ticker, start_date, end_date)
        except Exception as exc:
            logger.error(f"[ERROR] {ticker}: {exc}")
            return []

    def process_all_tickers_serial(self):
        """Tüm ticker'ları seri olarak işle"""
        logger.info("=== SERİ MOD BAŞLADI ===")
        
        start_date, end_date = self.calculate_date_range()
        logger.info(f"Tarih aralığı: {start_date.strftime('%Y-%m-%d')} - {end_date.strftime('%Y-%m-%d')}")
        
        all_data = []
        successful_tickers = 0
        failed_tickers = []
        
        try:
            for i, ticker in enumerate(self.ticker_list, 1):
                logger.info(f"[{i}/{len(self.ticker_list)}] İşleniyor: {ticker}")
                
                try:
                    ticker_data = self.fetch_ticker_data(ticker, start_date, end_date)
                    
                    if ticker_data:
                        all_data.extend(ticker_data)
                        successful_tickers += 1
                        logger.info(f"[OK] {ticker} başarılı")
                    else:
                        failed_tickers.append(ticker)
                        logger.warning(f"[FAIL] {ticker} veri alınamadı")
                        
                except Exception as e:
                    failed_tickers.append(ticker)
                    logger.error(f"[ERROR] {ticker} işlem hatası: {e}")
                
                # Her 5 ticker'dan sonra durum raporu
                if i % 5 == 0:
                    logger.info(f"Durum: {successful_tickers}/{i} başarılı, {len(all_data)} toplam kayıt")
            
            # Sonuçları işle ve kaydet
            if all_data:
                self.save_data(all_data, successful_tickers, failed_tickers)
            else:
                logger.error("[ERROR] Hiç veri alınamadı!")
                
        except Exception as e:
            logger.error(f"Seri işlem hatası: {e}")
            raise

    def process_all_tickers_parallel(self):
        """Tüm ticker'ları paralel olarak işle"""
        logger.info("=== PARALEL MOD BAŞLADI ===")
        
        start_date, end_date = self.calculate_date_range()
        logger.info(f"Tarih aralığı: {start_date.strftime('%Y-%m-%d')} - {end_date.strftime('%Y-%m-%d')}")
        
        all_data = []
        successful_tickers = 0
        failed_tickers = []
        
        try:
            # Ticker'ları küçük batch'lere böl
            batch_size = max(1, len(self.ticker_list) // self.workers)
            batches = [
                self.ticker_list[i:i + batch_size] 
                for i in range(0, len(self.ticker_list), batch_size)
            ]
            
            logger.info(f"Paralel işlem: {len(batches)} batch, {self.workers} worker")
            
            with ThreadPoolExecutor(max_workers=self.workers) as executor:
                # Her batch için future oluştur
                future_to_batch = {}
                for batch_idx, batch in enumerate(batches):
                    for ticker in batch:
                        future = executor.submit(self._fetch_single_ticker_data, ticker)
                        future_to_batch[future] = (batch_idx, ticker)
                
                # Sonuçları topla
                completed = 0
                for future in as_completed(future_to_batch):
                    batch_idx, ticker = future_to_batch[future]
                    completed += 1
                    
                    try:
                        ticker_data = future.result()
                        if ticker_data:
                            all_data.extend(ticker_data)
                            successful_tickers += 1
                            logger.info(f"[OK] {ticker} başarılı")
                        else:
                            failed_tickers.append(ticker)
                            logger.warning(f"[FAIL] {ticker} veri alınamadı")
                    except Exception as exc:
                        failed_tickers.append(ticker)
                        logger.error(f"[ERROR] {ticker}: {exc}")
                    
                    # İlerleme raporu
                    if completed % 5 == 0:
                        progress = (completed / len(self.ticker_list)) * 100
                        logger.info(f"[İLERLEME] {completed}/{len(self.ticker_list)} (%{progress:.1f}) - {len(all_data)} kayıt")
            
            # Sonuçları işle ve kaydet
            if all_data:
                self.save_data(all_data, successful_tickers, failed_tickers)
            else:
                logger.error("[ERROR] Hiç veri alınamadı!")
                
        except Exception as e:
            logger.error(f"Paralel işlem hatası: {e}")
            raise

    def save_data(self, all_data: List[Dict[str, Any]], successful_count: int, failed_tickers: List[str]):
        """Veriyi parquet dosyasına kaydet"""
        logger.info("=== VERİ KAYDETME ===")
        
        if not all_data:
            logger.error("Kaydedilecek veri yok!")
            return
        
        try:
            # DataFrame oluştur
            df = pd.DataFrame(all_data)
            
            # Tarih sütununu datetime'a çevir
            df['tarih'] = pd.to_datetime(df['tarih'])
            
            # Sırala ve duplikatları temizle
            df = df.sort_values(['ticker', 'tarih']).drop_duplicates()
            
            # Data klasörünü oluştur
            data_dir = Path("data")
            data_dir.mkdir(exist_ok=True)
            
            # Parquet dosyasına kaydet
            output_path = data_dir / self.output_filename
            df.to_parquet(output_path, index=False)
            
            # Excel'e de kaydet (analiz için)
            excel_path = output_path.with_suffix('.xlsx')
            df.to_excel(excel_path, index=False)
            
            # İstatistikler
            ticker_count = df['ticker'].nunique()
            total_records = len(df)
            date_range = f"{df['tarih'].min().strftime('%Y-%m-%d')} - {df['tarih'].max().strftime('%Y-%m-%d')}"
            
            logger.info(f"Parquet kaydedildi: {output_path}")
            logger.info(f"Excel kaydedildi: {excel_path}")
            logger.info(f"Istatistikler:")
            logger.info(f"   - Basarili ticker: {successful_count}/{len(self.ticker_list)}")
            logger.info(f"   - Toplam ticker: {ticker_count}")
            logger.info(f"   - Toplam kayit: {total_records:,}")
            logger.info(f"   - Tarih araligi: {date_range}")
            
            if failed_tickers:
                logger.warning(f"Basarisiz ticker'lar ({len(failed_tickers)}): {', '.join(failed_tickers)}")
            
            # Ticker başına özet
            ticker_summary = df.groupby('ticker').size().sort_values(ascending=False)
            logger.info(f"Ticker basina kayit sayisi:")
            for ticker, count in ticker_summary.head(10).items():
                logger.info(f"   - {ticker}: {count:,} kayit")
                
        except Exception as e:
            logger.error(f"Veri kaydetme hatası: {e}")
            raise

    def analyze_missing_dates(self) -> Dict[str, Tuple[datetime, datetime]]:
        """Eksik tarih aralıklarını analiz et"""
        if not self.input_file or not Path(self.input_file).exists():
            logger.error(f"[REPAIR] Input dosyası bulunamadı: {self.input_file}")
            return {}
        
        logger.info(f"[REPAIR] Mevcut veri analiz ediliyor: {self.input_file}")
        
        try:
            # Mevcut veriyi oku
            existing_df = pd.read_parquet(self.input_file)
            logger.info(f"[REPAIR] Mevcut kayıt sayısı: {len(existing_df):,}")
            
            # Tarih sütununu datetime'a çevir
            existing_df['tarih'] = pd.to_datetime(existing_df['tarih'])
            
            # Her ticker için son tarihi bul
            ticker_last_dates = existing_df.groupby('ticker')['tarih'].max()
            logger.info(f"[REPAIR] {len(ticker_last_dates)} ticker analiz ediliyor...")
            
            missing_ranges = {}
            today = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
            
            for ticker, last_date in ticker_last_dates.items():
                if ticker in self.ticker_list:  # Sadece istenen ticker'lar için
                    next_day = last_date + timedelta(days=1)
                    
                    if next_day.date() < today.date():
                        missing_ranges[ticker] = (next_day, today)
            
            completed_tickers = len(ticker_last_dates) - len(missing_ranges)
            total_tickers = len(self.ticker_list)
            
            logger.info(f"[ANALYSIS] {len(missing_ranges)} tane ticker eksik verili. {completed_tickers}/{total_tickers} tamamlanmış.")
            
            return missing_ranges
            
        except Exception as e:
            logger.error(f"[REPAIR] Analiz hatası: {e}")
            return {}

    def repair_missing_data(self):
        """Eksik verileri indir ve mevcut dosyaya ekle"""
        logger.info("[REPAIR MODE] Eksik veri tamamlama başlıyor...")
        
        try:
            # Eksik aralıkları analiz et
            missing_ranges = self.analyze_missing_dates()
            
            if not missing_ranges:
                logger.info("[REPAIR] Tüm ticker'lar güncel! Eksik veri yok.")
                return
            
            logger.info(f"[REPAIR] {len(missing_ranges)} ticker için eksik veri indiriliyor...")
            
            all_new_records = []
            
            def repair_single_ticker(ticker):
                """Tek bir ticker için repair işlemi"""
                start_date, end_date = missing_ranges[ticker]
                
                try:
                    logger.info(f"[REPAIR] {ticker}: {start_date.strftime('%Y-%m-%d')} - {end_date.strftime('%Y-%m-%d')}")
                    
                    # Request'ler arası delay ekle (rate limiting için)
                    time.sleep(0.5)
                    
                    # Veriyi indir
                    new_data = self.fetch_ticker_data(ticker, start_date, end_date)
                    
                    if new_data:
                        logger.info(f"[REPAIR] {ticker}: {len(new_data)} yeni kayıt")
                        return new_data
                    else:
                        logger.warning(f"[REPAIR] {ticker}: Veri bulunamadı")
                        return []
                        
                except Exception as e:
                    logger.error(f"[REPAIR] {ticker} hatası: {e}")
                    return []
            
            # Seri veya paralel mod seçimi
            if self.parallel_mode:
                # Paralel mod
                logger.info(f"[REPAIR] Paralel mod - {self.workers} worker")
                with ThreadPoolExecutor(max_workers=self.workers) as executor:
                    future_to_ticker = {
                        executor.submit(repair_single_ticker, ticker): ticker
                        for ticker in missing_ranges.keys()
                    }
                    
                    try:
                        for future in as_completed(future_to_ticker):
                            ticker = future_to_ticker[future]
                            try:
                                new_data = future.result()
                                if new_data:
                                    all_new_records.extend(new_data)
                            except Exception as e:
                                logger.error(f"[REPAIR] {ticker} paralel hatası: {e}")
                    except KeyboardInterrupt:
                        logger.info("[STOP] Kullanıcı tarafından durduruldu - paralel işlemler sonlandırılıyor...")
                        
                        # Çalışan görevleri iptal et
                        for future in future_to_ticker:
                            if not future.done():
                                future.cancel()
                        
                        # Executor'ı graceful shutdown yap
                        executor.shutdown(wait=False)
                        
                        # Tamamlanan sonuçları kontrol et
                        for future in future_to_ticker:
                            if future.done() and not future.cancelled():
                                ticker = future_to_ticker[future]
                                try:
                                    new_data = future.result()
                                    if new_data:
                                        all_new_records.extend(new_data)
                                        logger.info(f"[SAVED] {ticker}: {len(new_data)} kayıt kurtarıldı")
                                except Exception:
                                    pass
                        
                        logger.info(f"[STOP] {len(all_new_records)} kayıt kurtarıldı, işlem durduruluyor...")
            else:
                # Seri mod
                logger.info("[REPAIR] Seri mod")
                try:
                    for ticker in missing_ranges.keys():
                        new_data = repair_single_ticker(ticker)
                        if new_data:
                            all_new_records.extend(new_data)
                except KeyboardInterrupt:
                    logger.info(f"[STOP] Kullanıcı tarafından durduruldu - {len(all_new_records)} kayıt kurtarıldı")
            
            # Yeni verileri mevcut dosya ile birleştir
            if all_new_records:
                self.merge_with_existing_data(all_new_records)
            else:
                logger.warning("[REPAIR] Hiç yeni veri indirilemedi!")
                
        except Exception as e:
            logger.error(f"[REPAIR] Genel hata: {e}")
            raise

    def merge_with_existing_data(self, new_records: List[Dict[str, Any]]):
        """Yeni verileri mevcut dosya ile birleştir"""
        try:
            logger.info(f"[MERGE] {len(new_records)} yeni kayıt birleştiriliyor...")
            
            # Yeni verileri DataFrame'e çevir
            new_df = pd.DataFrame(new_records)
            
            # Mevcut veriyi oku
            existing_df = pd.read_parquet(self.input_file)
            
            # Birleştir ve duplikatları kaldır
            combined_df = pd.concat([existing_df, new_df], ignore_index=True)
            combined_df = combined_df.drop_duplicates(subset=['tarih', 'ticker'], keep='last')
            
            # Tarihe göre sırala
            combined_df['tarih'] = pd.to_datetime(combined_df['tarih'])
            combined_df = combined_df.sort_values(['ticker', 'tarih'])
            combined_df['tarih'] = combined_df['tarih'].dt.strftime('%Y-%m-%d')
            
            # Kaydet
            combined_df.to_parquet(self.output_filename, index=False)
            
            logger.info(f"[MERGE] Tamamlandı!")
            logger.info(f"[MERGE] Eski kayıt: {len(existing_df):,}")
            logger.info(f"[MERGE] Yeni kayıt: {len(new_df):,}")
            logger.info(f"[MERGE] Toplam kayıt: {len(combined_df):,}")
            logger.info(f"[MERGE] Dosya: {self.output_filename}")
            
        except Exception as e:
            logger.error(f"[MERGE] Birleştirme hatası: {e}")
            raise

    def run(self):
        """Ana çalışma fonksiyonu"""
        start_time = time.time()
        
        try:
            if self.repair_mode:
                # Repair mode
                if not self.input_file:
                    logger.error("[REPAIR] --input parametresi gerekli!")
                    return
                self.repair_missing_data()
            else:
                # Normal download mode
                if self.parallel_mode:
                    self.process_all_tickers_parallel()
                else:
                    self.process_all_tickers_serial()
                
            elapsed_time = time.time() - start_time
            logger.info(f"İşlem tamamlandı! Süre: {elapsed_time:.1f} saniye")
            
        except Exception as e:
            logger.error(f"İşlem hatası: {e}")
            raise


def main():
    """Komut satırı arayüzü"""
    parser = argparse.ArgumentParser(description='Yahoo Finance Veri İndirici')
    
    # Ana parametreler
    parser.add_argument('--test', action='store_true', help='Test modu (4 ticker)')
    parser.add_argument('--full', action='store_true', help='Tam mod (tüm ticker\'lar)')
    
    # Repair mode
    parser.add_argument('--repair', action='store_true', help='Repair modu - eksik verileri tamamla')
    parser.add_argument('--input', type=str, help='Repair için input parquet dosyası')
    
    # Tarih parametreleri
    parser.add_argument('--start-date', type=str, help='Başlangıç tarihi (YYYYMMDD, örn: 20230101)')
    parser.add_argument('--end-date', type=str, help='Bitiş tarihi (YYYYMMDD, örn: 20250701)')
    parser.add_argument('--years', type=int, default=0, help='Kaç yıl geriye git (custom tarih yoksa)')
    parser.add_argument('--months', type=int, default=12, help='Kaç ay geriye git (varsayılan: 12, custom tarih yoksa)')
    
    # İşlem parametreleri
    parser.add_argument('--workers', type=int, default=4, help='Paralel thread sayısı (varsayılan: 4)')
    parser.add_argument('--outfile', type=str, default='data/yahoo_finance_data.parquet', help='Çıktı dosya adı')
    
    # Ticker listesi
    parser.add_argument('--tickers', type=str, nargs='+', help='Özel ticker listesi (örn: SPY QQQ XU100.IS)')
    
    args = parser.parse_args()
    
    # Parametreleri logla
    logger.info("CMD: %s", " ".join(sys.argv))
    
    # Downloader oluştur ve çalıştır
    downloader = YahooFinanceDownloader(
        test_mode=args.test,
        years_back=args.years,
        months_back=args.months,
        ticker_list=args.tickers,
        workers=args.workers,
        output_filename=args.outfile,
        repair_mode=args.repair,
        input_file=args.input,
        start_date=args.start_date,
        end_date=args.end_date
    )
    
    downloader.run()


if __name__ == "__main__":
    main() 