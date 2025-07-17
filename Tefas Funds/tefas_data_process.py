import argparse
from pathlib import Path
import pandas as pd
import pyarrow.parquet as pq
import pyarrow as pa
import numpy as np
import logging

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

# Fon kategorisi kolon isimleri mapping
CATEGORY_MAPPING = {
    "Borçlanma Araçları Şemsiye Fonu": "borc_arac",
    "Değişken Şemsiye Fonu": "degisken",
    "Diğer Şemsiye Fonu": "diger",
    "Eurobond Şemsiye Fonu": "eurobond",
    "Fon Sepeti Şemsiye Fonu": "fon_sepet",
    "Hisse Senedi Şemsiye Fonu": "hisse",
    "Katılım Şemsiye Fonu": "katilim",
    "Kıymetli Madenler Şemsiye Fonu": "kiymetli_maden",
    "Para Piyasası Şemsiye Fonu": "para_piyasasi",
    "Serbest Şemsiye Fonu": "serbest",
    "Yabancı Hisse Senedi Şemsiye Fonu": "yabanci_hisse"
}

def remove_unwanted_columns(df: pd.DataFrame) -> pd.DataFrame:
    """Yatırımcı sayısı ve tedavüldeki pay sayısı kolonlarını çıkarır."""
    columns_to_remove = ["yatirimci_sayisi", "tedavuldeki_pay_sayisi"]
    existing_columns = [col for col in columns_to_remove if col in df.columns]
    
    if existing_columns:
        logger.info("Çıkarılan kolonlar: %s", existing_columns)
        df = df.drop(columns=existing_columns)
    else:
        logger.info("Çıkarılacak kolon bulunamadı: %s", columns_to_remove)
    
    return df

def convert_to_wide_format(df: pd.DataFrame) -> tuple[pd.DataFrame, dict]:
    """Long format'tan wide format'a dönüştürür ve fon kategorileri mapping'ini döner."""
    logger.info("Wide format'a dönüştürme başlıyor...")
    
    # Fon kodu ve kategori mapping'ini oluştur
    fund_categories = df.groupby('fon_kodu')['fon_kategorisi'].first().to_dict()
    logger.info("Toplam fon sayısı: %d", len(fund_categories))
    
    # Pivot işlemi için gerekli kolonları seç
    pivot_columns = ['fiyat', 'toplam_deger']
    
    wide_dfs = []
    for col in pivot_columns:
        pivoted = df.pivot(index='tarih', columns='fon_kodu', values=col)
        # Kolon isimlerini değiştir: fon_kodu_kolon_adı
        pivoted.columns = [f"{fund_code.lower()}_{col}" for fund_code in pivoted.columns]
        wide_dfs.append(pivoted)
    
    # Tüm pivot tabloları birleştir
    wide_df = pd.concat(wide_dfs, axis=1)
    wide_df.reset_index(inplace=True)
    
    # Fon kodu kolonlarını ekle (her fon için sabit fon_kodu kolonu)
    logger.info("Fon kodu kolonları ekleniyor...")
    for fund_code in fund_categories.keys():
        fund_lower = fund_code.lower()
        wide_df[f"{fund_lower}_fon_kodu"] = fund_code
    
    logger.info("Wide format tamamlandı. Boyut: %s", wide_df.shape)
    logger.info("Wide format kolon sayısı: %d", len(wide_df.columns))
    
    # DataFrame'i defragmente et
    wide_df = wide_df.copy()
    logger.info("DataFrame defragmentation tamamlandı")
    
    return wide_df, fund_categories

def compute_rolling_returns_wide(df: pd.DataFrame) -> pd.DataFrame:
    """Wide format'ta fon bazında kaydırmalı getirileri hesaplar."""
    logger.info("Wide format'ta getiri hesaplamaları başlıyor...")
    
    df = df.sort_values('tarih').copy()
    
    # Fiyat kolonlarını bul
    price_columns = [col for col in df.columns if col.endswith('_fiyat')]
    logger.info("Fiyat kolonları bulundu: %d adet", len(price_columns))
    
    # Tüm getiri kolonlarını tutacak liste
    return_dataframes = []
    
    # Her fiyat kolonu için getiri hesapla
    for i, price_col in enumerate(price_columns):
        if i % 50 == 0:
            logger.info("İşlenen fon: %d/%d", i, len(price_columns))
        
        fund_code = price_col.replace('_fiyat', '')
        
        # Günlük frekansa geçiş (eksik günleri forward fill)
        price_series = df.set_index('tarih')[price_col].asfreq('D').ffill()
        
        # Bu fon için tüm getiri kolonlarını hesapla
        fund_returns = {}
        for ret_col, days in WINDOWS.items():
            shifted_prices = price_series.shift(days)
            returns = price_series / shifted_prices - 1
            
            # Orijinal tarihlere geri map et
            fund_returns[f"{fund_code}_{ret_col}"] = returns.reindex(df['tarih']).values
        
        # Bu fonun getirilerini DataFrame'e çevir
        fund_df = pd.DataFrame(fund_returns, index=df.index)
        return_dataframes.append(fund_df)
    
    logger.info("Tüm getiriler hesaplandı, birleştiriliyor...")
    
    # Tüm getiri kolonlarını tek seferde birleştir
    if return_dataframes:
        all_returns_df = pd.concat(return_dataframes, axis=1)
        result_df = pd.concat([df, all_returns_df], axis=1)
    else:
        result_df = df
    
    logger.info("Wide format getiri hesaplamaları tamamlandı")
    return result_df

def compute_category_weighted_returns_wide(df: pd.DataFrame, fund_categories: dict) -> pd.DataFrame:
    """Wide format'ta kategori bazında ağırlıklı ortalama getirileri hesaplar."""
    logger.info("Wide format'ta kategori ağırlıklı ortalama hesaplamaları başlıyor...")
    
    # Return kolonlarını bul
    return_columns = [col for col in df.columns if any(col.endswith(f"_{ret}") for ret in WINDOWS.keys())]
    
    if not return_columns:
        logger.warning("Return kolonları bulunamadı")
        return df
    
    # Tüm kategori kolonlarını tutacak dictionary
    category_columns = {}
    
    # Her kategori için ağırlıklı ortalama hesapla
    for category_full, category_short in CATEGORY_MAPPING.items():
        # Bu kategorideki fonları bul
        category_funds = [fund for fund, cat in fund_categories.items() if cat == category_full]
        
        if not category_funds:
            logger.info("Kategori '%s' için fon bulunamadı", category_short)
            continue
        
        logger.info("Kategori '%s' - %d fon işleniyor", category_short, len(category_funds))
        
        # Her getiri penceresi için ağırlıklı ortalama hesapla
        for ret_period in WINDOWS.keys():
            weights_cols = []
            returns_cols = []
            
            for fund in category_funds:
                fund_lower = fund.lower()
                weight_col = f"{fund_lower}_toplam_deger"
                return_col = f"{fund_lower}_{ret_period}"
                
                if weight_col in df.columns and return_col in df.columns:
                    weights_cols.append(weight_col)
                    returns_cols.append(return_col)
            
            if weights_cols and returns_cols:
                # Ağırlıklı ortalama hesapla: Σ(weight * return) / Σ(weight)
                numerator = 0
                denominator = 0
                
                for weight_col, return_col in zip(weights_cols, returns_cols):
                    # NaN değerleri göz ardı et
                    valid_mask = pd.notna(df[weight_col]) & pd.notna(df[return_col])
                    
                    if valid_mask.any():
                        numerator += (df[weight_col] * df[return_col]).fillna(0)
                        denominator += df[weight_col].fillna(0)
                
                # Sıfır olmayan denominator değerleri için ağırlıklı ortalama hesapla
                weighted_avg = numerator / denominator
                category_columns[f"{category_short}_{ret_period}"] = weighted_avg
            else:
                # Bu kategori için veri yok, NaN kolonunu ekle
                category_columns[f"{category_short}_{ret_period}"] = pd.Series([pd.NA] * len(df), index=df.index)
    
    logger.info("Kategori kolonları birleştiriliyor...")
    
    # Kategori kolonlarını tek seferde birleştir
    if category_columns:
        category_df = pd.DataFrame(category_columns, index=df.index)
        result_df = pd.concat([df, category_df], axis=1)
    else:
        result_df = df
    
    logger.info("Kategori ağırlıklı ortalama hesaplamaları tamamlandı")
    return result_df

def compute_category_total_size(df: pd.DataFrame, fund_categories: dict) -> pd.DataFrame:
    """Wide format'ta kategori bazında toplam büyüklük hesaplar."""
    logger.info("Kategori toplam büyüklük hesaplamaları başlıyor...")
    
    # Tüm kategori büyüklük kolonlarını tutacak dictionary
    size_columns = {}
    
    # Her kategori için toplam büyüklük hesapla
    for category_full, category_short in CATEGORY_MAPPING.items():
        # Bu kategorideki fonları bul
        category_funds = [fund for fund, cat in fund_categories.items() if cat == category_full]
        
        if not category_funds:
            logger.info("Kategori '%s' için fon bulunamadı", category_short)
            size_columns[f"{category_short}_toplam_buyukluk"] = pd.Series([pd.NA] * len(df), index=df.index)
            continue
        
        logger.info("Kategori '%s' - %d fon toplam büyüklük hesaplanıyor", category_short, len(category_funds))
        
        # Bu kategorideki fonların toplam_deger kolonlarını topla
        total_size = 0
        valid_funds_found = False
        
        for fund in category_funds:
            fund_lower = fund.lower()
            size_col = f"{fund_lower}_toplam_deger"
            
            if size_col in df.columns:
                fund_size = df[size_col].fillna(0)
                total_size += fund_size
                valid_funds_found = True
        
        if valid_funds_found:
            size_columns[f"{category_short}_toplam_buyukluk"] = total_size
        else:
            size_columns[f"{category_short}_toplam_buyukluk"] = pd.Series([pd.NA] * len(df), index=df.index)
    
    logger.info("Kategori büyüklük kolonları birleştiriliyor...")
    
    # Kategori büyüklük kolonlarını tek seferde birleştir
    if size_columns:
        size_df = pd.DataFrame(size_columns, index=df.index)
        result_df = pd.concat([df, size_df], axis=1)
    else:
        result_df = df
    
    logger.info("Kategori toplam büyüklük hesaplamaları tamamlandı")
    return result_df

def compute_category_flows(df: pd.DataFrame, fund_categories: dict) -> pd.DataFrame:
    """Wide format'ta kategori bazında para akış yüzdelerini hesaplar."""
    logger.info("Kategori para akış hesaplamaları başlıyor...")
    
    df = df.sort_values('tarih').copy()
    
    # Tüm flow kolonlarını tutacak dictionary
    flow_columns = {}
    
    # Her kategori için flow hesapla
    for category_full, category_short in CATEGORY_MAPPING.items():
        size_col = f"{category_short}_toplam_buyukluk"
        
        if size_col not in df.columns:
            logger.warning("Kategori '%s' için toplam büyüklük kolonu bulunamadı", category_short)
            continue
        
        # Günlük frekansa geçiş (eksik günleri forward fill)
        size_series = df.set_index('tarih')[size_col].asfreq('D').ffill()
        
        # Her flow penceresi için hesapla
        for ret_col, days in WINDOWS.items():
            flow_col = ret_col.replace('ret_', 'flow_')
            
            shifted_size = size_series.shift(days)
            # Flow = (bugünkü büyüklük - geçmiş büyüklük) / geçmiş büyüklük
            flows = (size_series - shifted_size) / shifted_size
            
            # Orijinal tarihlere geri map et
            flow_columns[f"{category_short}_{flow_col}"] = flows.reindex(df['tarih']).values
    
    logger.info("Flow kolonları birleştiriliyor...")
    
    # Flow kolonlarını tek seferde birleştir
    if flow_columns:
        flow_df = pd.DataFrame(flow_columns, index=df.index)
        result_df = pd.concat([df, flow_df], axis=1)
    else:
        result_df = df
    
    logger.info("Kategori para akış hesaplamaları tamamlandı")
    return result_df

def main():
    parser = argparse.ArgumentParser(description="TEFAS verisini wide format'ta işle: gereksiz kolonları çıkar, getiriler ve kategori ağırlıklı ortalamalar hesapla")
    parser.add_argument("--input", type=str, default="data/tefas_full_2yrs.parquet", help="Giriş Parquet yolu")
    parser.add_argument("--output", type=str, default="data/tefas_full_2yrs_processed_wide.parquet", help="Çıkış Parquet (varsayılan) yolu")
    parser.add_argument("--excel", type=str, default="", help="Opsiyonel Excel çıktı yolu (.xlsx). Boş bırakılırsa --output temel alınır.")
    args = parser.parse_args()

    input_path = Path(args.input)
    output_path = Path(args.output)

    # Excel yolu belirle
    if args.excel:
        excel_path = Path(args.excel)
    else:
        excel_path = output_path.with_suffix(".xlsx")

    if not input_path.exists():
        logger.error("Giriş dosyası bulunamadı: %s", input_path)
        raise SystemExit(1)

    logger.info("%s yükleniyor...", input_path)
    df = pq.read_table(input_path).to_pandas()

    # Başlangıç kolon bilgisi
    logger.info("Başlangıç kolonları: %s", df.columns.tolist())
    logger.info("Başlangıç kayıt sayısı: %d, fon sayısı: %d", len(df), df["fon_kodu"].nunique())

    # Tarih sütunu garanti altına al
    if df["tarih"].dtype != "datetime64[ns]":
        df["tarih"] = pd.to_datetime(df["tarih"])

    # Fiyat sütunu kontrolü
    if "fiyat" not in df.columns:
        logger.error("'fiyat' sütunu bulunamadı. İşlem iptal.")
        raise SystemExit(1)

    # Gereksiz kolonları çıkar
    df = remove_unwanted_columns(df)

    # Wide format'a dönüştür
    wide_df, fund_categories = convert_to_wide_format(df)

    # Wide format'ta getiri hesaplamalarını yap
    wide_df = compute_rolling_returns_wide(wide_df)

    # Wide format'ta kategori bazında ağırlıklı ortalama getiriler hesapla
    wide_df = compute_category_weighted_returns_wide(wide_df, fund_categories)

    # Kategori toplam büyüklüklerini hesapla
    wide_df = compute_category_total_size(wide_df, fund_categories)

    # Kategori para akışlarını hesapla
    wide_df = compute_category_flows(wide_df, fund_categories)

    logger.info("Son kolon sayısı: %d", len(wide_df.columns))

    # Parquet'e yaz
    output_path.parent.mkdir(exist_ok=True)
    wide_df.to_parquet(output_path, engine="pyarrow", compression="zstd", index=False)
    logger.info("Parquet çıktı ➜ %s", output_path)

    # Excel'e yaz (opsiyonel)
    wide_df.to_excel(excel_path, index=False)
    logger.info("Excel çıktı ➜ %s", excel_path)

    logger.info("Tamamlandı ➜ %s (%d kayıt, %d kolon)", output_path, len(wide_df), len(wide_df.columns))

if __name__ == "__main__":
    main() 