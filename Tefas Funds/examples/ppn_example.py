"""Basit demo: PPN fonu verilerini çekip CSV'ye kaydeder."""

from datetime import date

try:
    import pandas as pd  # type: ignore
except ImportError:  # Pandas yoksa basit fallback
    pd = None  # type: ignore

try:
    # Çoğu durumda örnek modül olarak çalıştırılınca bu çalışır
    from ..provider import TefasProvider  # type: ignore
except ImportError:  # doğrudan 'python ppn_example.py' şeklinde çalıştırıldığında
    import sys
    from pathlib import Path

    # .. (parent) klasörü sys.path'e ekle
    sys.path.append(str(Path(__file__).resolve().parents[1]))

    from provider import TefasProvider  # type: ignore


def main() -> None:
    tp = TefasProvider()

    # Genel bilgi
    info = tp.fund_info("PPN")
    if info:
        print("Fon adı:", info.get("FonUnvani", "bilgi yok"))
    else:
        print("PPN için genel bilgi bulunamadı.")

    # Fiyat geçmişi (son 3 yıl)
    prices = tp.price_history("PPN", start=date.today().replace(year=date.today().year - 5))
    if pd is not None:
        df = pd.DataFrame(prices)
        df.to_csv("PPN_prices.csv", index=False)
        print("PPN_prices.csv dosyası oluşturuldu (", len(df), "satır ).")
    else:
        print("pandas yüklü değil; CSV çıktısı oluşturulmadı. Toplam", len(prices), "kayıt getirildi.")


if __name__ == "__main__":
    main() 