"""TefasProvider + hızlı demo – tek dosyada her şey.

Kullanım:
    python tefas_all_in_one.py PPN --years 5

Varsayılan: PPN fonunun son 3 yıllık fiyatını indirir.
"""
from __future__ import annotations

import argparse
import sys
from datetime import date, timedelta
from pathlib import Path
from typing import Any, Dict, List, Optional

import requests

try:
    import pandas as pd  # type: ignore
except ImportError:
    pd = None  # type: ignore


class TefasProvider:
    """Basit TEFAS API istemcisi (tek dosya sürümü)."""

    BASE_URL = "https://www.tefas.gov.tr/api/DB"
    TIMEOUT = 15

    # ---- yardımcı ----
    def _get(self, endpoint: str, params: Optional[Dict[str, str]] = None) -> Any:
        url = f"{self.BASE_URL}/{endpoint}"
        resp = requests.get(url, params=params, timeout=self.TIMEOUT)
        resp.raise_for_status()
        return resp.json()

    # ---- API yüzeyi ----
    def fund_info(self, code: str) -> Dict[str, Any]:
        data = self._get("TekilFonBilgi", {"FonKod": code.upper()})
        if isinstance(data, list):
            return data[0] if data else {}
        return data

    def price_history(self, code: str, start: date, end: Optional[date] = None) -> List[Dict[str, Any]]:
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


# ---------------- CLI / Demo -----------------

def parse_args(argv: List[str] | None = None) -> argparse.Namespace:
    p = argparse.ArgumentParser(description="TEFAS fon verisi indirici")
    p.add_argument("code", help="Fon kodu, örn. PPN")
    p.add_argument("--years", type=int, default=3, help="Kaç yıl geriye gidilsin (varsayılan: 3)")
    p.add_argument("--csv", type=Path, default=None, help="Çıktı CSV dosyası (varsayılan kod_yil.csv)")
    return p.parse_args(argv)


def main(argv: List[str] | None = None) -> None:
    args = parse_args(argv)
    provider = TefasProvider()

    info = provider.fund_info(args.code)
    print("Fon adı:", info.get("FonUnvani", "bilgi yok"))

    start = date.today() - timedelta(days=args.years * 365)
    data = provider.price_history(args.code, start=start)
    print(f"{len(data)} günlük kayıt alındı ( {start}  →  {date.today()} )")

    if pd is None:
        print("pandas kurulmadı, CSV oluşturulmadı.")
        return

    df = pd.DataFrame(data)
    outfile: Path = args.csv if args.csv else Path(f"{args.code}_{args.years}y.csv")
    df.to_csv(outfile, index=False)
    print("CSV yazıldı →", outfile.resolve())


if __name__ == "__main__":
    main() 