import io
import sys
from pathlib import Path

import pandas as pd
import requests


def get_all_optionable_tickers():
    """
    OCC / CBOE kaynaklarını kullanarak opsiyonu olan tüm tickerların listesini çeker.

    Not:
    - Önce CBOE equity + index options CSV dosyasını indirir.
    - Gerekirse buraya ek kontrol/filtre adımları eklenebilir.
    """
    # CBOE Sembol Listesi (equity + index options)
    cboe_url = "https://www.cboe.com/us/options/symboldir/equity_index_options/?download=csv"

    print("CBOE'den opsiyon listesi çekiliyor...")

    headers = {
        "User-Agent": (
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
            "AppleWebKit/537.36 (KHTML, like Gecko) "
            "Chrome/91.0.4472.124 Safari/537.36"
        )
    }

    try:
        response = requests.get(cboe_url, headers=headers, timeout=30)
        response.raise_for_status()

        content = response.content.decode("utf-8", errors="ignore")
        df_cboe = pd.read_csv(io.StringIO(content))

        # Sütun isimlerini temizle
        df_cboe.columns = [c.strip() for c in df_cboe.columns]

        # CBOE formatında genellikle 'Stock Symbol' alanı bulunur
        symbol_col_candidates = [c for c in df_cboe.columns if "Symbol" in c]
        if "Stock Symbol" in df_cboe.columns:
            col = "Stock Symbol"
        elif symbol_col_candidates:
            col = symbol_col_candidates[0]
            print(f"[info] Using symbol column: {col}")
        else:
            print(f"[error] Could not find symbol column in CBOE CSV. Columns: {df_cboe.columns.tolist()}")
            return []

        tickers = (
            df_cboe[col]
            .astype(str)
            .str.strip()
        )
        tickers = sorted(set(t for t in tickers if t and t.upper() != col.upper()))

        print(f"Toplam {len(tickers)} adet opsiyonlu ticker bulundu.")
        return tickers

    except Exception as e:
        print(f"Bir hata oluştu: {e}")
        return []


def main():
    tickers = get_all_optionable_tickers()
    if not tickers:
        print("Hiç ticker alınamadı.")
        sys.exit(1)

    # İlk birkaç ticker'ı göster
    print("İlk 10 Ticker:", tickers[:10])

    # İsteğe bağlı: CSV'ye kaydet
    out_path = Path("optionable_tickers_cboe.csv")
    pd.DataFrame(tickers, columns=["Ticker"]).to_csv(out_path, index=False)
    print(f"Ticker listesi '{out_path}' dosyasına kaydedildi.")


if __name__ == "__main__":
    main()


