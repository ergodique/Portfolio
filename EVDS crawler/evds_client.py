import os
from typing import Any, Dict, List, Optional

import requests


API_KEY_ENV_VAR = "EVDS_API_KEY"
DEFAULT_BASE_URL = "https://evds2.tcmb.gov.tr/service/evds/"


def resolve_api_key(fallback: Optional[str] = "xED0V6IsoE") -> str:
    """
    API anahtarını ortam değişkeninden okur, yoksa verilen fallback değeri kullanır.

    Üretim senaryolarında fallback kullanmak yerine ortam değişkeni /.env tercih edilmelidir.
    """
    env_key = os.getenv(API_KEY_ENV_VAR)
    if env_key:
        return env_key
    if fallback:
        return fallback
    raise ValueError(
        f"EVDS API anahtarı bulunamadı. Lütfen {API_KEY_ENV_VAR} ortam değişkenini ayarlayın."
    )


class EvdsClient:
    """
    EVDS (TCMB Elektronik Veri Dağıtım Sistemi) için basit bir metadata istemcisi.

    Bu istemci SADECE seri listesi ve varsa veri grupları gibi metaverilere erişir.
    Zaman serisi (tarih-değer) verilerini çekmez.
    """

    def __init__(
        self,
        api_key: Optional[str] = None,
        base_url: str = DEFAULT_BASE_URL,
        timeout: int = 30,
    ) -> None:
        self.api_key = api_key or resolve_api_key()
        self.base_url = base_url.rstrip("/") + "/"
        self.timeout = timeout

    def _request(self, path: str, params: Optional[Dict[str, Any]] = None) -> Any:
        url = self.base_url + path.lstrip("/")

        # EVDS API anahtarı, güncel dokümantasyonda query parametresi
        # olarak kullanılmaktadır: ?key=API_KEY&type=json ...
        headers: Dict[str, str] = {}
        query = dict(params or {})
        # Mevcut parametreleri ezmemek için sadece key yoksa ekle
        query.setdefault("key", self.api_key)

        response = requests.get(url, headers=headers, params=query, timeout=self.timeout)

        if response.status_code != 200:
            # Hata teşhisi için kısa ama faydalı mesaj
            raise RuntimeError(
                f"EVDS isteği başarısız oldu. "
                f"URL={response.url}, status={response.status_code}, body={response.text[:500]}"
            )

        try:
            return response.json()
        except ValueError as exc:
            raise RuntimeError(
                f"EVDS yanıtı JSON formatında değil. URL={response.url}, body örnek={response.text[:500]}"
            ) from exc

    def get_all_series(self) -> List[Dict[str, Any]]:
        """
        Tüm veri serilerinin metadatasını döndürür.

        Dönüş tipik olarak list[dict] formatındadır; her sözlükte en azından
        'SERIE_CODE' ve 'SERIE_NAME' alanları bulunur.
        """
        data = self._request("serieList", params={"type": "json"})

        if not isinstance(data, list):
            # Şema değişikliği vb. durumlarda daha anlamlı hata vermek için kontrol
            raise RuntimeError(
                f"Beklenen format list[dict] idi, gelen: {type(data)}. Örnek: {str(data)[:500]}"
            )

        return data

    def get_datagroups(self) -> Any:
        """
        İsteğe bağlı: Veri gruplarının listesini döndürür.
        Bu da sadece metadata içerir, veri çekmez.
        """
        return self._request("datagroups", params={"type": "json"})


