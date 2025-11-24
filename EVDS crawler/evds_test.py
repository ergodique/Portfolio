import os
import sys
from typing import Any, Dict

import requests


API_KEY_ENV_VAR = "EVDS_API_KEY"
BASE_URL = "https://evds2.tcmb.gov.tr/service/evds/serieList"


def get_api_key() -> str:
    """
    Basit test için öncelik sırası:
    1. Ortam değişkeni EVDS_API_KEY
    2. Kod içindeki sabit fallback (gerekirse elle düzenlenebilir)
    """
    env_key = os.getenv(API_KEY_ENV_VAR)
    if env_key:
        return env_key

    # Gerekirse buraya manuel API anahtarı yazılabilir.
    # Güvenli olması için üretim kodunda bu yaklaşım yerine .env / ortam değişkeni kullanılmalıdır.
    fallback_key = "xED0V6IsoE"
    return fallback_key


def fetch_serie_list() -> Dict[str, Any]:
    api_key = get_api_key()

    # EVDS için anahtar query parametresi olarak gönderilir
    headers: Dict[str, str] = {}
    params = {
        "type": "json",
        "key": api_key,
    }

    print("EVDS serieList endpoint'ine istek atılıyor...")
    print(f"URL: {BASE_URL}")

    response = requests.get(BASE_URL, headers=headers, params=params, timeout=30)

    print(f"HTTP durum kodu: {response.status_code}")

    if response.status_code != 200:
        print("İstek başarısız oldu. Sunucu yanıt gövdesi:")
        # Yanıt tipik olarak JSON ama test aşamasında ham metni göstermek daha faydalı olabilir
        print(response.text)
        response.raise_for_status()

    try:
        data = response.json()
    except ValueError:
        print("Yanıt JSON formatında değil. Ham gövde:")
        print(response.text)
        raise

    return data


def print_sample_series(data: Any, limit: int = 10) -> None:
    if not isinstance(data, list):
        print("Beklenen format list[dict] idi, gelen veri türü:", type(data))
        print("Ham veri örneği:")
        print(str(data)[:1000])
        return

    total = len(data)
    print(f"Toplam seri sayısı (tahmini): {total}")
    print(f"İlk {min(limit, total)} seriden örnekler:")
    print("-" * 80)

    for i, item in enumerate(data[:limit], start=1):
        code = item.get("SERIE_CODE") or item.get("serie_code")
        name = item.get("SERIE_NAME") or item.get("serie_name")
        group = item.get("DATA_GROUP") or item.get("data_group")

        print(f"{i}. Kod: {code}")
        print(f"   Açıklama: {name}")
        if group:
            print(f"   Veri grubu: {group}")
        print("-" * 80)


def main() -> None:
    try:
        data = fetch_serie_list()
    except Exception as exc:
        print("EVDS serieList isteği sırasında bir hata oluştu:", file=sys.stderr)
        print(str(exc), file=sys.stderr)
        sys.exit(1)

    print_sample_series(data)


if __name__ == "__main__":
    main()


