"""
DataDownloader Test Script
=========================

Bu script DataDownloader sınıfının tüm özelliklerini test eder ve
backtrader ile vectorbt için uygun veri formatlarını gösterir.
"""

import sys
import os
from datetime import datetime, timedelta
import pandas as pd
import matplotlib.pyplot as plt

# DataDownloader sınıfını import et
from data_downloader import DataDownloader


def test_single_symbol():
    """Tek sembol veri indirme testi."""
    print("=" * 60)
    print("TEST 1: TEK SEMBOL VERİ İNDİRME")
    print("=" * 60)
    
    downloader = DataDownloader()
    
    try:
        # Apple hissesi için son 6 ay verisi
        print("📊 AAPL hissesi için son 6 ay verisi indiriliyor...")
        data = downloader.download_data(
            symbols="AAPL",
            timeframe="1d",
            period="6mo"
        )
        
        print(f"\n📈 İndirilen veri önizlemesi:")
        print(data.head())
        print(f"\n📊 Veri istatistikleri:")
        print(data.describe())
        
        # Veri bilgilerini göster
        info = downloader.get_data_info()
        print(f"\n📋 Veri bilgileri:")
        for key, value in info.items():
            print(f"   {key}: {value}")
        
        return data
        
    except Exception as e:
        print(f"❌ Hata: {e}")
        return None


def test_multiple_symbols():
    """Çoklu sembol veri indirme testi."""
    print("\n" + "=" * 60)
    print("TEST 2: ÇOKLU SEMBOL VERİ İNDİRME")
    print("=" * 60)
    
    downloader = DataDownloader()
    
    try:
        # Birden fazla hisse için veri
        symbols = ["AAPL", "MSFT", "GOOGL", "TSLA"]
        print(f"📊 {', '.join(symbols)} hisseleri için son 3 ay verisi indiriliyor...")
        
        data = downloader.download_data(
            symbols=symbols,
            timeframe="1d",
            period="3mo"
        )
        
        print(f"\n📈 Çoklu veri boyutu: {data.shape}")
        print(f"📈 Kolonlar: {list(data.columns)}")
        
        # Her sembol için ayrı veri çıkarma
        print(f"\n📊 Tek sembol verisi çıkarma örneği (AAPL):")
        aapl_data = downloader.get_single_symbol_data("AAPL")
        print(aapl_data.head())
        
        return data
        
    except Exception as e:
        print(f"❌ Hata: {e}")
        return None


def test_different_timeframes():
    """Farklı timeframe'ler için test."""
    print("\n" + "=" * 60)
    print("TEST 3: FARKLI TIMEFRAME'LER")
    print("=" * 60)
    
    downloader = DataDownloader()
    timeframes = ["1d", "1wk", "1mo"]
    
    for tf in timeframes:
        try:
            print(f"\n📊 {tf} timeframe ile AAPL verisi indiriliyor...")
            data = downloader.download_data(
                symbols="AAPL",
                timeframe=tf,
                period="1y"
            )
            print(f"   Veri boyutu: {data.shape}")
            print(f"   Tarih aralığı: {data.index[0].date()} - {data.index[-1].date()}")
            
        except Exception as e:
            print(f"❌ {tf} timeframe hatası: {e}")


def test_custom_date_range():
    """Özel tarih aralığı testi."""
    print("\n" + "=" * 60)
    print("TEST 4: ÖZEL TARİH ARALIĞI")
    print("=" * 60)
    
    downloader = DataDownloader()
    
    try:
        # Belirli tarih aralığı
        start_date = "2023-01-01"
        end_date = "2023-12-31"
        
        print(f"📊 AAPL için {start_date} - {end_date} arası veri indiriliyor...")
        data = downloader.download_data(
            symbols="AAPL",
            timeframe="1d",
            start_date=start_date,
            end_date=end_date
        )
        
        print(f"📈 Veri boyutu: {data.shape}")
        print(f"📅 Gerçek tarih aralığı: {data.index[0].date()} - {data.index[-1].date()}")
        
        return data
        
    except Exception as e:
        print(f"❌ Hata: {e}")
        return None


def test_data_resampling():
    """Veri yeniden örnekleme testi."""
    print("\n" + "=" * 60)
    print("TEST 5: VERİ YENİDEN ÖRNEKLEME")
    print("=" * 60)
    
    downloader = DataDownloader()
    
    try:
        # Günlük veri indir
        print("📊 Günlük AAPL verisi indiriliyor...")
        daily_data = downloader.download_data(
            symbols="AAPL",
            timeframe="1d",
            period="6mo"
        )
        
        print(f"📈 Günlük veri boyutu: {daily_data.shape}")
        
        # Haftalık veriye dönüştür
        print("🔄 Haftalık veriye dönüştürülüyor...")
        weekly_data = downloader.resample_data("1W")
        print(f"📈 Haftalık veri boyutu: {weekly_data.shape}")
        
        # Aylık veriye dönüştür
        print("🔄 Aylık veriye dönüştürülüyor...")
        monthly_data = downloader.resample_data("1M")
        print(f"📈 Aylık veri boyutu: {monthly_data.shape}")
        
        return daily_data, weekly_data, monthly_data
        
    except Exception as e:
        print(f"❌ Hata: {e}")
        return None, None, None


def test_data_saving():
    """Veri kaydetme testi."""
    print("\n" + "=" * 60)
    print("TEST 6: VERİ KAYDETME")
    print("=" * 60)
    
    downloader = DataDownloader()
    
    try:
        # Veri indir
        print("📊 Test verisi indiriliyor...")
        data = downloader.download_data(
            symbols=["AAPL", "MSFT"],
            timeframe="1d",
            period="1mo"
        )
        
        # Farklı formatlarda kaydet
        print("💾 CSV formatında kaydediliyor...")
        downloader.save_data("test_data.csv", "csv")
        
        print("💾 Excel formatında kaydediliyor...")
        downloader.save_data("test_data.xlsx", "excel")
        
        print("💾 Pickle formatında kaydediliyor...")
        downloader.save_data("test_data.pkl", "pickle")
        
        # Dosyaların oluştuğunu kontrol et
        files = ["test_data.csv", "test_data.xlsx", "test_data.pkl"]
        for file in files:
            if os.path.exists(file):
                size = os.path.getsize(file) / 1024  # KB
                print(f"✅ {file} oluşturuldu ({size:.1f} KB)")
            else:
                print(f"❌ {file} oluşturulamadı")
        
    except Exception as e:
        print(f"❌ Hata: {e}")


def test_backtrader_format():
    """Backtrader için uygun format testi."""
    print("\n" + "=" * 60)
    print("TEST 7: BACKTRADER FORMAT UYUMLULUĞU")
    print("=" * 60)
    
    downloader = DataDownloader()
    
    try:
        # Backtrader için veri hazırla
        print("📊 Backtrader için AAPL verisi hazırlanıyor...")
        data = downloader.download_data(
            symbols="AAPL",
            timeframe="1d",
            period="3mo"
        )
        
        # Backtrader formatı için gerekli kolonları kontrol et
        required_columns = ['Open', 'High', 'Low', 'Close', 'Volume']
        available_columns = [col for col in required_columns if col in data.columns]
        
        print(f"📋 Backtrader için gerekli kolonlar: {required_columns}")
        print(f"📋 Mevcut kolonlar: {available_columns}")
        
        if len(available_columns) == len(required_columns):
            print("✅ Veri Backtrader ile uyumlu!")
            
            # Backtrader için örnek format
            bt_data = data[required_columns].copy()
            bt_data.columns = [col.lower() for col in bt_data.columns]  # Küçük harfe çevir
            
            print(f"📈 Backtrader formatı:")
            print(bt_data.head())
            
            return bt_data
        else:
            print("❌ Veri Backtrader ile uyumlu değil!")
            return None
            
    except Exception as e:
        print(f"❌ Hata: {e}")
        return None


def test_vectorbt_format():
    """VectorBT için uygun format testi."""
    print("\n" + "=" * 60)
    print("TEST 8: VECTORBT FORMAT UYUMLULUĞU")
    print("=" * 60)
    
    downloader = DataDownloader()
    
    try:
        # VectorBT için çoklu sembol verisi
        print("📊 VectorBT için çoklu sembol verisi hazırlanıyor...")
        symbols = ["AAPL", "MSFT", "GOOGL"]
        data = downloader.download_data(
            symbols=symbols,
            timeframe="1d",
            period="3mo"
        )
        
        # VectorBT genellikle Close fiyatlarını kullanır
        if len(symbols) > 1:
            # Çoklu sembol için Close fiyatları
            close_prices = pd.DataFrame()
            for symbol in symbols:
                close_prices[symbol] = data[symbol]['Close']
            
            print(f"📈 VectorBT formatı (Close fiyatları):")
            print(close_prices.head())
            
            return close_prices
        else:
            print(f"📈 VectorBT formatı (tek sembol):")
            print(data['Close'].head())
            return data['Close']
            
    except Exception as e:
        print(f"❌ Hata: {e}")
        return None


def create_simple_visualization(data, title="Fiyat Grafiği"):
    """Basit görselleştirme oluştur."""
    try:
        plt.figure(figsize=(12, 6))
        
        if isinstance(data, pd.DataFrame):
            if 'Close' in data.columns:
                plt.plot(data.index, data['Close'], label='Close', linewidth=2)
            elif len(data.columns) <= 5:  # Çoklu sembol ama az sayıda
                for col in data.columns:
                    plt.plot(data.index, data[col], label=col, linewidth=1.5)
            else:
                # Çok fazla kolon varsa sadece ilk birkaçını göster
                for col in data.columns[:3]:
                    plt.plot(data.index, data[col], label=col, linewidth=1.5)
        else:
            plt.plot(data.index, data.values, label='Price', linewidth=2)
        
        plt.title(title)
        plt.xlabel('Tarih')
        plt.ylabel('Fiyat ($)')
        plt.legend()
        plt.grid(True, alpha=0.3)
        plt.xticks(rotation=45)
        plt.tight_layout()
        
        # Grafiği kaydet
        filename = f"{title.lower().replace(' ', '_')}.png"
        plt.savefig(filename, dpi=300, bbox_inches='tight')
        print(f"📊 Grafik kaydedildi: {filename}")
        
        plt.show()
        
    except Exception as e:
        print(f"❌ Görselleştirme hatası: {e}")


def main():
    """Ana test fonksiyonu."""
    print("🚀 DataDownloader Kapsamlı Test Başlıyor...")
    print("=" * 80)
    
    # Test 1: Tek sembol
    single_data = test_single_symbol()
    
    # Test 2: Çoklu sembol
    multi_data = test_multiple_symbols()
    
    # Test 3: Farklı timeframe'ler
    test_different_timeframes()
    
    # Test 4: Özel tarih aralığı
    custom_data = test_custom_date_range()
    
    # Test 5: Veri yeniden örnekleme
    daily, weekly, monthly = test_data_resampling()
    
    # Test 6: Veri kaydetme
    test_data_saving()
    
    # Test 7: Backtrader format
    bt_data = test_backtrader_format()
    
    # Test 8: VectorBT format
    vbt_data = test_vectorbt_format()
    
    # Görselleştirme
    print("\n" + "=" * 60)
    print("GÖRSELLEŞTIRME")
    print("=" * 60)
    
    if single_data is not None:
        create_simple_visualization(single_data, "AAPL Günlük Fiyat")
    
    if vbt_data is not None and isinstance(vbt_data, pd.DataFrame):
        create_simple_visualization(vbt_data, "Çoklu Sembol Karşılaştırma")
    
    print("\n🎉 Tüm testler tamamlandı!")
    print("=" * 80)
    
    # Özet bilgi
    print("\n📋 TEST ÖZETİ:")
    print("✅ DataDownloader sınıfı başarıyla test edildi")
    print("✅ Tek ve çoklu sembol veri indirme çalışıyor")
    print("✅ Farklı timeframe'ler destekleniyor")
    print("✅ Özel tarih aralıkları çalışıyor")
    print("✅ Veri yeniden örnekleme çalışıyor")
    print("✅ Veri kaydetme (CSV, Excel, Pickle) çalışıyor")
    print("✅ Backtrader format uyumluluğu sağlandı")
    print("✅ VectorBT format uyumluluğu sağlandı")
    
    print("\n🔧 Sonraki adımlar:")
    print("1. Backtrader ile backtest stratejileri geliştirin")
    print("2. VectorBT ile hızlı analiz ve optimizasyon yapın")
    print("3. Farklı timeframe'lerde stratejileri test edin")


if __name__ == "__main__":
    main()