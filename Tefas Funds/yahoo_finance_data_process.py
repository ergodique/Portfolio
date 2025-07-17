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
    
    def __init__(self, input_file: str, output_file: Optional[str] = None, excel_file: Optional[str] = None, create_wide_format: bool = True):
        """
        Args:
            input_file: Giriş parquet dosyası
            output_file: Çıkış parquet dosyası (opsiyonel)
            excel_file: Excel çıkış dosyası (opsiyonel)
            create_wide_format: Wide format oluştur (default: True)
        """
        # Input dosyası - data/ klasöründe ara
        input_path = Path(input_file)
        if not input_path.exists() and not input_path.is_absolute():
            # Dosya yoksa data/ klasöründe ara
            data_path = Path("data") / input_file
            if data_path.exists():
                self.input_path = data_path
                logger.info(f"Input dosyası data/ klasöründe bulundu: {data_path}")
            else:
                self.input_path = input_path  # Orijinal path'i koru (hata mesajı için)
        else:
            self.input_path = input_path
        
        # Wide format flag'ini sakla
        self.create_wide_format = create_wide_format
        
        if output_file:
            output_path = Path(output_file)
            # Absolute path değilse data/ klasörü altına koy
            if not output_path.is_absolute():
                self.output_path = Path("data") / output_file
            else:
                self.output_path = output_path
        else:
            # Varsayılan: data/input_file_wide.parquet veya data/input_file_processed.parquet
            if create_wide_format:
                output_name = self.input_path.stem + "_wide.parquet"
            else:
                output_name = self.input_path.stem + "_processed.parquet"
            self.output_path = Path("data") / output_name
        
        if excel_file:
            excel_path = Path(excel_file)
            # Absolute path değilse data/ klasörü altına koy
            if not excel_path.is_absolute():
                self.excel_path = Path("data") / excel_file
            else:
                self.excel_path = excel_path
        else:
            # Varsayılan: data/output_file.xlsx
            excel_name = self.output_path.stem + ".xlsx"
            self.excel_path = Path("data") / excel_name
        
        # Data klasörünü oluştur (varsa dokunma)
        output_dir = self.output_path.parent
        excel_dir = self.excel_path.parent
        
        if not output_dir.exists():
            output_dir.mkdir(parents=True, exist_ok=True)
            logger.info(f"Data klasörü oluşturuldu: {output_dir}")
        
        if not excel_dir.exists() and excel_dir != output_dir:
            excel_dir.mkdir(parents=True, exist_ok=True)
            logger.info(f"Excel klasörü oluşturuldu: {excel_dir}")
    
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
    
    def clean_ticker_name(self, ticker: str) -> str:
        """Ticker adını ML için uygun hale getir"""
        # Özel karakterleri temizle ve küçük harfe çevir
        cleaned = ticker.lower()
        cleaned = cleaned.replace("-", "")
        cleaned = cleaned.replace("=", "")
        cleaned = cleaned.replace("^", "")
        cleaned = cleaned.replace(".is", "")
        cleaned = cleaned.replace(".f", "")
        cleaned = cleaned.replace("=x", "")
        
        return cleaned
    
    def explode_to_wide_format(self, df: pd.DataFrame) -> pd.DataFrame:
        """Long format'ı wide format'a çevir (ML için)"""
        logger.info("Wide format'a çevriliyor...")
        
        # Haftasonu günlerini filtrele (Cumartesi=5, Pazar=6)
        df["weekday"] = df["tarih"].dt.weekday
        weekday_count = len(df)
        df = df[df["weekday"] < 5]  # 0=Pazartesi, 4=Cuma
        weekend_removed = weekday_count - len(df)
        if weekend_removed > 0:
            logger.info(f"Haftasonu günleri silindi: {weekend_removed} kayıt")
        
        # Geçici weekday kolonunu sil
        df = df.drop(columns=["weekday"])
        
        # Ticker isimlerini temizle
        df["clean_ticker"] = df["ticker"].apply(self.clean_ticker_name)
        
        # Pivot işlemi için value kolonları
        value_columns = ["fiyat", "ret_1w", "ret_1m", "ret_3m", "ret_6m", "ret_12m"]
        
        result_dfs = []
        
        for col in value_columns:
            # Her kolon için ayrı pivot yap
            pivot_df = df.pivot(index="tarih", columns="clean_ticker", values=col)
            
            # Kolon isimlerini düzenle: ticker_kolon
            pivot_df.columns = [f"{ticker}_{col}" for ticker in pivot_df.columns]
            
            result_dfs.append(pivot_df)
        
        # Tüm pivot'ları birleştir
        wide_df = pd.concat(result_dfs, axis=1)
        # DataFrame olarak garanti et
        if not isinstance(wide_df, pd.DataFrame):
            wide_df = wide_df.to_frame()
        
        # Index'i sıfırla (tarih kolonu olsun)
        wide_df.reset_index(inplace=True)
        
        # Kolonları sırala (tarih + ticker bazlı mantıklı sıralama)
        tarih_col = ["tarih"]
        
        # Ticker listesini al ve sırala
        tickers = df["clean_ticker"].unique()
        sorted_tickers = sorted(tickers)
        
        # Her ticker için doğru sıralama: fiyat, ret_1w, ret_1m, ret_3m, ret_6m, ret_12m
        ordered_columns = []
        for ticker in sorted_tickers:
            ordered_columns.extend([
                f"{ticker}_fiyat",
                f"{ticker}_ret_1w", 
                f"{ticker}_ret_1m",
                f"{ticker}_ret_3m",
                f"{ticker}_ret_6m",
                f"{ticker}_ret_12m"
            ])
        
        # Sadece mevcut kolonları al (bazıları eksik olabilir)
        available_cols = [col for col in ordered_columns if col in wide_df.columns]
        wide_df = wide_df[tarih_col + available_cols]
        
        logger.info(f"Wide format: {len(wide_df)} tarih, {len(wide_df.columns)-1} feature")
        return wide_df

    def save_data(self, df: pd.DataFrame, wide_df: Optional[pd.DataFrame] = None):
        """Verileri parquet ve excel olarak kaydet"""
        logger.info(f"Long format sütun listesi: {df.columns.tolist()}")
        
        # Long format'ı kaydet
        self.output_path.parent.mkdir(exist_ok=True)
        df.to_parquet(self.output_path, engine="pyarrow", compression="zstd", index=False)
        logger.info(f"Long format parquet: {self.output_path}")
        
        df.to_excel(self.excel_path, index=False)
        logger.info(f"Long format excel: {self.excel_path}")
        
        # Wide format varsa onu da kaydet
        if wide_df is not None:
            wide_parquet_path = self.output_path.with_stem(self.output_path.stem + "_wide")
            wide_excel_path = self.excel_path.with_stem(self.excel_path.stem + "_wide")
            
            wide_df.to_parquet(wide_parquet_path, engine="pyarrow", compression="zstd", index=False)
            logger.info(f"Wide format parquet: {wide_parquet_path}")
            
            wide_df.to_excel(wide_excel_path, index=False)
            logger.info(f"Wide format excel: {wide_excel_path}")
        
        logger.info(f"Tamamlandı: {len(df)} kayıt, {df['ticker'].nunique()} ticker")
    
    def process(self):
        """Ana işlem fonksiyonu"""
        # Veriyi yükle
        df = self.load_data()
        
        # Return hesapla
        df_processed = self.compute_rolling_returns(df)
        
        # Wide format oluştur (constructor'da belirlenen ayara göre)
        wide_df = None
        if self.create_wide_format:
            wide_df = self.explode_to_wide_format(df_processed)
        
        # Kaydet
        self.save_data(df_processed, wide_df)
        
        return df_processed, wide_df

def main():
    parser = argparse.ArgumentParser(description="Yahoo Finance verisine rolling getiriler ekle")
    parser.add_argument("--input", type=str, required=True, help="Giriş Parquet yolu")
    parser.add_argument("--output", type=str, default="", help="Çıkış Parquet yolu (varsayılan: data/input_wide.parquet)")
    parser.add_argument("--excel", type=str, default="", help="Excel çıktı yolu (varsayılan: data/output.xlsx)")
    parser.add_argument("--no-wide", action="store_true", help="Wide format oluşturma (ML için explode etme)")
    
    args = parser.parse_args()
    
    create_wide = not args.no_wide  # Default True, --no-wide ile False
    
    # Processor oluştur ve çalıştır
    processor = YahooFinanceDataProcessor(
        input_file=args.input,
        output_file=args.output if args.output else None,
        excel_file=args.excel if args.excel else None,
        create_wide_format=create_wide
    )
    
    processor.process()

if __name__ == "__main__":
    main() 