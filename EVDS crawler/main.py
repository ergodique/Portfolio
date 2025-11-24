from pathlib import Path

from evds_client import EvdsClient
from crawler import collect_series_metadata, save_metadata


def run() -> None:
    client = EvdsClient()

    print("EVDS seri metadatası çekiliyor (yalnızca kodlar ve açıklamalar)...")
    df = collect_series_metadata(client)

    total = len(df)
    print(f"Toplam seri sayısı: {total}")

    sample_count = min(10, total)
    if sample_count > 0:
        print(f"\nİlk {sample_count} seriden örnekler:")
        print("-" * 80)
        for _, row in df.head(sample_count).iterrows():
            code = row.get("SERIE_CODE")
            name = row.get("SERIE_NAME")
            group = row.get("DATA_GROUP")
            print(f"Kod: {code}")
            print(f"Açıklama: {name}")
            if group:
                print(f"Veri grubu: {group}")
            print("-" * 80)

    # Çıktı dosyalarının yolları (kök klasör altına data/ dizini içinde)
    base_dir = Path(".")
    data_dir = base_dir / "data"
    json_path = data_dir / "evds_series_metadata.json"
    csv_path = data_dir / "evds_series_metadata.csv"

    save_metadata(df, json_path=json_path, csv_path=csv_path)

    print("\nDosya çıktıları oluşturuldu:")
    print(f"JSON: {json_path.resolve()}")
    print(f"CSV : {csv_path.resolve()}")


if __name__ == "__main__":
    run()


