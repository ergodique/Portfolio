from pathlib import Path
from typing import Optional

import pandas as pd

from evds_client import EvdsClient


def collect_series_metadata(client: Optional[EvdsClient] = None) -> pd.DataFrame:
    """
    Tum seri metadatasini EVDS uzerinden cekip bir DataFrame olarak dondurur.

    Bu fonksiyon YALNIZCA metadata ceker, zaman serisi verisi (tarih-deger) cekmez.
    """
    client = client or EvdsClient()
    raw_series = client.get_all_series()

    df = pd.DataFrame(raw_series)

    # Sik kullanilan alanlari one al, digerlerini de koru
    preferred_cols = [
        "CATEGORY_ID",
        "CATEGORY_NAME",
        "DATAGROUP_CODE",
        "DATAGROUP_NAME",
        "SERIE_CODE",
        "SERIE_NAME",
        "FREQUENCY",
        "START_DATE",
        "END_DATE",
    ]

    existing_pref = [c for c in preferred_cols if c in df.columns]
    other_cols = [c for c in df.columns if c not in existing_pref]
    df = df[existing_pref + other_cols]

    # Kod bazinda siralama ve olasi tekrarlarin temizlenmesi
    if "SERIE_CODE" in df.columns:
        df = df.drop_duplicates(subset=["SERIE_CODE"]).sort_values("SERIE_CODE")

    df.reset_index(drop=True, inplace=True)
    return df


def save_metadata(
    df: pd.DataFrame,
    output_dir: Path,
    base_name: str = "evds_series_metadata",
) -> dict:
    """
    Verilen DataFrame'i JSON, CSV ve Excel olarak kaydeder.
    """
    output_dir.mkdir(parents=True, exist_ok=True)

    json_path = output_dir / f"{base_name}.json"
    csv_path = output_dir / f"{base_name}.csv"
    xlsx_path = output_dir / f"{base_name}.xlsx"

    # JSON (UTF-8, Turkce karakterler bozulmadan)
    df.to_json(
        json_path,
        orient="records",
        force_ascii=False,
        indent=2,
    )

    # CSV (Excel uyumlu)
    df.to_csv(
        csv_path,
        index=False,
        encoding="utf-8-sig",
    )

    # Excel
    df.to_excel(
        xlsx_path,
        index=False,
        engine="openpyxl",
    )

    return {
        "json": json_path,
        "csv": csv_path,
        "xlsx": xlsx_path,
    }


