# requirements: aiohttp, pandas, pyarrow  # (pyarrow sadece çıktıda lazım)
# repo kökünüz PYTHONPATH'ta ise:
from providers.tefas_provider import TefasProvider
import asyncio, pandas as pd, pyarrow as pa, pyarrow.parquet as pq

tp = TefasProvider()

async def fetch_ppn():
    # 10 yıl geriye; TEFAS daha eskiyi bulursa döndürür
    start_date = "2015-07-07"
    perf = tp.get_fund_performance(
        fund_code="PPN",
        start_date=start_date,
        end_date="2025-07-07"
    )
    if perf.get("error_message"):
        print("Hata:", perf["error_message"])
        return
    # Listeyi DataFrame'e çevir
    df = pd.DataFrame(perf["fiyat_geçmisi"])
    print(df.head())          # erken kontrol
    print(df.tail())
    # Çıktıyı Parquet olarak kaydet
    pq.write_table(pa.Table.from_pandas(df),
                   "data/fund_code=PPN/ppn_history.parquet",
                   compression="zstd")
    print("Satır sayısı:", len(df))

if __name__ == "__main__":
    asyncio.run(fetch_ppn())
