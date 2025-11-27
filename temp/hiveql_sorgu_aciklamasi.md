# HiveQL Sorgusu Detayli Aciklamasi

Bu dokuman, vadeli mevduat hesaplari icin bakiye agirlikli bagil faiz hesaplamasi yapan HiveQL sorgusunun her bir CTE'sini aciklamaktadir.

---

## Genel Bakis

Sorgu, bir musterinin vadeli mevduat hesaplarini banka geneli ortalamalarla karsilastirarak "bagil" (relative) degerler hesaplar. Bu sayede musterinin banka ortalamasina gore ne kadar iyi/kotu faiz aldigi, ne kadar uzun/kisa vadeli yatirim yaptigi gibi metrikler elde edilir.

---

## 1. `base_hesaplar` CTE'si

**Amac:** Buyuk tablodan (`AI_INPUT.ODS_MEV_MEVDUAT_A`) temel filtreleri uygulayarak veri cekmek. `VADE_SURE` filtresi **OLMADAN** tum vadeli mevduat kayitlarini aliyor.

**Ne yapiyor:**
- Vade baslangic tarihinden "periyot tarihi" hesapliyor (haftanin gunune gore)
- Vade siniflandirmasi yapiyor (1 aya kadar, 3 aya kadar, vb.)
- Kanal siniflandirmasi yapiyor (SUBE, DIGITAL, DIGER)

### Periyot Tarihi Hesaplama Mantigi (+0 Yaklasimi)

Vade baslangic tarihini **ayni haftanin Cumasina** yuvarliyor. Boylece Cumartesi'den Cuma'ya kadar olan tum gunler ayni haftanin Cumasina eslesir:

| Vade Baslangic Gunu | Eklenen Gun | Sonuc |
|---------------------|-------------|-------|
| Cuma (Friday)       | +0          | Ayni Cuma |
| Persembe (Thursday) | +1          | Ayni Haftanin Cumasi |
| Carsamba (Wednesday)| +2          | Ayni Haftanin Cumasi |
| Sali (Tuesday)      | +3          | Ayni Haftanin Cumasi |
| Pazartesi (Monday)  | +4          | Ayni Haftanin Cumasi |
| Pazar (Sunday)      | +5          | Ayni Haftanin Cumasi |
| Cumartesi (Saturday)| +6          | Sonraki Cuma (yeni hafta) |

**Haftalik Gruplama Gorseli:**

```
Hafta 40 Periyodu: 3 Ekim (Cuma)
+-----------------------------------------------------------------------+
|  Cmt 27  |  Paz 28  |  Pzt 29  |  Sal 30  |  Car 1   |  Per 2   |  Cum 3   |
|   +6     |   +5     |   +4     |   +3     |   +2     |   +1     |   +0     |
|    |         |          |          |          |          |          |      |
+----+---------+----------+----------+----------+----------+----------+------+
     |                                                                 |
     +-------------------------> 3 Ekim <------------------------------+
                              (Hafta 40 Cumasi)
```

### Ornek Cikti:

| hesno | mus_no | gunsn_bak_tl | vade_sure | hesaplanan_faiz_oran | vade_period_tarihi | onceki_period_tarihi | vade_siniflandirma | kanal_siniflandirma | p |
|-------|--------|--------------|-----------|----------------------|--------------------|--------------------|-------------------|-------------------|-----------|
| H001  | 22572230 | 50,000 | 32 | 45.5 | 2025-11-14 | 2025-11-07 | 3_aya_kadar_vadeli | SUBE | 20251110 |
| H002  | 22572230 | 100,000 | 90 | 47.2 | 2025-11-14 | 2025-11-07 | 3_aya_kadar_vadeli | DIGITAL | 20251108 |
| H003  | 12345678 | 75,000 | 180 | 48.0 | 2025-11-14 | 2025-11-07 | 6_aya_kadar_vadeli | SUBE | 20251110 |
| H001  | 22572230 | 52,000 | 32 | 45.8 | 2025-11-14 | 2025-11-07 | 3_aya_kadar_vadeli | SUBE | 20251105 |
| H004  | 99999999 | 200,000 | 365 | 50.0 | 2025-11-07 | 2025-10-31 | 1_yildan_uzun_vadeli | DIGITAL | 20251103 |

---

## 2. `tekillestirilmis_kayitlar` CTE'si

**Amac:** Ayni hesabin ayni periyotta birden fazla kaydi varsa, en guncel ve en yuksek bakiyeli kaydi secmek.

**Ne yapiyor:**
- `PARTITION BY vade_period_tarihi, hesno` - Her periyot + hesap kombinasyonu icin grup olusturur
- `ORDER BY p DESC, gunsn_bak_tl DESC` - En yuksek P (en guncel tarih), sonra en yuksek bakiye
- `ROW_NUMBER()` - Her gruba 1'den baslayarak numara verir

### Gorsel Aciklama:

**Girdi (base_hesaplar):**

```
+--------+------------------+--------+--------------+------+
| hesno  | vade_period_tarihi| p      | gunsn_bak_tl | rn   |
+--------+------------------+--------+--------------+------+
| H001   | 2025-11-14       | 20251110| 50,000      | ?    |  <- Ayni hesap
| H001   | 2025-11-14       | 20251105| 52,000      | ?    |  <- Ayni hesap, ayni periyot
| H002   | 2025-11-14       | 20251108| 100,000     | ?    |
| H003   | 2025-11-14       | 20251110| 75,000      | ?    |
+--------+------------------+--------+--------------+------+
```

**ROW_NUMBER Hesaplamasi:**

```
Grup 1: hesno=H001, vade_period_tarihi=2025-11-14
  - p=20251110, bakiye=50,000  -> rn=1 (en guncel P)
  - p=20251105, bakiye=52,000  -> rn=2 (eski P, elenir)

Grup 2: hesno=H002, vade_period_tarihi=2025-11-14
  - p=20251108, bakiye=100,000 -> rn=1 (tek kayit)

Grup 3: hesno=H003, vade_period_tarihi=2025-11-14
  - p=20251110, bakiye=75,000  -> rn=1 (tek kayit)
```

**Cikti (rn=1 filtrelendikten sonra):**

```
+--------+------------------+--------+--------------+------+
| hesno  | vade_period_tarihi| p      | gunsn_bak_tl | rn   |
+--------+------------------+--------+--------------+------+
| H001   | 2025-11-14       | 20251110| 50,000      | 1    | <- Secildi
| H002   | 2025-11-14       | 20251108| 100,000     | 1    | <- Secildi
| H003   | 2025-11-14       | 20251110| 75,000      | 1    | <- Secildi
+--------+------------------+--------+--------------+------+
```

---

## 3. `BankaGeneliHaftalikView` CTE'si

**Amac:** Her periyot + vade sinifi + kanal kombinasyonu icin **banka geneli ortalama degerleri** hesaplamak.

**Ne yapiyor:**
- Bakiye agirlikli ortalama faiz orani
- Bakiye agirlikli ortalama FTF orani
- Bakiye agirlikli ortalama vade suresi
- Ortalama bakiye buyuklugu (toplam bakiye / hesap sayisi)

### Hesaplama Formulleri:

```
vbh_ortalama_faiz = SUM(bakiye * faiz) / SUM(bakiye)
vbh_ortalama_ftf = SUM(bakiye * ftf) / SUM(bakiye)
vbh_ortalama_vade_suresi = SUM(bakiye * vade_sure) / SUM(bakiye)
vbh_ortalama_bakiye_buyuklugu = SUM(bakiye) / COUNT(hesap)
```

### Gorsel Ornek:

**Girdi (tekillestirilmis_kayitlar, rn=1):**

```
+------------------+--------------------+-------------------+--------------+-------+----------+
| vade_period_tarihi| vade_siniflandirma | kanal_siniflandirma| gunsn_bak_tl | faiz  | vade_sure|
+------------------+--------------------+-------------------+--------------+-------+----------+
| 2025-11-14       | 3_aya_kadar_vadeli | SUBE              | 50,000       | 45.5  | 32       |
| 2025-11-14       | 3_aya_kadar_vadeli | SUBE              | 80,000       | 46.0  | 60       |
| 2025-11-14       | 3_aya_kadar_vadeli | SUBE              | 70,000       | 44.5  | 45       |
| 2025-11-14       | 3_aya_kadar_vadeli | DIGITAL           | 100,000      | 47.2  | 90       |
| 2025-11-14       | 6_aya_kadar_vadeli | SUBE              | 75,000       | 48.0  | 180      |
+------------------+--------------------+-------------------+--------------+-------+----------+
```

**Hesaplama (2025-11-14, 3_aya_kadar_vadeli, SUBE icin):**

```
Toplam Bakiye = 50,000 + 80,000 + 70,000 = 200,000

Bakiye Agirlikli Ortalama Faiz:
= (50,000*45.5 + 80,000*46.0 + 70,000*44.5) / 200,000
= (2,275,000 + 3,680,000 + 3,115,000) / 200,000
= 9,070,000 / 200,000
= 45.35

Bakiye Agirlikli Ortalama Vade Suresi:
= (50,000*32 + 80,000*60 + 70,000*45) / 200,000
= (1,600,000 + 4,800,000 + 3,150,000) / 200,000
= 9,550,000 / 200,000
= 47.75 gun

Ortalama Bakiye Buyuklugu:
= 200,000 / 3 = 66,666.67
```

**Cikti:**

```
+------------------+--------------------+-------------------+------------------+-----------------+----------------------+---------------------------+
| vade_period_tarihi| vade_siniflandirma | kanal_siniflandirma| vbh_toplam_bakiye| vbh_ortalama_faiz| vbh_ortalama_vade_suresi| vbh_ortalama_bakiye_buyuklugu|
+------------------+--------------------+-------------------+------------------+-----------------+----------------------+---------------------------+
| 2025-11-14       | 3_aya_kadar_vadeli | SUBE              | 200,000          | 45.35           | 47.75                | 66,666.67                 |
| 2025-11-14       | 3_aya_kadar_vadeli | DIGITAL           | 100,000          | 47.20           | 90.00                | 100,000.00                |
| 2025-11-14       | 6_aya_kadar_vadeli | SUBE              | 75,000           | 48.00           | 180.00               | 75,000.00                 |
+------------------+--------------------+-------------------+------------------+-----------------+----------------------+---------------------------+
```

---

## 4. `MusteriHesaplari` CTE'si

**Amac:** Belirli bir musterinin (`mus_no = 22572230`) hesaplarini `VADE_SURE BETWEEN 28 AND 1096` filtresiyle almak.

**Ne yapiyor:**
- `base_hesaplar` CTE'sinden musteri filtreliyor
- Vade suresi filtresini ekliyor (28-1096 gun arasi)
- Son 12 aylik kayitlari aliyor

**Ornek Cikti:**

```
+--------+----------+--------+--------------+-------+------------------+--------------------+--------------------+-------------------+
| p      | mus_no   | hesno  | gunsn_bak_tl | faiz  | vade_period_tarihi| onceki_period_tarihi| vade_siniflandirma | kanal_siniflandirma|
+--------+----------+--------+--------------+-------+------------------+--------------------+--------------------+-------------------+
| 20251110| 22572230 | H001   | 50,000       | 45.5  | 2025-11-14       | 2025-11-07         | 3_aya_kadar_vadeli | SUBE              |
| 20251108| 22572230 | H002   | 100,000      | 47.2  | 2025-11-14       | 2025-11-07         | 3_aya_kadar_vadeli | DIGITAL           |
+--------+----------+--------+--------------+-------+------------------+--------------------+--------------------+-------------------+
```

---

## 5. `BagilFaizHesaplama` CTE'si

**Amac:** Musteri hesaplarini **onceki periyottaki** banka geneli ortalamalarla karsilastirarak **bagil (relative) degerler** hesaplamak.

**Kritik Nokta:** JOIN, `onceki_period_tarihi` uzerinden yapiliyor! Yani musteri 40. haftada hesap actiysa, karsilastirma 39. haftanin banka ortalamalariyla yapiliyor.

### Bagil Hesaplama Mantigi:

```
Hafta 40'da acilan hesap --> Hafta 39 ortalamasiyla karsilastirilir

vade_period_tarihi = 3 Ekim (Hafta 40 Cumasi)
onceki_period_tarihi = 26 Eylul (Hafta 39 Cumasi) = vade_period_tarihi - 7 gun
```

### JOIN Mantigi:

```sql
MusteriHesaplari.onceki_period_tarihi = BankaGeneliHaftalikView.vade_period_tarihi
AND
MusteriHesaplari.vade_siniflandirma = BankaGeneliHaftalikView.vade_siniflandirma
AND
MusteriHesaplari.kanal_siniflandirma = BankaGeneliHaftalikView.kanal_siniflandirma
```

### Gorsel Ornek:

**MusteriHesaplari:**
```
+--------+--------------+-------+--------------------+-------------------+--------------------+
| hesno  | gunsn_bak_tl | faiz  | onceki_period_tarihi| vade_siniflandirma | kanal_siniflandirma|
+--------+--------------+-------+--------------------+--------------------+-------------------+
| H001   | 50,000       | 45.5  | 2025-11-07         | 3_aya_kadar_vadeli | SUBE              |
| H002   | 100,000      | 47.2  | 2025-11-07         | 3_aya_kadar_vadeli | DIGITAL           |
+--------+--------------+-------+--------------------+--------------------+-------------------+
```

**BankaGeneliHaftalikView (2025-11-07 periyodu):**
```
+------------------+--------------------+-------------------+-----------------+----------------------+
| vade_period_tarihi| vade_siniflandirma | kanal_siniflandirma| vbh_ortalama_faiz| vbh_ortalama_vade_suresi|
+------------------+--------------------+-------------------+-----------------+----------------------+
| 2025-11-07       | 3_aya_kadar_vadeli | SUBE              | 44.00           | 50.00                |
| 2025-11-07       | 3_aya_kadar_vadeli | DIGITAL           | 46.00           | 85.00                |
+------------------+--------------------+-------------------+-----------------+----------------------+
```

**Bagil Deger Hesaplamalari:**

```
H001 icin (SUBE kanali):
  bagil_faiz = 45.5 / 44.00 = 1.034  (banka ortalamasinin %103.4'u)
  
H002 icin (DIGITAL kanali):
  bagil_faiz = 47.2 / 46.00 = 1.026  (banka ortalamasinin %102.6'si)
```

**Cikti:**

```
+--------+--------------+-------+-----------------+------------+
| hesno  | gunsn_bak_tl | faiz  | vbh_ortalama_faiz| bagil_faiz |
+--------+--------------+-------+-----------------+------------+
| H001   | 50,000       | 45.5  | 44.00           | 1.034      |
| H002   | 100,000      | 47.2  | 46.00           | 1.026      |
+--------+--------------+-------+-----------------+------------+
```

---

## 6. Final SELECT

**Amac:** Musterinin tum hesaplarini **bakiye agirlikli** olarak birlestirip tek bir satir haline getirmek.

### Hesaplama:

```
Musteri: 22572230

H001: bakiye=50,000,  bagil_faiz=1.034
H002: bakiye=100,000, bagil_faiz=1.026

Bakiye Agirlikli Bagil Faiz:
= (50,000 * 1.034 + 100,000 * 1.026) / (50,000 + 100,000)
= (51,700 + 102,600) / 150,000
= 154,300 / 150,000
= 1.0287
```

**Final Cikti:**

```
+--------+----------+---------------------------+----------------------------------+-----------------------------------+------------------------------+---------------+---------------------------+
| p      | mus_no   | bakiye_agirlikli_bagil_faiz| bakiye_agirlikli_bagil_ftf_orani | bakiye_agirlikli_bagil_vade_suresi| bakiye_agirlikli_bagil_bakiye| toplam_bakiye | musteri_toplam_hesap_sayisi|
+--------+----------+---------------------------+----------------------------------+-----------------------------------+------------------------------+---------------+---------------------------+
| 20251110| 22572230| 1.0287                    | 1.0150                           | 0.9850                            | 1.2500                       | 150,000.00    | 2                         |
+--------+----------+---------------------------+----------------------------------+-----------------------------------+------------------------------+---------------+---------------------------+
```

---

## Ozet Akis Semasi

```
                    AI_INPUT.ODS_MEV_MEVDUAT_A
                              |
                              v
                    +-------------------+
                    |   base_hesaplar   |  <- Tum vadeler, tum musteriler (36 ay)
                    | (VADE_SURE yok)   |
                    +-------------------+
                         /         \
                        /           \
                       v             v
    +------------------------+    +------------------+
    | tekillestirilmis_      |    | MusteriHesaplari |
    | kayitlar (ROW_NUMBER)  |    | (Tek musteri,    |
    +------------------------+    | VADE_SURE filtreli|
               |                  | 12 ay)           |
               v                  +------------------+
    +------------------------+              |
    | BankaGeneliHaftalikView|              |
    | (Periyot + Vade +      |              |
    |  Kanal bazli           |              |
    |  ortalamalar)          |              |
    +------------------------+              |
                \                          /
                 \                        /
                  v                      v
              +---------------------------+
              |   BagilFaizHesaplama      |
              | (LEFT JOIN on            |
              |  onceki_period_tarihi)   |
              +---------------------------+
                          |
                          v
              +---------------------------+
              |      Final SELECT         |
              | (Bakiye agirlikli         |
              |  aggregation)             |
              +---------------------------+
```

---

## Optimizasyon Notu

Bu yaklasimla **buyuk tabloya sadece 1 kez** gidiliyor ve sonraki tum islemler CTE'ler uzerinden yapiliyor. Orijinal sorguda tablo 2 kez okunuyordu (biri banka geneli, biri musteri hesaplari icin).

---

*Dokuman Tarihi: Kasim 2025*
