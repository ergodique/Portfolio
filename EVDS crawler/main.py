from pathlib import Path

from evds_client import EvdsClient
from crawler import collect_series_metadata, save_metadata


def run() -> None:
    client = EvdsClient()

    print("EVDS seri metadatasi cekiliyor (yalnizca kodlar ve aciklamalar)...")
    print("=" * 80)
    df = collect_series_metadata(client)

    total = len(df)
    print("=" * 80)
    print(f"Toplam seri sayisi: {total}")

    sample_count = min(10, total)
    if sample_count > 0:
        print(f"\nIlk {sample_count} seriden ornekler:")
        print("-" * 80)
        for _, row in df.head(sample_count).iterrows():
            code = row.get("SERIE_CODE")
            name = row.get("SERIE_NAME")
            category = row.get("CATEGORY_NAME")
            datagroup = row.get("DATAGROUP_NAME")
            print(f"Kod: {code}")
            print(f"Aciklama: {name}")
            if category:
                print(f"Kategori: {category}")
            if datagroup:
                print(f"Veri grubu: {datagroup}")
            print("-" * 80)

    # Cikti dosyalarinin yollari
    base_dir = Path(".")
    data_dir = base_dir / "data"

    paths = save_metadata(df, output_dir=data_dir)

    print("\nDosya ciktilari olusturuldu:")
    print(f"JSON : {paths['json'].resolve()}")
    print(f"CSV  : {paths['csv'].resolve()}")
    print(f"Excel: {paths['xlsx'].resolve()}")


if __name__ == "__main__":
    run()


