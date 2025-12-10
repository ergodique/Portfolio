# Polymarket Wallet Trade Analyzer - Development Roadmap

## Proje Amacı

Polymarket API kullanarak belirli bir wallet adresinin trade gecmisini ceken, parquet dosyasina kaydeden ve analiz eden bir Python aracı geliştirmek.

**Hedef:** Verilen wallet adresinin son X aylık (veya günlük) tüm trade'lerini cekip parquet dosyasina kaydetmek. Bu parquet dosyasini tablo gibi kullanarak trader'in trade'lerini analiz etmek.

**Gerekli Veriler:**
- Timestamp
- Trader (wallet adresi)
- Tüm trade aktiviteleri
- Hangi markette yapıldığı
- PnL
- Market'in bahis sonlandığındaki outcome bilgisi

## Yapılan Geliştirmeler

### 1. Proje Yapısı
- `Polymarket_Analytics/` klasörü oluşturuldu
- `polymarket_client.py` - Polymarket API client (data-api ve gamma-api)
- `wallet_analyzer.py` - Ana CLI aracı
- `requirements.txt` - Bağımlılıklar (requests, pandas, pyarrow, aiohttp)
- `Data/` klasörü - Parquet dosyalarının kaydedildiği klasör
- `trade_analysis.ipynb` - Jupyter notebook (veri analizi için)

### 2. API Client Geliştirmeleri
- **Sync ve Async Mod Desteği:** `-p` parametresi ile paralel istek sayısı belirlenebiliyor
- **Duplicate Kontrolü:** Her trade için unique key oluşturuldu (`transaction_hash + condition_id + outcome + size + price + timestamp`)
- **Progress Callback:** Her batch'ten sonra partial data güncelleniyor (Ctrl+C ile kesme desteği)
- **Tarih Filtreleme:** `start_date` ve `end_date` parametreleri ile tarih aralığı filtresi

### 3. Performans Optimizasyonları
- **Rate Limit Kaldırıldı:** `time.sleep(0.2)` kaldırıldı
- **Page Size Artırıldı:** 500'den 1000'e çıkarıldı (ama API max 500 döndürüyor)
- **Async Parallel Fetching:** `aiohttp` ile paralel istek desteği eklendi
- **Market Info Opsiyonel:** `--fetch-market-info` flag'i ile market detayları opsiyonel hale getirildi

### 4. Kullanıcı Deneyimi İyileştirmeleri
- **CLI Parametreleri:**
  - `-d, --days`: Günlük veri çekme
  - `-m, --months`: Aylık veri çekme
  - `-p, --parallel`: Paralel istek sayısı (1=sync, 5-10 önerilen)
  - `-o, --output`: Çıktı dosyası yolu
  - `--fetch-market-info`: Market detaylarını çek (yavaşlatır)
- **Ctrl+C Desteği:** Kesme durumunda partial data `_partial.parquet` olarak kaydediliyor
- **Progress Göstergesi:** Her 2000 offset'te progress bilgisi

### 5. Veri Yapısı
Parquet dosyası şu kolonları içeriyor:
- `timestamp` - İşlem zamanı
- `trader` - Wallet adresi
- `side` - BUY/SELL
- `market_slug` - Market URL slug
- `event_slug` - Event URL slug
- `market_question` - Market sorusu
- `outcome` - YES/NO
- `outcome_index` - Outcome index
- `amount` - İşlem miktarı
- `price` - İşlem fiyatı
- `pnl` - Kar/Zarar
- `market_resolved` - Market sonuçlandı mı
- `winning_outcome` - Kazanan sonuç
- `condition_id` - Market condition ID
- `asset` - Token asset adresi
- `transaction_hash` - TX hash

## Karşılaşılan Sorunlar ve Çözümler

### Sorun 1: Duplicate Trade'ler
**Sorun:** Paralel fetch'te aynı trade'ler birden fazla kez ekleniyordu.
**Çözüm:** Unique key oluşturuldu: `transaction_hash + condition_id + outcome + size + price + timestamp`
**Durum:** ✅ Çözüldü

### Sorun 2: Offset Artışı Hatası
**Sorun:** `offset += len(data)` kullanılıyordu, bu yanlış offset artışına neden oluyordu.
**Çözüm:** `offset += limit` olarak değiştirildi (her zaman limit kadar artırılıyor)
**Durum:** ✅ Çözüldü

### Sorun 3: Tarih Filtreleme Çok Erken Duruyordu
**Sorun:** API verileri en yeni tarihten eskiye doğru geliyor, tarih kontrolü çok erken duruyordu.
**Çözüm:** Durma koşulu iyileştirildi - sadece sayfanın %80'inden fazlası `start_date`'den önceyse ve 5 sayfa üst üste böyleyse duruyor.
**Durum:** ✅ Çözüldü

### Sorun 4: API Offset Limitinin Keşfi
**Sorun:** Offset 1000'den sonra çalışmıyor, aynı verileri döndürüyor.
**Test Sonuçları:**
- offset=0, 500, 1000: Farklı veriler ✅
- offset=1500, 2000, 2500: Aynı veriler (offset=1000 ile aynı) ❌
**Durum:** ⚠️ API Limiti - Aşılamadı

### Sorun 5: Timestamp-based Pagination Denemesi
**Denenen:** `before`, `after`, `start_time`, `end_time`, `from`, `to` parametreleri
**Sonuç:** Data-api'de çalışmıyor, aynı verileri döndürüyor
**Durum:** ❌ Çalışmıyor

### Sorun 6: Zaman Penceresi Yaklaşımı
**Denenen:** Büyük tarih aralığını 6 saatlik pencerelere bölme
**Sorun:** API verileri en yeni tarihten eskiye doğru geliyor, eski pencereler için offset=0'dan başlamak işe yaramıyor
**Durum:** ❌ Çalışmıyor

## ✅ ÇÖZÜM: Hibrit Market-by-Market Yaklaşımı

### Sorun Detayı (Eski)
- **API Endpoint:** `https://data-api.polymarket.com/trades`
- **Offset Limiti:** 1000 (dokümantasyonda belirtilmiş)
- **Etki:** Sadece en son ~1500-2000 trade çekilebiliyordu

### Bulunan Çözüm: Hibrit Yaklaşım ✅
Offset limitini aşmak için yeni bir hibrit strateji uygulandı:

1. **Adım 1:** Standart offset-based yöntemle en yeni trade'leri çek (offset 0-1000)
2. **Adım 2:** `/positions` endpoint'inden kullanıcının tüm market'lerini (pozisyonlarını) al
3. **Adım 3:** Her market için ayrı ayrı trade'leri çek
4. **Adım 4:** Tüm sonuçları birleştir ve deduplicate et

### Neden Çalışıyor?
- `/positions` endpoint'i offset limitine takılmıyor
- Her market için ayrı `/trades` sorgusu offset limitini sıfırlıyor
- Standart yöntem kapatılmış (0 pozisyonlu) market'leri yakalar
- Market-by-market yöntem offset limiti aşan trade'leri yakalar

### Kullanım
```bash
# Hibrit yaklaşım ile (önerilen)
python wallet_analyzer.py <wallet_address> -d 7 --market-approach

# Standart yaklaşım ile (offset limitine takılır)
python wallet_analyzer.py <wallet_address> -d 7
```

### Test Sonuçları (Karşılaştırma)
```
Standart yaklaşım (eski):
  - 1498 trade
  - Tarih aralığı: ~3 saat (10:52 - 13:35)
  
Hibrit yaklaşım (yeni):
  - 1631 trade (+133 ek trade)
  - Tarih aralığı: ~22 saat (16:05 - 14:15)
```

## Mevcut Durum

### Çalışan Özellikler
- ✅ Sync mode ile trade çekme (offset 0-1000 arası)
- ✅ Duplicate kontrolü
- ✅ Tarih filtreleme
- ✅ Parquet dosyasına kaydetme
- ✅ Ctrl+C ile kesme ve partial data kaydetme
- ✅ Progress göstergesi
- ✅ **Hibrit market-by-market yaklaşım (--market-approach)**

### Sınırlamalar
- ⚠️ Hibrit yaklaşım biraz daha yavaş (her market için ayrı istek)
- ⚠️ Tamamen kapatılmış pozisyonlar `/positions`'da görünmeyebilir
- ⚠️ **API Rate Limit:** Bilinmiyor, test edilmedi

### Güncel Test Sonuçları
```
Wallet: 0x6031b6eed1c97e853c6e0f03ad3ce3529351f96d
Period: 7 days
Method: Hibrit (--market-approach)
Result: 1631 trade
Date Range: 2025-12-07 16:05:23 to 2025-12-08 14:15:49
Unique Markets: 35
```

## Gelecek İçin Öneriler

### 1. API Alternatifleri Araştırma
- [ ] Polymarket GraphQL API kontrolü
- [ ] Farklı endpoint'ler (ör. `/activity` vs `/trades`)
- [ ] Üçüncü taraf API'ler (PolyRouter, aiopolymarket)
- [ ] Polymarket Support ile iletişim (offset limit artırma talebi)

### 2. Alternatif Veri Kaynakları
- [ ] Blockchain'den direkt veri çekme (Polygon blockchain)
- [ ] The Graph gibi indexing servisleri
- [ ] Dune Analytics (ücretli API gerekli)

### 3. Mevcut Çözümü İyileştirme
- [ ] Daha küçük zaman aralıkları ile çoklu çalıştırma (manuel)
- [ ] Incremental update mekanizması (son çekilen trade'den devam)
- [ ] API rate limit testi ve optimizasyonu

### 4. Kod İyileştirmeleri
- [ ] Kullanılmayan pencere fonksiyonlarını temizleme
- [ ] Daha iyi hata yönetimi
- [ ] Logging mekanizması
- [ ] Unit testler

## Dosya Yapısı

```
Polymarket_Analytics/
├── polymarket_client.py      # API client
├── wallet_analyzer.py         # Ana CLI aracı
├── requirements.txt           # Bağımlılıklar
├── trade_analysis.ipynb       # Jupyter notebook (analiz)
├── test_api_pagination.py    # Test scriptleri
├── test_offset_deep.py
├── test_timestamp_pagination.py
├── test_timestamp_pagination_data_api.py
├── Data/                      # Parquet dosyaları
│   └── trades_*.parquet
└── ROADMAP.md                 # Bu dosya
```

## Kullanım Örnekleri

```bash
# 1 günlük veri çek (sync mode)
python wallet_analyzer.py 0x6031b6eed1c97e853c6e0f03ad3ce3529351f96d -d 1 -p 1

# 1 aylık veri çek (paralel mode)
python wallet_analyzer.py 0x6031b6eed1c97e853c6e0f03ad3ce3529351f96d -m 1 -p 10

# Market detayları ile çek
python wallet_analyzer.py 0x6031b6eed1c97e853c6e0f03ad3ce3529351f96d -d 1 -p 10 --fetch-market-info
```

## Önemli Notlar

1. **API Offset Limiti:** Polymarket API'nin `/trades` endpoint'i için offset limiti 1000. Bu limit aşılamıyor ve sadece en son ~1500-2000 trade çekilebiliyor.

2. **Veri Sıralaması:** API verileri en yeni tarihten eskiye doğru sıralı geliyor. Bu nedenle eski tarihlere ulaşmak için offset kullanmak gerekiyor, ama offset limiti var.

3. **Timestamp-based Pagination:** Data-api'de `before` ve `after` parametreleri çalışmıyor. CLOB API'de çalışıyor olabilir ama test edilmedi.

4. **Duplicate Kontrolü:** Her trade için unique key kullanılıyor: `transaction_hash + condition_id + outcome + size + price + timestamp`. Bu, aynı transaction içindeki farklı trade'leri ayırt ediyor.

## Sonraki Adımlar İçin Öneriler

1. **Polymarket API Dokümantasyonunu Detaylı İnceleme**
   - GraphQL API var mı?
   - Farklı endpoint'ler var mı?
   - Premium API tier'ları var mı?

2. **Blockchain'den Direkt Veri Çekme**
   - Polygon blockchain'den Polymarket contract'larını sorgulama
   - The Graph gibi indexing servisleri

3. **Incremental Update Mekanizması**
   - Son çekilen trade'in timestamp'ini kaydetme
   - Bir sonraki çalıştırmada o timestamp'ten devam etme
   - Bu şekilde zamanla tüm verileri toplama

4. **API Support ile İletişim**
   - Offset limit artırma talebi
   - Alternatif pagination yöntemleri sorma
   - Premium API seçenekleri

## Test Edilen API Parametreleri

### Çalışan Parametreler
- ✅ `user` - Wallet adresi
- ✅ `limit` - Sayfa boyutu (max 500)
- ✅ `offset` - Sayfa offset'i (max 1000)

### Çalışmayan Parametreler
- ❌ `before` - Timestamp (aynı verileri döndürüyor)
- ❌ `after` - Timestamp (aynı verileri döndürüyor)
- ❌ `start_time` - Unix timestamp (aynı verileri döndürüyor)
- ❌ `end_time` - Unix timestamp (aynı verileri döndürüyor)
- ❌ `from` - Unix timestamp (aynı verileri döndürüyor)
- ❌ `to` - Unix timestamp (aynı verileri döndürüyor)

## Kod Kalitesi Notları

- ✅ Linter hataları yok
- ✅ Type hints kullanılıyor
- ✅ Docstring'ler mevcut
- ✅ Error handling var
- ⚠️ Unit testler yok
- ⚠️ Logging mekanizması basit (print statements)

## Bağımlılıklar

```
requests>=2.28.0
pandas>=1.5.0
pyarrow>=14.0.0
aiohttp>=3.9.0
```

## Son Güncelleme

Tarih: 2025-12-08
Durum: API offset limiti nedeniyle sadece en son ~1500-2000 trade çekilebiliyor. Timestamp-based pagination ve zaman penceresi yaklaşımları denendi ama çalışmadı.

