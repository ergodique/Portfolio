# HiveQL Query Detailed Explanation

This document explains each CTE of the HiveQL query that calculates balance-weighted relative interest rates for time deposit accounts.

---

## Overview

The query compares a customer's time deposit accounts with bank-wide averages to calculate "relative" values. This way, metrics such as how much better/worse interest rate the customer receives compared to the bank average, or how long/short-term their investments are, can be obtained.

---

## 1. `base_hesaplar` CTE (Base Accounts)

**Purpose:** To fetch data from the large table (`AI_INPUT.ODS_MEV_MEVDUAT_A`) by applying basic filters. It retrieves all time deposit records **WITHOUT** the `VADE_SURE` (maturity duration) filter.

**What it does:**
- Calculates "period date" from the maturity start date (based on day of the week)
- Performs maturity classification (up to 1 month, up to 3 months, etc.)
- Performs channel classification (BRANCH, DIGITAL, OTHER)

### Period Date Calculation Logic (+0 Approach)

Rounds the maturity start date to **the same week's Friday**. This way, all days from Saturday to Friday are mapped to that week's Friday:

| Maturity Start Day | Days Added | Result |
|--------------------|------------|--------|
| Friday             | +0         | Same Friday |
| Thursday           | +1         | Same Week's Friday |
| Wednesday          | +2         | Same Week's Friday |
| Tuesday            | +3         | Same Week's Friday |
| Monday             | +4         | Same Week's Friday |
| Sunday             | +5         | Same Week's Friday |
| Saturday           | +6         | Next Friday (new week) |

**Weekly Grouping Visualization:**

```
Week 40 Period: October 3 (Friday)
+-----------------------------------------------------------------------+
|  Sat 27  |  Sun 28  |  Mon 29  |  Tue 30  |  Wed 1   |  Thu 2   |  Fri 3   |
|   +6     |   +5     |   +4     |   +3     |   +2     |   +1     |   +0     |
|    |         |          |          |          |          |          |      |
+----+---------+----------+----------+----------+----------+----------+------+
     |                                                                 |
     +-------------------------> Oct 3 <-------------------------------+
                              (Week 40 Friday)
```

### Sample Output:

| hesno | mus_no | gunsn_bak_tl | vade_sure | hesaplanan_faiz_oran | vade_period_tarihi | onceki_period_tarihi | vade_siniflandirma | kanal_siniflandirma | p |
|-------|--------|--------------|-----------|----------------------|--------------------|--------------------|-------------------|-------------------|-----------|
| H001  | 22572230 | 50,000 | 32 | 45.5 | 2025-11-14 | 2025-11-07 | 3_aya_kadar_vadeli | SUBE | 20251110 |
| H002  | 22572230 | 100,000 | 90 | 47.2 | 2025-11-14 | 2025-11-07 | 3_aya_kadar_vadeli | DIGITAL | 20251108 |
| H003  | 12345678 | 75,000 | 180 | 48.0 | 2025-11-14 | 2025-11-07 | 6_aya_kadar_vadeli | SUBE | 20251110 |
| H001  | 22572230 | 52,000 | 32 | 45.8 | 2025-11-14 | 2025-11-07 | 3_aya_kadar_vadeli | SUBE | 20251105 |
| H004  | 99999999 | 200,000 | 365 | 50.0 | 2025-11-07 | 2025-10-31 | 1_yildan_uzun_vadeli | DIGITAL | 20251103 |

**Column Translations:**
- hesno = account_number
- mus_no = customer_number
- gunsn_bak_tl = daily_balance_tl
- vade_sure = maturity_duration
- hesaplanan_faiz_oran = calculated_interest_rate
- vade_period_tarihi = maturity_period_date
- onceki_period_tarihi = previous_period_date
- vade_siniflandirma = maturity_classification
- kanal_siniflandirma = channel_classification
- p = partition_date

---

## 2. `tekillestirilmis_kayitlar` CTE (Deduplicated Records)

**Purpose:** If the same account has multiple records in the same period, select the most recent and highest balance record.

**What it does:**
- `PARTITION BY vade_period_tarihi, hesno` - Creates groups for each period + account combination
- `ORDER BY p DESC, gunsn_bak_tl DESC` - Highest P (most recent date), then highest balance
- `ROW_NUMBER()` - Assigns numbers starting from 1 to each group

### Visual Explanation:

**Input (base_hesaplar):**

```
+--------+------------------+--------+--------------+------+
| hesno  | vade_period_tarihi| p      | gunsn_bak_tl | rn   |
+--------+------------------+--------+--------------+------+
| H001   | 2025-11-14       | 20251110| 50,000      | ?    |  <- Same account
| H001   | 2025-11-14       | 20251105| 52,000      | ?    |  <- Same account, same period
| H002   | 2025-11-14       | 20251108| 100,000     | ?    |
| H003   | 2025-11-14       | 20251110| 75,000      | ?    |
+--------+------------------+--------+--------------+------+
```

**ROW_NUMBER Calculation:**

```
Group 1: hesno=H001, vade_period_tarihi=2025-11-14
  - p=20251110, balance=50,000  -> rn=1 (most recent P)
  - p=20251105, balance=52,000  -> rn=2 (older P, eliminated)

Group 2: hesno=H002, vade_period_tarihi=2025-11-14
  - p=20251108, balance=100,000 -> rn=1 (single record)

Group 3: hesno=H003, vade_period_tarihi=2025-11-14
  - p=20251110, balance=75,000  -> rn=1 (single record)
```

**Output (after filtering rn=1):**

```
+--------+------------------+--------+--------------+------+
| hesno  | vade_period_tarihi| p      | gunsn_bak_tl | rn   |
+--------+------------------+--------+--------------+------+
| H001   | 2025-11-14       | 20251110| 50,000      | 1    | <- Selected
| H002   | 2025-11-14       | 20251108| 100,000     | 1    | <- Selected
| H003   | 2025-11-14       | 20251110| 75,000      | 1    | <- Selected
+--------+------------------+--------+--------------+------+
```

---

## 3. `BankaGeneliHaftalikView` CTE (Bank-Wide Weekly View)

**Purpose:** Calculate **bank-wide average values** for each period + maturity class + channel combination.

**What it does:**
- Balance-weighted average interest rate
- Balance-weighted average FTF (Forward Transfer Factor) rate
- Balance-weighted average maturity duration
- Average balance size (total balance / number of accounts)

### Calculation Formulas:

```
vbh_ortalama_faiz = SUM(balance * interest_rate) / SUM(balance)
vbh_ortalama_ftf = SUM(balance * ftf_rate) / SUM(balance)
vbh_ortalama_vade_suresi = SUM(balance * maturity_duration) / SUM(balance)
vbh_ortalama_bakiye_buyuklugu = SUM(balance) / COUNT(accounts)
```

### Visual Example:

**Input (tekillestirilmis_kayitlar, rn=1):**

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

**Calculation (for 2025-11-14, 3_aya_kadar_vadeli, SUBE):**

```
Total Balance = 50,000 + 80,000 + 70,000 = 200,000

Balance-Weighted Average Interest Rate:
= (50,000*45.5 + 80,000*46.0 + 70,000*44.5) / 200,000
= (2,275,000 + 3,680,000 + 3,115,000) / 200,000
= 9,070,000 / 200,000
= 45.35

Balance-Weighted Average Maturity Duration:
= (50,000*32 + 80,000*60 + 70,000*45) / 200,000
= (1,600,000 + 4,800,000 + 3,150,000) / 200,000
= 9,550,000 / 200,000
= 47.75 days

Average Balance Size:
= 200,000 / 3 = 66,666.67
```

**Output:**

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

## 4. `MusteriHesaplari` CTE (Customer Accounts)

**Purpose:** Get a specific customer's (`mus_no = 22572230`) accounts with the `VADE_SURE BETWEEN 28 AND 1096` filter.

**What it does:**
- Filters customer from `base_hesaplar` CTE
- Adds maturity duration filter (between 28-1096 days)
- Gets records from the last 12 months

**Sample Output:**

```
+--------+----------+--------+--------------+-------+------------------+--------------------+--------------------+-------------------+
| p      | mus_no   | hesno  | gunsn_bak_tl | faiz  | vade_period_tarihi| onceki_period_tarihi| vade_siniflandirma | kanal_siniflandirma|
+--------+----------+--------+--------------+-------+------------------+--------------------+--------------------+-------------------+
| 20251110| 22572230 | H001   | 50,000       | 45.5  | 2025-11-14       | 2025-11-07         | 3_aya_kadar_vadeli | SUBE              |
| 20251108| 22572230 | H002   | 100,000      | 47.2  | 2025-11-14       | 2025-11-07         | 3_aya_kadar_vadeli | DIGITAL           |
+--------+----------+--------+--------------+-------+------------------+--------------------+--------------------+-------------------+
```

---

## 5. `BagilFaizHesaplama` CTE (Relative Interest Calculation)

**Purpose:** Calculate **relative values** by comparing customer accounts with bank-wide averages from the **previous period**.

**Critical Point:** The JOIN is performed on `onceki_period_tarihi` (previous period date)! So if a customer opened an account in week 40, the comparison is made with bank averages from week 39.

### Relative Calculation Logic:

```
Account opened in Week 40 --> Compared with Week 39 averages

vade_period_tarihi = October 3 (Week 40 Friday)
onceki_period_tarihi = September 26 (Week 39 Friday) = vade_period_tarihi - 7 days
```

### JOIN Logic:

```sql
MusteriHesaplari.onceki_period_tarihi = BankaGeneliHaftalikView.vade_period_tarihi
AND
MusteriHesaplari.vade_siniflandirma = BankaGeneliHaftalikView.vade_siniflandirma
AND
MusteriHesaplari.kanal_siniflandirma = BankaGeneliHaftalikView.kanal_siniflandirma
```

### Visual Example:

**MusteriHesaplari (Customer Accounts):**
```
+--------+--------------+-------+--------------------+-------------------+--------------------+
| hesno  | gunsn_bak_tl | faiz  | onceki_period_tarihi| vade_siniflandirma | kanal_siniflandirma|
+--------+--------------+-------+--------------------+--------------------+-------------------+
| H001   | 50,000       | 45.5  | 2025-11-07         | 3_aya_kadar_vadeli | SUBE              |
| H002   | 100,000      | 47.2  | 2025-11-07         | 3_aya_kadar_vadeli | DIGITAL           |
+--------+--------------+-------+--------------------+--------------------+-------------------+
```

**BankaGeneliHaftalikView (2025-11-07 period):**
```
+------------------+--------------------+-------------------+-----------------+----------------------+
| vade_period_tarihi| vade_siniflandirma | kanal_siniflandirma| vbh_ortalama_faiz| vbh_ortalama_vade_suresi|
+------------------+--------------------+-------------------+-----------------+----------------------+
| 2025-11-07       | 3_aya_kadar_vadeli | SUBE              | 44.00           | 50.00                |
| 2025-11-07       | 3_aya_kadar_vadeli | DIGITAL           | 46.00           | 85.00                |
+------------------+--------------------+-------------------+-----------------+----------------------+
```

**Relative Value Calculations:**

```
For H001 (BRANCH channel):
  relative_interest = 45.5 / 44.00 = 1.034  (103.4% of bank average)
  
For H002 (DIGITAL channel):
  relative_interest = 47.2 / 46.00 = 1.026  (102.6% of bank average)
```

**Output:**

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

**Purpose:** Combine all customer accounts in a **balance-weighted** manner into a single row.

### Calculation:

```
Customer: 22572230

H001: balance=50,000,  relative_interest=1.034
H002: balance=100,000, relative_interest=1.026

Balance-Weighted Relative Interest:
= (50,000 * 1.034 + 100,000 * 1.026) / (50,000 + 100,000)
= (51,700 + 102,600) / 150,000
= 154,300 / 150,000
= 1.0287
```

**Final Output:**

```
+--------+----------+---------------------------+----------------------------------+-----------------------------------+------------------------------+---------------+---------------------------+
| p      | mus_no   | bakiye_agirlikli_bagil_faiz| bakiye_agirlikli_bagil_ftf_orani | bakiye_agirlikli_bagil_vade_suresi| bakiye_agirlikli_bagil_bakiye| toplam_bakiye | musteri_toplam_hesap_sayisi|
+--------+----------+---------------------------+----------------------------------+-----------------------------------+------------------------------+---------------+---------------------------+
| 20251110| 22572230| 1.0287                    | 1.0150                           | 0.9850                            | 1.2500                       | 150,000.00    | 2                         |
+--------+----------+---------------------------+----------------------------------+-----------------------------------+------------------------------+---------------+---------------------------+
```

**Output Column Translations:**
- bakiye_agirlikli_bagil_faiz = balance_weighted_relative_interest
- bakiye_agirlikli_bagil_ftf_orani = balance_weighted_relative_ftf_rate
- bakiye_agirlikli_bagil_vade_suresi = balance_weighted_relative_maturity_duration
- bakiye_agirlikli_bagil_bakiye = balance_weighted_relative_balance
- toplam_bakiye = total_balance
- musteri_toplam_hesap_sayisi = customer_total_account_count

---

## Summary Flow Diagram

```
                    AI_INPUT.ODS_MEV_MEVDUAT_A
                              |
                              v
                    +-------------------+
                    |   base_hesaplar   |  <- All maturities, all customers (36 months)
                    | (no VADE_SURE)    |
                    +-------------------+
                         /         \
                        /           \
                       v             v
    +------------------------+    +------------------+
    | tekillestirilmis_      |    | MusteriHesaplari |
    | kayitlar (ROW_NUMBER)  |    | (Single customer,|
    +------------------------+    | VADE_SURE filtered|
               |                  | 12 months)       |
               v                  +------------------+
    +------------------------+              |
    | BankaGeneliHaftalikView|              |
    | (Period + Maturity +   |              |
    |  Channel based         |              |
    |  averages)             |              |
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
              | (Balance-weighted         |
              |  aggregation)             |
              +---------------------------+
```

---

## Optimization Note

With this approach, **the large table is accessed only once** and all subsequent operations are performed through CTEs. In the original query, the table was read twice (once for bank-wide averages, once for customer accounts).

---

*Document Date: November 2025*
