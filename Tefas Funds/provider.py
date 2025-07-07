import requests
from datetime import date
from typing import Any, Dict, List, Optional

__all__ = ["TefasProvider"]


class TefasProvider:
    """Basit TEFAS API istemcisi.

    TEFAS (https://www.tefas.gov.tr) JSON servislerini çağırır ve ham
    python veri yapıları olarak döner. Herhangi bir kimlik doğrulama
    gerektirmez.
    """

    BASE_URL = "https://www.tefas.gov.tr/api/DB"
    TIMEOUT = 15  # saniye

    # ---- dahili yardımcılar -------------------------------------------------
    def _get(self, endpoint: str, params: Optional[Dict[str, str]] = None) -> Any:
        """GET isteği atar ve `response.json()` döner."""
        url = f"{self.BASE_URL}/{endpoint}"
        response = requests.get(url, params=params, timeout=self.TIMEOUT)
        response.raise_for_status()
        return response.json()

    # ---- herkese açık metodlar ---------------------------------------------
    def fund_list(self) -> List[Dict[str, Any]]:
        """Tüm TEFAS fon kodu/isim listesini getirir."""
        return self._get("GetFunds")

    def fund_info(self, code: str) -> Dict[str, Any]:
        """Belirli bir fonun (kod) temel bilgileri.

        TEFAS servisinden tek elemanlı bir liste dönebiliyor; burada ilk
        eleman sözlük olarak geri verilir. Eğer zaten sözlük ise aynen
        döndürülür.
        """
        data = self._get("TekilFonBilgi", {"FonKod": code.upper()})
        if isinstance(data, list):
            return data[0] if data else {}
        return data

    def price_history(
        self,
        code: str,
        start: date,
        end: Optional[date] = None,
    ) -> List[Dict[str, Any]]:
        """Belirtilen tarih aralığında günlük fiyat serisi getirir."""
        if end is None:
            end = date.today()
        return self._get(
            "OldFundPriceValues",
            {
                "FonKod": code.upper(),
                "StartDate": start.isoformat(),
                "EndDate": end.isoformat(),
            },
        )

    def portfolio_breakdown(self, code: str) -> List[Dict[str, Any]]:
        """Fonun son portföy dağılımını döner."""
        return self._get("FonPortfoyDagilimi", {"FonKod": code.upper()}) 