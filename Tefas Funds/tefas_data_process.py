import argparse
from pathlib import Path
import pandas as pd
import pyarrow.parquet as pq
import pyarrow as pa
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

def compute_rolling_returns(df: pd.DataFrame) -> pd.DataFrame:
    """Fon bazında kaydırmalı getirileri (takvim günü bazlı) ekler."""
    df = df.sort_values(["fon_kodu", "tarih"]).copy()
    df["fiyat"] = pd.to_numeric(df["fiyat"], errors="coerce")

    # Yeni kolonları NaN ile oluştur
    for col in WINDOWS.keys():
        df[col] = pd.NA

    result_frames = []
    for code, grp in df.groupby("fon_kodu", sort=False):
        g = grp.copy()
        g = g.sort_values("tarih")
        # Günlük frekansa geç – eksik günleri ileriye doğru doldur (ffill)
        s_daily = (
            g.set_index("tarih")["fiyat"]
            .asfreq("D")
            .ffill()
        )

        for col, days in WINDOWS.items():
            shifted = s_daily.shift(days)
            ret_series = s_daily / shifted - 1
            # Orijinal tarihlere geri map et
            g[col] = ret_series.reindex(g["tarih"]).values

        result_frames.append(g)

    df_out = pd.concat(result_frames, ignore_index=True)
    return df_out

def main():
    parser = argparse.ArgumentParser(description="TEFAS verisine rolling getiriler ekle")
    parser.add_argument("--input", type=str, default="data/tefas_test_data.parquet", help="Giriş Parquet yolu")
    parser.add_argument("--output", type=str, default="data/tefas_test_data_processed.parquet", help="Çıkış Parquet (varsayılan) yolu")
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

    # Tarih sütunu garanti altına al
    if df["tarih"].dtype != "datetime64[ns]":
        df["tarih"] = pd.to_datetime(df["tarih"])

    # Fiyat sütunu kontrolü
    if "fiyat" not in df.columns:
        logger.error("'fiyat' sütunu bulunamadı. İşlem iptal.")
        raise SystemExit(1)

    df = compute_rolling_returns(df)

    logger.info("Son sütun listesi: %s", df.columns.tolist())

    # Parquet'e yaz
    output_path.parent.mkdir(exist_ok=True)
    df.to_parquet(output_path, engine="pyarrow", compression="zstd", index=False)

    # Excel'e yaz (opsiyonel)
    df.to_excel(excel_path, index=False)
    logger.info("Excel çıktı ➜ %s", excel_path)

    logger.info("Tamamlandı ➜ %s (%d kayıt, %d fon)", output_path, len(df), df["fon_kodu"].nunique())

if __name__ == "__main__":
    main() 