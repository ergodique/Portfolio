"""
Data Downloader Class for Backtest Libraries
============================================

Bu modül Yahoo Finance'ten finansal veri indirmek için DataDownloader sınıfını içerir.
Backtrader ve VectorBT kütüphaneleri ile uyumlu veri formatında çıktı sağlar.
"""

import yfinance as yf
import pandas as pd
from datetime import datetime, timedelta
from typing import Union, List, Optional, Dict, Any
import warnings

warnings.filterwarnings('ignore')


class DataDownloader:
    """
    Yahoo Finance'ten finansal veri indirmek için kullanılan sınıf.
    
    Bu sınıf tek veya birden fazla enstrüman için belirtilen zaman aralığında
    ve timeframe'de veri indirebilir.
    """
    
    def __init__(self):
        """DataDownloader sınıfını başlatır."""
        self.data = None
        self.symbols = None
        
    def download_data(self, 
                     symbols: Union[str, List[str]], 
                     timeframe: str = "1d",
                     start_date: Optional[Union[str, datetime]] = None,
                     end_date: Optional[Union[str, datetime]] = None,
                     period: Optional[str] = None) -> pd.DataFrame:
        """
        Yahoo Finance'ten veri indirir.
        
        Parameters:
        -----------
        symbols : str or list of str
            İndirilecek enstrüman sembolleri (örn: "AAPL" veya ["AAPL", "MSFT"])
        timeframe : str, default "1d"
            Veri timeframe'i. Seçenekler:
            - "1m", "2m", "5m", "15m", "30m", "60m", "90m" (dakika)
            - "1h" (saat)
            - "1d" (gün)
            - "5d" (5 gün)
            - "1wk" (hafta)
            - "1mo" (ay)
            - "3mo" (3 ay)
        start_date : str or datetime, optional
            Başlangıç tarihi (YYYY-MM-DD formatında)
        end_date : str or datetime, optional
            Bitiş tarihi (YYYY-MM-DD formatında)
        period : str, optional
            Alternatif olarak period kullanılabilir:
            "1d", "5d", "1mo", "3mo", "6mo", "1y", "2y", "5y", "10y", "ytd", "max"
            
        Returns:
        --------
        pd.DataFrame
            İndirilen veri (OHLCV formatında)
        """
        
        # Sembolleri normalize et
        if isinstance(symbols, str):
            symbols = [symbols]
        
        self.symbols = symbols
        
        # Tarih parametrelerini kontrol et
        if period is None and (start_date is None or end_date is None):
            # Varsayılan olarak son 1 yıl
            end_date = datetime.now()
            start_date = end_date - timedelta(days=365)
            print(f"Tarih belirtilmediği için son 1 yıl verisi indirilecek: {start_date.date()} - {end_date.date()}")
        
        try:
            # Veriyi indir
            if len(symbols) == 1:
                ticker = yf.Ticker(symbols[0])
                if period:
                    data = ticker.history(period=period, interval=timeframe)
                else:
                    data = ticker.history(start=start_date, end=end_date, interval=timeframe)
                
                # Tek sembol için MultiIndex'i kaldır
                if isinstance(data.columns, pd.MultiIndex):
                    data.columns = data.columns.droplevel(1)
                    
            else:
                # Birden fazla sembol için
                if period:
                    data = yf.download(symbols, period=period, interval=timeframe, group_by='ticker')
                else:
                    data = yf.download(symbols, start=start_date, end=end_date, interval=timeframe, group_by='ticker')
            
            # Veriyi temizle
            data = data.dropna()
            
            if data.empty:
                raise ValueError("İndirilen veri boş. Sembol adlarını ve tarih aralığını kontrol edin.")
            
            self.data = data
            
            print(f"✅ Veri başarıyla indirildi:")
            print(f"   Semboller: {', '.join(symbols)}")
            print(f"   Timeframe: {timeframe}")
            print(f"   Veri boyutu: {data.shape}")
            print(f"   Tarih aralığı: {data.index[0].date()} - {data.index[-1].date()}")
            
            return data
            
        except Exception as e:
            print(f"❌ Veri indirme hatası: {str(e)}")
            raise
    
    def get_single_symbol_data(self, symbol: str) -> pd.DataFrame:
        """
        Çoklu sembol verisinden tek bir sembolün verisini döndürür.
        
        Parameters:
        -----------
        symbol : str
            İstenen sembol adı
            
        Returns:
        --------
        pd.DataFrame
            Tek sembol verisi
        """
        if self.data is None:
            raise ValueError("Önce veri indirmelisiniz.")
        
        if len(self.symbols) == 1:
            return self.data
        
        if symbol not in self.symbols:
            raise ValueError(f"Sembol '{symbol}' indirilen veriler arasında bulunamadı.")
        
        # MultiIndex kolonlardan tek sembol verisini çıkar
        symbol_data = self.data[symbol].copy()
        return symbol_data
    
    def save_data(self, filename: str, format: str = "csv") -> None:
        """
        İndirilen veriyi dosyaya kaydeder.
        
        Parameters:
        -----------
        filename : str
            Dosya adı
        format : str, default "csv"
            Dosya formatı ("csv", "excel", "pickle")
        """
        if self.data is None:
            raise ValueError("Kaydedilecek veri yok. Önce veri indirin.")
        
        if format.lower() == "csv":
            self.data.to_csv(filename)
        elif format.lower() == "excel":
            self.data.to_excel(filename)
        elif format.lower() == "pickle":
            self.data.to_pickle(filename)
        else:
            raise ValueError("Desteklenen formatlar: csv, excel, pickle")
        
        print(f"✅ Veri {filename} dosyasına kaydedildi.")
    
    def get_data_info(self) -> Dict[str, Any]:
        """
        İndirilen veri hakkında bilgi döndürür.
        
        Returns:
        --------
        dict
            Veri bilgileri
        """
        if self.data is None:
            return {"error": "Veri henüz indirilmedi"}
        
        info = {
            "symbols": self.symbols,
            "shape": self.data.shape,
            "start_date": self.data.index[0],
            "end_date": self.data.index[-1],
            "columns": list(self.data.columns),
            "missing_values": self.data.isnull().sum().sum(),
            "memory_usage": f"{self.data.memory_usage(deep=True).sum() / 1024**2:.2f} MB"
        }
        
        return info
    
    def resample_data(self, timeframe: str) -> pd.DataFrame:
        """
        Mevcut veriyi farklı bir timeframe'e dönüştürür.
        
        Parameters:
        -----------
        timeframe : str
            Hedef timeframe (örn: "1H", "1D", "1W")
            
        Returns:
        --------
        pd.DataFrame
            Yeniden örneklenmiş veri
        """
        if self.data is None:
            raise ValueError("Önce veri indirmelisiniz.")
        
        # OHLCV verisi için uygun aggregation
        agg_dict = {
            'Open': 'first',
            'High': 'max',
            'Low': 'min',
            'Close': 'last',
            'Volume': 'sum'
        }
        
        if len(self.symbols) == 1:
            # Tek sembol için
            resampled = self.data.resample(timeframe).agg(agg_dict)
        else:
            # Çoklu sembol için
            resampled_data = {}
            for symbol in self.symbols:
                symbol_data = self.data[symbol]
                resampled_data[symbol] = symbol_data.resample(timeframe).agg(agg_dict)
            
            resampled = pd.concat(resampled_data, axis=1)
        
        # NaN değerleri temizle
        resampled = resampled.dropna()
        
        print(f"✅ Veri {timeframe} timeframe'ine dönüştürüldü. Yeni boyut: {resampled.shape}")
        
        return resampled


# Kullanım örneği ve test fonksiyonları
def example_usage():
    """DataDownloader sınıfının kullanım örneği."""
    
    print("=== DataDownloader Kullanım Örneği ===\n")
    
    # DataDownloader örneği oluştur
    downloader = DataDownloader()
    
    # Tek sembol veri indirme
    print("1. Tek sembol veri indirme (AAPL):")
    data = downloader.download_data("AAPL", timeframe="1d", period="6mo")
    print(f"İndirilen veri:\n{data.head()}\n")
    
    # Veri bilgilerini göster
    print("2. Veri bilgileri:")
    info = downloader.get_data_info()
    for key, value in info.items():
        print(f"   {key}: {value}")
    print()
    
    # Çoklu sembol veri indirme
    print("3. Çoklu sembol veri indirme (AAPL, MSFT, GOOGL):")
    symbols = ["AAPL", "MSFT", "GOOGL"]
    multi_data = downloader.download_data(symbols, timeframe="1d", period="3mo")
    print(f"Çoklu veri boyutu: {multi_data.shape}\n")
    
    # Tek sembol verisi çıkarma
    print("4. Tek sembol verisi çıkarma (AAPL):")
    aapl_data = downloader.get_single_symbol_data("AAPL")
    print(f"AAPL verisi:\n{aapl_data.head()}\n")


if __name__ == "__main__":
    example_usage()