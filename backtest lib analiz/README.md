# Backtest Library Analysis

Bu proje, **Backtrader** ve **VectorBT** kütüphanelerini karşılaştırmak ve test etmek için oluşturulmuştur. Yahoo Finance'ten veri indirme, backtest stratejileri geliştirme ve performans analizi yapma özelliklerini içerir.

## 📁 Proje Yapısı

```
backtest lib analiz/
├── data_downloader.py          # Yahoo Finance veri indirme sınıfı
├── test_data_downloader.py     # DataDownloader test scripti
├── requirements.txt            # Gerekli Python paketleri
├── README.md                   # Bu dosya
├── backtrader_examples/        # Backtrader örnekleri (oluşturulacak)
├── vectorbt_examples/          # VectorBT örnekleri (oluşturulacak)
└── data/                       # İndirilen veriler (oluşturulacak)
```

## 🚀 Kurulum

1. **Sanal ortam oluşturun (önerilen):**
```bash
python -m venv venv
venv\Scripts\activate  # Windows
# source venv/bin/activate  # Linux/Mac
```

2. **Gerekli paketleri yükleyin:**
```bash
pip install -r requirements.txt
```

## 📊 DataDownloader Sınıfı

### Özellikler
- ✅ Tek veya çoklu sembol veri indirme
- ✅ Farklı timeframe desteği (1m, 5m, 1h, 1d, 1w, 1m)
- ✅ Özel tarih aralığı belirleme
- ✅ Veri yeniden örnekleme
- ✅ CSV, Excel, Pickle formatında kaydetme
- ✅ Backtrader ve VectorBT uyumlu format

### Kullanım Örneği

```python
from data_downloader import DataDownloader

# DataDownloader örneği oluştur
downloader = DataDownloader()

# Tek sembol veri indirme
data = downloader.download_data(
    symbols="AAPL",
    timeframe="1d",
    period="6mo"
)

# Çoklu sembol veri indirme
multi_data = downloader.download_data(
    symbols=["AAPL", "MSFT", "GOOGL"],
    timeframe="1d",
    start_date="2023-01-01",
    end_date="2023-12-31"
)

# Veriyi kaydetme
downloader.save_data("my_data.csv", "csv")
```

### Desteklenen Timeframe'ler
- **Dakika:** 1m, 2m, 5m, 15m, 30m, 60m, 90m
- **Saat:** 1h
- **Gün:** 1d, 5d
- **Hafta:** 1wk
- **Ay:** 1mo, 3mo

### Desteklenen Period'lar
- 1d, 5d, 1mo, 3mo, 6mo, 1y, 2y, 5y, 10y, ytd, max

## 🧪 Test Etme

DataDownloader sınıfını test etmek için:

```bash
python test_data_downloader.py
```

Bu script şu testleri yapar:
1. ✅ Tek sembol veri indirme
2. ✅ Çoklu sembol veri indirme
3. ✅ Farklı timeframe'ler
4. ✅ Özel tarih aralığı
5. ✅ Veri yeniden örnekleme
6. ✅ Veri kaydetme (CSV, Excel, Pickle)
7. ✅ Backtrader format uyumluluğu
8. ✅ VectorBT format uyumluluğu

## 📈 Backtrader vs VectorBT

### Backtrader
- **Avantajlar:**
  - Detaylı backtest raporları
  - Esnek strateji geliştirme
  - Görselleştirme desteği
  - Geniş topluluk desteği

- **Dezavantajlar:**
  - Daha yavaş performans
  - Daha karmaşık syntax

### VectorBT
- **Avantajlar:**
  - Çok hızlı performans (vectorized)
  - Kolay optimizasyon
  - Modern Python syntax
  - Paralel işlem desteği

- **Dezavantajlar:**
  - Daha az dokümantasyon
  - Daha az topluluk desteği

## 🔧 Gelecek Özellikler

- [ ] Backtrader örnek stratejileri
- [ ] VectorBT örnek stratejileri
- [ ] Performans karşılaştırma araçları
- [ ] Risk yönetimi modülleri
- [ ] Teknik analiz indikatörleri
- [ ] Portföy optimizasyonu
- [ ] Canlı trading bağlantısı

## 📝 Notlar

- Yahoo Finance API'si ücretsizdir ancak rate limiting vardır
- Intraday veriler (1m, 5m, etc.) sadece son 60 gün için mevcuttur
- Bazı semboller farklı borsalarda işlem görebilir (.IS, .L, etc.)

## 🤝 Katkıda Bulunma

1. Fork yapın
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Commit yapın (`git commit -m 'Add amazing feature'`)
4. Push yapın (`git push origin feature/amazing-feature`)
5. Pull Request oluşturun

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır.

## 📞 İletişim

Sorularınız için issue açabilir veya pull request gönderebilirsiniz.

---

**Happy Trading! 📈🚀**