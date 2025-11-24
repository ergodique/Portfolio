from pathlib import Path
from typing import Optional

import pandas as pd

from evds_client import EvdsClient


def collect_series_metadata(client: Optional[EvdsClient] = None) -> pd.DataFrame:
    """
    Tüm seri metadatasını EVDS üzerinden çekip bir DataFrame olarak döndürür.

    Bu fonksiyon YALNIZCA metadata çeker, zaman serisi verisi (tarih-değer) çekmez.
    """
    client = client or EvdsClient()
    raw_series = client.get_all_series()

    df = pd.DataFrame(raw_series)

    # Sık kullanılan alanları öne al, diğerlerini de koru
    preferred_cols = [
        "SERIE_CODE",
        "SERIE_NAME",
        "DATA_GROUP",
        "FREQUENCY",
        "DECIMAL",
        "START_DATE",
        "END_DATE",
    ]

    existing_pref = [c for c in preferred_cols if c in df.columns]
    other_cols = [c for c in df.columns if c not in existing_pref]
    df = df[existing_pref + other_cols]

    # Kod bazında sıralama ve olası tekrarların temizlenmesi
    if "SERIE_CODE" in df.columns:
        df = df.drop_duplicates(subset=["SERIE_CODE"]).sort_values("SERIE_CODE")

    df.reset_index(drop=True, inplace=True)
    return df


def save_metadata(
    df: pd.DataFrame,
    json_path: Path,
    csv_path: Path,
) -> None:
    """
    Verilen DataFrame'i JSON ve CSV olarak kaydeder.
    """
    json_path.parent.mkdir(parents=True, exist_ok=True)
    csv_path.parent.mkdir(parents=True, exist_ok=True)

    # JSON (UTF-8, Türkçe karakterler bozulmadan)
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


