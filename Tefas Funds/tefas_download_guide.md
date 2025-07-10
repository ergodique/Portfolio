# TEFAS Toplu Veri İndirme Scripti – Geliştirme Güncesi

Bu dosya, `tefas_download_data.py` betiğini adım adım nasıl geliştirdiğimizi ve nasıl kullanacağınızı özetler. Mevcut sohbeti kaybetseniz bile yalnızca bu rehber aracılığıyla projeye kaldığınız yerden devam edebilirsiniz.

---

## 1. Başlangıç Problemi
* **Hata**: `Expecting value: line 1 column 1 (char 0)` → TEFAS Mart 2024 itibarıyla CSRF token koruması ekledi.
* **İlk Çözüm**: `TefasProvider` içinde token alma/yönetme mekanizması.

## 2. Toplu İndirme Betiği (`tefas_download_data.py`)
1. **Oluşturuldu** – Tüm fonların geçmişini indir, Parquet’e yaz.
2. **Temel Özellikler**
   * Test modu / tam mod
   * Yıllar geriye parametresi (`--years`)
   * 60 günlük chunk’larla istek
   * 3 sn rate-limit gecikmesi
   * Başarısız chunk için 2 retry
   * Hata yönetimi (JSON parse, ConnectionReset)
   * Kategori belirleme (API + ad tahmini)
   * Çıktı: `data/tefas_[test|all]_data.parquet`

## 3. Windows Uyumluluğu
* Dinamik temp klasörü
* `openpyxl` zorunluluğu
* Emoji yerine `[OK]`, `[ERROR]` etiketleri

## 4. Fon Kodu/Kategori Sütunları
* `borsa_bulten_fiyat` kaldırıldı
* `fon_kodu` ve `fon_kategorisi` eklendi

## 5. Yeni Fon (≤1 Yıl) Desteği
* `fetch_fund_history` → tarih aralığında veri yoksa geriye doğru tarar (30g, 90g, 180g, 365g…)
* En eski tarihten itibaren tüm mevcut veri alınır (`allow_gaps=True`)

## 6. Test Modu İçin Özel Fon Listesi
* CLI parametresi: `--codes DSP,BOL,GTH`
* `TefasDataDownloader(codes_list=…)`
* Rastgele seçim kaldırıldı → Yalnızca belirtilen kodlar indirilir

## 7. Oturum Yenileme & Fonlar Arası Gecikme
* Her fon başlamadan **yeni session** (`self.provider = self._setup_provider()`)
* Fonlar arasında `time.sleep(4)`

## 8. Komut Satırı Kullanımı
```bash
# Sadece seçili fonlar (test)
python tefas_download_data.py --test --codes DSP,PPN,PMP --years 1

# Tüm fonlar (tüm geçmiş)
python tefas_download_data.py --full --years 3
```

## 9. Sık Karşılaşılan Hatalar & Çözümler
| Hata | Çözüm |
|------|-------|
| `Expecting value …` (JSON parse) | Betik otomatik session yeniler; gerekirse `--years` değerini azaltın |
| `ConnectionResetError 10054` | Oturum yenileme + 4 sn gecikme problemi çözer |
| `openpyxl not found` | `pip install openpyxl` |
| `Belirtilen fon kodları bulunamadı` | `--codes` listesini kontrol edin (büyük harf) |

## 10. Gelecek Adımlar
* Çok iş parçacıklı indirme ⇒ Daha hızlı ama TEFAS rate-limit’i test edilmeli
* Kategori bilgisini yerel önbelleğe alma ⇒ API çağrısı azalır

---

Bu rehber, betiğin mevcut **mihenk taşı** sürümünü belgelemektedir. Yeni geliştirmelerde buraya not ekleyerek ilerleyin. 

## 11. Veri İşleme Aşaması – Rolling Getiriler (Mihenk Taşı v2)

### 11.1 `tefas_data_process.py`
* **Amaç** : İndirilen ham Parquet dosyasına (test veya full) kaydırmalı getiri kolonları eklemek.
* **Yeni Kolonlar**  
  `ret_1w`, `ret_1m`, `ret_3m`, `ret_6m`, `ret_12m`  → sırasıyla 7, 30, 90, 180, 365 takvim günü getirisi.
* **Takvim Günü Mantığı**  
  1. Fon bazında kayıtlar tarih sırasına dizilir.  
  2. `asfreq('D')` ile eksik takvim günleri eklenir.  
  3. `ffill()` → fiyat son bilinen değerle ileriye doldurulur.  
  4. Getiri formülü = `fiyat / fiyat.shift(N) - 1`  
  5. Sonuç orijinal tarihlere geri eşlenir (`reindex`).
* **Kullanım**
```bash
python tefas_data_process.py \
  --input data/tefas_test_data.parquet \
  --output data/tefas_test_data_processed.parquet
```
* **Çıktı** : Tüm kolonlar Parquet’te korunur (pandas `to_parquet`).

### 11.2 Sütun Kontrolü
Log çıktısında:
```
Son sütun listesi: [..., 'ret_1w', 'ret_1m', 'ret_3m', 'ret_6m', 'ret_12m']
```
Parquet okuyarak doğrulayabilirsiniz:
```python
import pandas as pd
df = pd.read_parquet('data/tefas_test_data_processed.parquet')
print(df.columns)
```

### 11.3 Önemli Kod Parçası
```40:46:Tefas Funds/tefas_data_process.py
s_daily = (
    g.set_index("tarih")["fiyat"].asfreq("D").ffill()
)
```
Bu satırlar eksik günleri takvim gününe göre doldurarak doğru getiri hesaplamasını sağlar.

---

Bu rehber **indir → işleme** hattının son durumunu özetler. Gelecekteki geliştirmeleri yine buraya ekleyin. 