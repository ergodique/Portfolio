import argparse
from pathlib import Path
import pandas as pd
import pyarrow.parquet as pq
import pyarrow as pa
import logging
from typing import Optional

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

WINDOWS = {
    "ret_1w": 7,    # 7 gün
    "ret_1m": 30,   # 30 gün ≈ 1 ay
    "ret_3m": 90,   # 3 ay
    "ret_6m": 180,  # 6 ay
    "ret_12m": 365  # 12 ay
}

# Tüm tickerlar için normal getiri hesaplanacak

class YahooFinanceDataProcessor:
    """Yahoo Finance verilerini işleyen class"""
    
    def __init__(self, input_file: str, output_file: Optional[str] = None, excel_file: Optional[str] = None):
        """
        Args:
            input_file: Giriş parquet dosyası
            output_file: Çıkış parquet dosyası (opsiyonel)
            excel_file: Excel çıkış dosyası (opsiyonel)
        """
        self.input_path = Path(input_file)
        
        if output_file:
            self.output_path = Path(output_file)
        else:
            # Varsayılan: input_file_processed.parquet
            self.output_path = self.input_path.with_stem(self.input_path.stem + "_processed")
        
        if excel_file:
            self.excel_path = Path(excel_file)
        else:
            # Varsayılan: output_file.xlsx
            self.excel_path = self.output_path.with_suffix(".xlsx")
    
    def load_data(self) -> pd.DataFrame:
        """Parquet dosyasını yükle"""
        if not self.input_path.exists():
            raise FileNotFoundError(f"Giriş dosyası bulunamadı: {self.input_path}")
        
        logger.info(f"{self.input_path} yükleniyor...")
        df = pq.read_table(self.input_path).to_pandas()
        
        # Tarih sütunu garanti altına al
        if df["tarih"].dtype != "datetime64[ns]":
            df["tarih"] = pd.to_datetime(df["tarih"])
        
        # Fiyat sütunu kontrolü
        if "fiyat" not in df.columns:
            raise ValueError("'fiyat' sütunu bulunamadı. İşlem iptal.")
        
        # Hacim sütununu at (kullanmıyoruz)
        if "hacim" in df.columns:
            df = df.drop(columns=["hacim"])
            logger.info("Hacim kolonu atıldı")
        
        logger.info(f"Veri yüklendi: {len(df)} kayıt, {df['ticker'].nunique()} ticker")
        return df
    
    def compute_returns_for_ticker(self, ticker_data: pd.DataFrame) -> pd.DataFrame:
        """Tek bir ticker için getiri hesapla"""
        ticker = ticker_data["ticker"].iloc[0]
        g = ticker_data.copy().sort_values("tarih")
        
        # Yeni kolonları NaN ile oluştur
        for col in WINDOWS.keys():
            g[col] = pd.NA
        
        logger.debug(f"[NORMAL] {ticker}: Normal getiri hesaplanıyor")
        g["fiyat"] = pd.to_numeric(g["fiyat"], errors="coerce")
        
        # Günlük frekansa geç – eksik günleri ileriye doğru doldur (ffill)
        s_daily = (
            g.set_index("tarih")["fiyat"]
            .asfreq("D")
            .ffill()
        )
        
        for col, days in WINDOWS.items():
            shifted = s_daily.shift(days)
            ret_series = s_daily / shifted - 1
            # Orijinal tarihlere geri map et
            g[col] = ret_series.reindex(g["tarih"]).values
        
        return g
    
    def compute_rolling_returns(self, df: pd.DataFrame) -> pd.DataFrame:
        """Tüm tickerlar için kaydırmalı getirileri hesapla"""
        df = df.sort_values(["ticker", "tarih"]).copy()
        
        result_frames = []
        
        for ticker, grp in df.groupby("ticker", sort=False):
            processed_ticker = self.compute_returns_for_ticker(grp)
            result_frames.append(processed_ticker)
        
        df_out = pd.concat(result_frames, ignore_index=True)
        return df_out
    
    def save_data(self, df: pd.DataFrame):
        """Verileri parquet ve excel olarak kaydet"""
        logger.info(f"Son sütun listesi: {df.columns.tolist()}")
        
        # Parquet'e yaz
        self.output_path.parent.mkdir(exist_ok=True)
        df.to_parquet(self.output_path, engine="pyarrow", compression="zstd", index=False)
        logger.info(f"Parquet çıktı: {self.output_path}")
        
        # Excel'e yaz
        df.to_excel(self.excel_path, index=False)
        logger.info(f"Excel çıktı: {self.excel_path}")
        
        logger.info(f"Tamamlandı: {len(df)} kayıt, {df['ticker'].nunique()} ticker")
    
    def process(self):
        """Ana işlem fonksiyonu"""
        # Veriyi yükle
        df = self.load_data()
        
        # Return hesapla
        df_processed = self.compute_rolling_returns(df)
        
        # Kaydet
        self.save_data(df_processed)
        
        return df_processed

def main():
    parser = argparse.ArgumentParser(description="Yahoo Finance verisine rolling getiriler ekle")
    parser.add_argument("--input", type=str, required=True, help="Giriş Parquet yolu")
    parser.add_argument("--output", type=str, default="", help="Çıkış Parquet yolu (varsayılan: input_processed.parquet)")
    parser.add_argument("--excel", type=str, default="", help="Excel çıktı yolu (.xlsx). Boş bırakılırsa output temel alınır.")
    
    args = parser.parse_args()
    
    # Processor oluştur ve çalıştır
    processor = YahooFinanceDataProcessor(
        input_file=args.input,
        output_file=args.output if args.output else None,
        excel_file=args.excel if args.excel else None
    )
    
    processor.process()

if __name__ == "__main__":
    main() 