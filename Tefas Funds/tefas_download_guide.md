# TEFAS Fon Veri İndirme Rehberi

Bu dosya, `tefas_download_data_merged.py` betiğini adım adım nasıl geliştirdiğimizi ve nasıl kullanacağınızı özetler. Mevcut sohbeti kaybetseniz bile yalnızca bu rehber aracılığıyla projeye kaldığınız yerden devam edebilirsiniz.

## 1. Provider Sınıfı (`providers/tefas_provider.py`)

Bu sınıf TEFAS API'si ile iletişimi sağlar. Fon bilgilerini çekme, performans verilerini alma gibi temel işlevleri içerir.

**Ana metodlar:**
- `get_fund_performance(fund_code, start_date, end_date)`: Belirli tarih aralığında fon performansını getirir
- `_get_takasbank_fund_list()`: Takasbank'tan güncel fon listesini alır

## 2. Ana İndirme Betiği (`tefas_download_data_merged.py`)

Bu betik hem seri hem paralel mod destekler ve repair özelliği içerir.

### Temel Kullanım

**Test Modu (5 fon):**
```bash
python tefas_download_data_merged.py --test --years 1 --workers 1
```

**Belirli Fonlar:**
```bash
python tefas_download_data_merged.py --test --codes DSP,PPN,PMP --years 1 --workers 4
```

**Tüm Fonlar:**
```bash
python tefas_download_data_merged.py --full --years 3 --workers 6
```

**Repair Mode (Eksik verileri tamamla):**
```bash
python tefas_download_data_merged.py --repair --input data/tefas_full_2yrs.parquet --workers 4
```

### Ana Özellikler

- ✅ **Seri/Paralel Mod**: `--workers 1` (seri) veya `--workers 4+` (paralel)
- ✅ **Repair Mode**: Eksik verileri otomatik tespit edip tamamlar
- ✅ **Graceful Shutdown**: Ctrl+C ile o ana kadarki sonuçları kaydeder
- ✅ **SSL Warnings**: Otomatik olarak engellenmiş
- ✅ **Progress Tracking**: Detaylı ilerleme takibi

## 3. Veri İşleme (`tefas_data_process.py`)

İndirilen ham verilere rolling returns ekler:

```bash
python tefas_data_process.py --input data/raw.parquet --output data/processed.parquet
```

**Eklenen sütunlar**: `ret_1w`, `ret_1m`, `ret_3m`, `ret_6m`, `ret_12m`

## 4. Yahoo Finance İntegrasyonu

**Veri İndirme:**
```bash
python yahoo_finance_downloader.py --tickers "ASELS.IS,SISE.IS" --years 2
```

**Veri İşleme:**
```bash
python yahoo_finance_data_process.py --input yahoo_finance_data.parquet --output processed_data.parquet
```

## 5. Codebase Yapısı

```
Tefas Funds/
├── tefas_download_data_merged.py     # ⭐ ANA BETIK (seri+paralel+repair)
├── tefas_data_process.py             # Rolling returns hesaplama
├── yahoo_finance_downloader.py       # Yahoo Finance data indirme
├── yahoo_finance_data_process.py     # Yahoo Finance data işleme
├── providers/
│   └── tefas_provider.py             # TEFAS API wrapper
├── data/                             # Parquet files
├── log/                              # Timestamped logs
└── requirements.txt                  # Python dependencies
```

## 6. Sık Kullanılan Komutlar

**Günlük repair (önerilen):**
```bash
python tefas_download_data_merged.py --repair --input data/tefas_full_2yrs.parquet --workers 1
```

**İlk kurulum (tüm fonlar 2 yıl):**
```bash
python tefas_download_data_merged.py --full --years 2 --workers 4
```

**Test (belirli fonlar):**
```bash
python tefas_download_data_merged.py --test --codes "DSP,PPN,BHI" --months 6 --workers 2
```

**Spesifik tarih aralığı:**
```bash
python tefas_download_data_merged.py --test --codes "PPN,TLE,IPV" --start-date 2025-01-01 --end-date 2025-07-01 --workers 4
```

## 7. Son Geliştirmeler ve Çözülen Sorunlar

### 🔧 Major Fixes (Temmuz 2025)

#### 1. TEFAS Provider Fund List Sorunu ✅
- **Sorun**: Takasbank Excel URL'si HTML döndürüyordu (`Content-Type: text/html`)
- **Çözüm**: TEFAS'ın kendi `BindComparisonFundReturns` API'sini kullandık
- **Sonuç**: 861 fon başarıyla yükleniyor

#### 2. Fon Kategori Sınıflandırma İyileştirmesi ✅  
- **Sorun**: "Yabancı" + "Borçlanma" kombinasyonu eksikti
- **Çözüm**: `_guess_category_from_name()` metoduna kombinasyon kuralı eklendi
- **Sonuç**: Eurobond fonları doğru kategorize ediliyor

#### 3. Tarih Aralığı Sorunu & Chunk-based İndirme ✅
- **Sorun**: 12 ay veri isteniyor, sadece ~2 ay geliyordu
- **Root Cause**: TEFAS API uzun tarih aralıklarında timeout yapıyor
- **Çözüm**: 120+ günlük aralıkları 90 günlük parçalara bölen sistem
- **Sonuç**: 1 yıl = 4 chunk × 90 gün, sıralı indirme + gecikme

#### 4. Repair Mode Kategori Düzeltmesi ✅
- **Sorun**: `'fon_adi': f'Repair - {fund_code}'` sahte isimler → yanlış kategoriler
- **Çözüm**: `_get_takasbank_fund_list()` ile gerçek fon isimleri eşleştirme
- **Sonuç**: Repair mode'da kategoriler doğru atanıyor

#### 5. Spesifik Tarih Aralığı Parametreleri ✅
- **Eklenen**: `--start-date YYYY-MM-DD` ve `--end-date YYYY-MM-DD` parametreleri
- **Çakışma Kontrolü**: `--start-date/--end-date` ile `--months/--years` aynı anda kullanılamaz
- **Örnekler**: 
  ```bash
  # 6 aylık spesifik aralık
  --start-date 2025-01-01 --end-date 2025-07-01
  
  # Başlangıç tarihi belirtili 
  --start-date 2024-01-01  # → bugüne kadar
  
  # Bitiş tarihi belirtili
  --end-date 2025-06-30    # → 2 yıl geriye
  ```

### 🛠️ Infrastructure İyileştirmeleri

#### Rate Limiting & Reliability
```python
# Chunk'lar arası delay
time.sleep(1)

# Request'ler arası jitter
base_delay = 0.5 + (attempt * 0.3)  
jitter = random.uniform(0.1, 0.3)
time.sleep(base_delay + jitter)
```

#### Auto-Directory Creation
- `data/` klasörü otomatik oluşturulur [[memory:3537521]]
- Mevcut içerik korunur

#### Graceful Shutdown (Ctrl+C)
- Seri ve paralel modlarda desteklenir
- O ana kadarki veriler kaydedilir
- Repair mode'da çalışan task'lar tamamlanır

#### Logging & Progress Tracking
```bash
# Chunk sistemi logları
[CHUNK 1] PPN: 2024-01-01 → 2024-03-31 (90 gün)
[CHUNK 2] PPN: 2024-04-01 → 2024-06-29 (90 gün)
[CHUNK TOTAL] PPN: 502 toplam kayıt (4 parça)
```

### 📊 Test Sonuçları

**10 Fon Kategorik Dağılım:**
- Değişken Şemsiye Fonu: 2 fon (IPB, TCD)
- Eurobond Şemsiye Fonu: 2 fon (TLE, IPV)  
- Hisse Senedi Şemsiye Fonu: 2 fon (AHI, IIH)
- Para Piyasası Şemsiye Fonu: 2 fon (PPN, PRD)
- Yabancı Hisse Senedi Şemsiye Fonu: 2 fon (AFA, YAY)

**Performance Metrics:**
- **Chunk sistemi**: 12 ay veri → 4 chunk × 90 gün
- **Rate limiting**: 0.5-1.5s gecikme + jitter
- **Repair mode**: Eksik veri tespit + gerçek fon isimleri

## 8. Debugging & Troubleshooting

### Yaygın Sorunlar

**1. SSL Certificate Warnings**
```python
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
```

**2. Connection Reset Errors**  
- Rate limiting aktif, retry mekanizması var
- Chunk sistemi timeout'ları azaltır

**3. Tarih Aralığı Sorunları**
- `--start-date`/`--end-date` parametrelerini kontrol et
- Debug loglarında tarih değerlerini gözlemle

### Test Araçları

**Repair Mode Testi için veri silme:**
```bash
python remove_last_records.py data/tefas_full_2yrs.parquet
# → Her fondan son 2 kaydı siler, repair testi için eksik veri oluşturur
``` 