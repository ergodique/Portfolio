# TEFAS Fon Veri Analiz Sistemi

Bu proje, TEFAS (Türkiye Elektronik Fon Alım Satım Platformu) fonlarının geçmiş verilerini indirme, işleme ve analiz etme için geliştirilmiş kapsamlı bir Python sistemidir. Ayrıca Yahoo Finance'den borsa verilerini indirme ve karşılaştırmalı analiz yapma özelliklerini de içerir.

## 📋 İçindekiler

1. [Kurulum](#kurulum)
2. [Temel Komponentler](#temel-komponentler)
3. [TEFAS Veri İndirme](#tefas-veri-indirme)
4. [Veri İşleme ve Analiz](#veri-işleme-ve-analiz)
5. [Yahoo Finance İndirme](#yahoo-finance-indirme)
6. [Örnek Kullanım Senaryoları](#örnek-kullanım-senaryoları)
7. [Troubleshooting](#troubleshooting)

## 🚀 Kurulum

### Gereksinimler

```bash
pip install -r requirements.txt
```

### Dizin Yapısı
```
Tefas Funds/
├── data/                           # İndirilen ve işlenmiş veriler
├── log/                            # Log dosyaları
├── providers/                      # Veri sağlayıcı modülleri
├── tefas_download_data_merged.py   # Ana TEFAS indirme scripti
├── tefas_data_process.py          # Wide format veri işleme
├── yahoo_finance_downloader.py    # Yahoo Finance indirme
├── yahoo_finance_data_process.py  # Yahoo Finance veri işleme
├── remove_last_records.py         # Test/repair yardımcı script
└── requirements.txt               # Python bağımlılıkları
```

## 🧩 Temel Komponentler

### 1. TEFAS İndirme Motoru (`tefas_download_data_merged.py`)

TEFAS'tan fon verilerini indiren ana script. Üç farklı modda çalışır:

**Özellikler:**
- ✅ Seri ve paralel indirme desteği
- ✅ Repair modu (eksik verileri tamamlama)
- ✅ Rate limiting ve error handling
- ✅ Chunk-based tarih aralığı işleme
- ✅ Otomatik kategori sınıflandırması

### 2. Veri İşleme Motoru (`tefas_data_process.py`)

Long format TEFAS verisini wide format'a dönüştürür ve ML için hazırlar.

**İşlevler:**
- ✅ Wide format dönüşümü (her tarih = 1 satır)
- ✅ Rolling return hesaplamaları (1w, 1m, 3m, 6m, 12m)
- ✅ Kategori bazlı ağırlıklı ortalama getiriler
- ✅ Kategori toplam büyüklük hesaplamaları
- ✅ Para akış (flow) analizleri

### 3. Yahoo Finance İndirme (`yahoo_finance_downloader.py`)

Global borsa endekslerini ve ETF'leri indirme.

**Kapsam:**
- 🇹🇷 Türkiye: XU100, XU030, XBANK #BIST100,30 ve Banka Endeksi
- 🇺🇸 ABD: SPY, QQQ, IWM #S&P500,Nasdaq,Russel 2000
- 🌍 Global: EFA, VWO, DJP, TLT #Amerikan Tahvilleri, Avrupa Endeksleri ve Gelişmekte Olan Ülkeler.
#Kapsam downloader classında defaul tickers altında bulunabilir. 

### 4. Yahoo Finance İşleme (`yahoo_finance_data_process.py`)

Yahoo Finance verisini wide format'a dönüştürür.

### 5. Provider Sistemi (`providers/tefas_provider.py`)

TEFAS API'lerini abstraction layer'ı ile sarmalamış provider class'ı.

## 📊 TEFAS Veri İndirme

### Test Modunda Kullanım
Not: 1 dk içinde fazla request atmak ip ban ile sonuçlanabiliyor. 4-6 paralelliği çok geçmemeye çalışın. Repair modda ise seri ya da max 2 worker deneyerek başlayın...

**10 fon ile test:**
```bash
# Seri mod (yavaş ama güvenli)
python tefas_download_data_merged.py --test --codes "PPN,AAK,TLE,IPV,TCD" --workers 1

# Paralel mod (hızlı)
python tefas_download_data_merged.py --test --codes "PPN,AAK,TLE,IPV,TCD" --workers 4
```

### Tam Veri İndirme

**Tüm fonlar (850+ fon):**
```bash
# 1 ay veri - paralel
python tefas_download_data_merged.py --full --months 1 --workers 4

# 1 yıl veri - paralel
python tefas_download_data_merged.py --full --years 1 --workers 4

# Özel tarih aralığı
python tefas_download_data_merged.py --full --start-date 2023-01-01 --end-date 2023-12-31 --workers 4
```

### Repair Modu (Eksik Veri Tamamlama)

```bash
# Mevcut dosyadaki eksikleri tespit et ve tamamla
python tefas_download_data_merged.py --repair --input data/tefas_full_2yrs.parquet --workers 4

# Seri repair (daha güvenli ama yavaş)
python tefas_download_data_merged.py --repair --input data/tefas_full_2yrs.parquet --workers 1
```

### Çıktı Dosyaları

- **Parquet**: `data/tefas_full_Xyrs.parquet` (sıkıştırılmış, hızlı)
- **Excel**: `data/tefas_full_Xyrs.xlsx` (insan okunabilir)
- **Log**: `log/tefas_download_YYYYMMDD_HHMMSS.log`

## ⚙️ Veri İşleme ve Analiz

### Wide Format Dönüşümü

**Long format'tan wide format'a:**
```bash
# Test verisi ile
python tefas_data_process.py --input data/test_10fon.parquet --output data/test_10fon_processed_wide.parquet

# Tam veri ile
python tefas_data_process.py --input data/tefas_full_2yrs.parquet --output data/tefas_full_2yrs_processed_wide.parquet
```

### Wide Format Çıktısı

Her satır bir tarihi temsil eder ve şu kolon tiplerini içerir:

#### Fon Bazlı Kolonlar:
```
fon_kodu_fiyat          # Fon birim fiyatı
fon_kodu_toplam_deger   # Fon toplam büyüklüğü (AUM)
fon_kodu_ret_1w         # 1 haftalık getiri
fon_kodu_ret_1m         # 1 aylık getiri
fon_kodu_ret_3m         # 3 aylık getiri
fon_kodu_ret_6m         # 6 aylık getiri
fon_kodu_ret_12m        # 12 aylık getiri
fon_kodu_fon_kodu       # Fon kodu referansı
```

#### Kategori Bazlı Kolonlar:
```
# Ağırlıklı ortalama getiriler
kategori_ret_1w         # Kategorinin ağırlıklı ortalama 1w getirisi
kategori_ret_1m         # Kategorinin ağırlıklı ortalama 1m getirisi
...

# Kategori toplam büyüklükleri
kategori_toplam_buyukluk  # Kategorinin toplam AUM'u

# Para akış analizleri
kategori_flow_1w        # 1 haftalık para giriş/çıkış oranı
kategori_flow_1m        # 1 aylık para giriş/çıkış oranı
...
```

#### Desteklenen Kategoriler:
- `borc_arac` - Borçlanma Araçları Şemsiye Fonu
- `degisken` - Değişken Şemsiye Fonu
- `eurobond` - Eurobond Şemsiye Fonu
- `hisse` - Hisse Senedi Şemsiye Fonu
- `para_piyasasi` - Para Piyasası Şemsiye Fonu
- `serbest` - Serbest Şemsiye Fonu
- `yabanci_hisse` - Yabancı Hisse Senedi Şemsiye Fonu
- ve diğerleri...

## 🌍 Yahoo Finance İndirme
Not: Tefas'a göre çok daha hızlı ve paralellik destekleyen bir api. Yüzlerce tickerın 5-10 senelik verileri saniyeler içinde indirilebildiği için kullanımı daha kolay. 

### Temel Kullanım

```bash
# Varsayılan ticker'lar ile 1 ay
python yahoo_finance_downloader.py --months 1

# Özel ticker'lar ile
python yahoo_finance_downloader.py --months 3 --tickers "SPY,QQQ,TSLA"

# Paralel indirme
python yahoo_finance_downloader.py --months 6 --workers 4
```

### Wide Format İşleme

```bash
# Yahoo Finance verisini wide format'a çevir
python yahoo_finance_data_process.py --input data/yahoo_finance_data.parquet --output data/yahoo_finance_processed_wide.parquet
```

## 🎯 Örnek Kullanım Senaryoları

### Senaryo 1: Hızlı Test ve Geliştirme

```bash
# 1. Küçük test verisi indir
python tefas_download_data_merged.py --test --codes "PPN,AAK,TLE,IPV,TCD" --workers 2

# 2. Wide format'a çevir
python tefas_data_process.py --input data/test_5fon.parquet --output data/test_processed_wide.parquet

# 3. Sonuçları Excel'de kontrol et
# data/test_processed_wide.xlsx dosyasını aç
```

### Senaryo 2: Tam Veri Toplama ve ML Pipeline

```bash
# 1. Tüm fonların 2 yıllık verisini indir (Production)
python tefas_download_data_merged.py --full --years 2 --workers 6

# 2. Wide format ML verisi oluştur
python tefas_data_process.py --input data/tefas_full_2yrs.parquet --output data/ml_ready_wide.parquet

# 3. Global benchmark'ları da ekle
python yahoo_finance_downloader.py --years 2 --workers 4
python yahoo_finance_data_process.py --input data/yahoo_finance_data.parquet --output data/global_benchmarks_wide.parquet
```

### Senaryo 3: Eksik Veri Tamamlama ve Güncelleme

```bash
# 1. Mevcut verideki eksikleri tespit et
python tefas_download_data_merged.py --repair --input data/tefas_full_2yrs.parquet --workers 4

# 2. Güncel veri ekle (son 1 ay)
python tefas_download_data_merged.py --full --months 1 --workers 6

# 3. Verileri birleştir ve yeniden işle
python tefas_data_process.py --input data/tefas_full_updated.parquet --output data/ml_ready_updated_wide.parquet
```

### Senaryo 4: Kategori Analizi

```bash
# 1. Tam veri seti hazırla
python tefas_download_data_merged.py --full --months 6 --workers 6
python tefas_data_process.py --input data/tefas_full_6months.parquet --output data/category_analysis_wide.parquet

# 2. Wide format'ta analiz yap
# - Kategori getiri performansları: degisken_ret_3m, hisse_ret_3m, para_piyasasi_ret_3m
# - Para akış trendleri: degisken_flow_1m, hisse_flow_1m
# - Kategori büyüklükleri: degisken_toplam_buyukluk, hisse_toplam_buyukluk
```

## 🔧 İleri Seviye Özellikler

### Chunk-Based İndirme

120+ günlük veri talepleri otomatik olarak 90 günlük chunk'lara bölünür:

```bash
# Bu komut otomatik olarak 4 chunk'a bölünür
python tefas_download_data_merged.py --full --months 12 --workers 6
```

### Rate Limiting

Sistem otomatik olarak rate limiting uygular:
- Request'ler arası 1-3 saniye jitter
- Hata durumunda exponential backoff
- TEFAS sunucularına zarar vermez

### Performance Optimizasyonu

850 fon için wide format işleme optimize edilmiştir:
- DataFrame fragmentation önleme
- Memory efficient processing
- Batch processing ile hız artışı

## 🐛 Troubleshooting

### Yaygın Sorunlar

**1. Rate Limiting Hatası:**
```bash
# Worker sayısını azalt
python tefas_download_data_merged.py --full --months 1 --workers 2  # 6 yerine 2
```

**2. Memory Sorunları (850 fon):**
```bash
# Smaller chunks kullan veya sistemi parçalara böl
python tefas_download_data_merged.py --test --codes "ilk_100_fon_listesi" --workers 4
```

**3. Network Timeouts:**
```bash
# Seri mod kullan
python tefas_download_data_merged.py --full --months 1 --workers 1
```

### Log Dosyaları

Tüm işlemler detaylı log tutar:
```
log/tefas_download_20240116_143022.log
log/yahoo_download_20240116_143055.log
```

### Veri Doğrulama

```bash
# Test verisi ile doğrula
python -c "
import pandas as pd
df = pd.read_parquet('data/test_processed_wide.parquet')
print('Boyut:', df.shape)
print('Tarih aralığı:', df['tarih'].min(), 'to', df['tarih'].max())
print('Fon sayısı:', len([col for col in df.columns if col.endswith('_fiyat')]))
print('Kategori sayısı:', len([col for col in df.columns if col.endswith('_ret_1w') and '_ret_' in col]))
"
```

## 📈 Data Schema

### Long Format (Ham Veri)
```
tarih           # datetime64[ns]
fiyat           # float64
toplam_deger    # float64  
fon_unvan       # string
fon_kodu        # string
fon_kategorisi  # string
```

### Wide Format (İşlenmiş Veri)
```
tarih                    # datetime64[ns] - Primary key
{fon}_fiyat             # float64 - Fon fiyatları
{fon}_toplam_deger      # float64 - Fon AUM'ları
{fon}_ret_{period}      # float64 - Fon getirileri
{fon}_fon_kodu          # string - Fon referansları
{kategori}_ret_{period} # float64 - Kategori ağırlıklı getiriler
{kategori}_toplam_buyukluk # float64 - Kategori toplam AUM
{kategori}_flow_{period}   # float64 - Kategori para akışları
```

## 🎯 Next Steps

Bu veri seti şu amaçlar için kullanılabilir:
- 📊 **Performans Analizi**: Fon ve kategori bazlı getiri analizleri
- 🤖 **Machine Learning**: Fon performans tahmin modelleri
- 💹 **Risk Analizi**: Volatilite ve korelasyon hesaplamaları
- 📈 **Portfolio Optimization**: Modern portfolio theory uygulamaları
- 🔄 **Factor Analysis**: Risk faktörlerinin fon getirileri üzerindeki etkisi

