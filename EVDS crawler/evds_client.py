import os
from pathlib import Path
from typing import Any, Dict, List, Optional

import pandas as pd
from dotenv import load_dotenv
from evds import evdsAPI


API_KEY_ENV_VAR = "EVDS_API_KEY"

# .env dosyasini yukle
env_path = Path(__file__).parent / ".env"
if env_path.exists():
    load_dotenv(env_path)


def resolve_api_key() -> str:
    """
    API anahtarini .env dosyasindan veya ortam degiskeninden okur.
    """
    env_key = os.getenv(API_KEY_ENV_VAR)
    if env_key:
        return env_key
    raise ValueError(
        f"EVDS API anahtari bulunamadi. Lutfen {API_KEY_ENV_VAR} ortam degiskenini ayarlayin "
        f"veya .env dosyasina ekleyin."
    )


class EvdsClient:
    """
    EVDS (TCMB Elektronik Veri Dagitim Sistemi) icin resmi evds paketi kullanan istemci.
    """

    def __init__(self, api_key: Optional[str] = None) -> None:
        self.api_key = api_key or resolve_api_key()
        self.evds = evdsAPI(self.api_key)

    def get_main_categories(self) -> pd.DataFrame:
        """
        Ana kategorilerin listesini dondurur.
        """
        return self.evds.main_categories

    def get_sub_categories(self, category_id: int) -> pd.DataFrame:
        """
        Belirtilen ana kategori altindaki alt kategorileri dondurur.
        """
        return self.evds.get_sub_categories(category_id)

    def get_series(self, datagroup_code: str) -> pd.DataFrame:
        """
        Belirtilen alt kategori (datagroup) altindaki serileri dondurur.
        """
        return self.evds.get_series(datagroup_code)

    def get_all_series(self) -> List[Dict[str, Any]]:
        """
        Tum kategorileri ve serileri gezerek tam seri listesini dondurur.
        """
        all_series = []

        # Ana kategorileri al
        main_cats = self.get_main_categories()
        print(f"Toplam {len(main_cats)} ana kategori bulundu.")

        for _, cat_row in main_cats.iterrows():
            cat_id = cat_row.get("CATEGORY_ID")
            cat_name = cat_row.get("TOPIC_TITLE_TR", "")
            print(f"  Kategori isleniyor: {cat_id} - {cat_name}")

            try:
                # Alt kategorileri al
                sub_cats = self.get_sub_categories(cat_id)

                for _, sub_row in sub_cats.iterrows():
                    datagroup_code = sub_row.get("DATAGROUP_CODE")
                    datagroup_name = sub_row.get("DATAGROUP_NAME", "")

                    try:
                        # Serileri al
                        series_df = self.get_series(datagroup_code)

                        for _, series_row in series_df.iterrows():
                            serie_dict = series_row.to_dict()
                            serie_dict["CATEGORY_ID"] = cat_id
                            serie_dict["CATEGORY_NAME"] = cat_name
                            serie_dict["DATAGROUP_CODE"] = datagroup_code
                            serie_dict["DATAGROUP_NAME"] = datagroup_name
                            all_series.append(serie_dict)

                    except Exception as e:
                        print(f"    Seri alinamadi ({datagroup_code}): {e}")
                        continue

            except Exception as e:
                print(f"    Alt kategori alinamadi ({cat_id}): {e}")
                continue

        return all_series

