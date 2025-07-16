import argparse
import logging
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any, Dict, List, Optional

import pandas as pd
import yfinance as yf
from dateutil.relativedelta import relativedelta

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
        output_filename: str = "yahoo_finance_data.parquet",
        parallel_mode: Optional[bool] = None
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
        """
        self.test_mode = test_mode
        self.years_back = years_back
        self.months_back = months_back
        self.workers = max(1, workers)
        self.output_filename = output_filename
        
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
        end_date = datetime.now()
        
        # Years parametresi öncelikli - eğer years verilmişse months'u görmezden gel
        if self.years_back > 0:
            start_date = end_date - relativedelta(years=self.years_back)
        elif self.months_back > 0:
            start_date = end_date - relativedelta(months=self.months_back)
        else:
            start_date = end_date - relativedelta(years=1)  # Varsayılan 1 yıl
            
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

    def run(self):
        """Ana çalışma fonksiyonu"""
        start_time = time.time()
        
        try:
            if self.parallel_mode:
                self.process_all_tickers_parallel()
            else:
                self.process_all_tickers_serial()
                
            elapsed_time = time.time() - start_time
            logger.info(f"Islem tamamlandi! Sure: {elapsed_time:.1f} saniye")
            
        except Exception as e:
            logger.error(f"İşlem hatası: {e}")
            raise


def main():
    """Komut satırı arayüzü"""
    parser = argparse.ArgumentParser(description='Yahoo Finance Veri İndirici')
    
    # Ana parametreler
    parser.add_argument('--test', action='store_true', help='Test modu (4 ticker)')
    parser.add_argument('--full', action='store_true', help='Tam mod (tüm ticker\'lar)')
    
    # Zaman parametreleri
    parser.add_argument('--years', type=int, default=0, help='Kaç yıl geriye git')
    parser.add_argument('--months', type=int, default=12, help='Kaç ay geriye git (varsayılan: 12)')
    
    # İşlem parametreleri
    parser.add_argument('--workers', type=int, default=4, help='Paralel thread sayısı (varsayılan: 4)')
    parser.add_argument('--outfile', type=str, default='yahoo_finance_data.parquet', help='Çıktı dosya adı')
    
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
        output_filename=args.outfile
    )
    
    downloader.run()


if __name__ == "__main__":
    main() 