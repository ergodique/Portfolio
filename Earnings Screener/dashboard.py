"""
Earnings (next 7 days) – IV / HV
Evren : S&P 500 + Nasdaq-100 + Russell 1000
--------------------------------------------------------------------------
pip install yfinance pandas numpy requests beautifulsoup4 lxml websockets
"""

import os, sys, time, yfinance as yf, pandas as pd, numpy as np, requests
from bs4 import BeautifulSoup
from datetime import date, timedelta
from math import sqrt

REFRESH_SEC = 60
TODAY       = date.today()
WEEK_LIMIT  = TODAY + timedelta(days=7)

# ─── 1. EVREN ────────────────────────────────────────────────────────────────
def scrape(url, col_names):
    for df in pd.read_html(url, flavor="lxml"):
        for c in col_names:
            if c in df.columns:
                return df[c].astype(str).str.strip().tolist()
    return []

sp500  = scrape("https://en.wikipedia.org/wiki/List_of_S%26P_500_companies", ["Symbol"])
nasdaq = scrape("https://en.wikipedia.org/wiki/Nasdaq-100", ["Ticker", "Ticker symbol"])
r1000  = scrape("https://en.wikipedia.org/wiki/Russell_1000_Index",
                ["Ticker symbol", "Symbol", "Ticker"])

TICKERS = sorted(set(sp500 + nasdaq + r1000))
print(f"[info] Universe size: {len(TICKERS)}")

# ─── 2. YARDIMCILAR ─────────────────────────────────────────────────────────
def next_earn_ts(tkr: yf.Ticker):
    """Bugünden sonraki ilk bilanço datetime'ını döndürür (None = bulunamadı)."""
    try:
        # Yeni API (>=0.2.38)
        if hasattr(tkr, "get_next_earnings_date"):
            ts = tkr.get_next_earnings_date()
            if pd.notna(ts):
                return ts

        # Eski API – DataFrame döner
        ed = tkr.get_earnings_dates(limit=8)
        fut = ed[ed.index.date >= TODAY]
        return fut.index[0] if not fut.empty else None
    except Exception:
        return None

def atm_iv(sym):
    try:
        t = yf.Ticker(sym)
        if not t.options:
            return None
        exp  = sorted(t.options)[0]
        oc   = t.option_chain(exp)
        spot = t.history(period="1d")["Close"].iloc[-1]
        calls = oc.calls.assign(dist=lambda d: abs(d.strike-spot))
        puts  = oc.puts .assign(dist=lambda d: abs(d.strike-spot))
        if calls.empty or puts.empty:
            return None
        c_iv = calls.sort_values("dist").iloc[0]["impliedVolatility"]
        p_iv = puts .sort_values("dist").iloc[0]["impliedVolatility"]
        if pd.isna(c_iv) or pd.isna(p_iv):
            return None
        return (c_iv + p_iv)/2
    except Exception:
        return None

def hist_vol(sym, win=30):
    try:
        px = yf.Ticker(sym).history(period=f"{win*2}d")["Close"].tail(win+1)
        if len(px) < win+1:
            return None
        return np.log(px/px.shift(1)).dropna().std(ddof=0)*np.sqrt(252)
    except Exception:
        return None

# ─── 3. TABLO ───────────────────────────────────────────────────────────────
def build_table():
    recs = []
    for sym in TICKERS:
        tkr  = yf.Ticker(sym)
        ts   = next_earn_ts(tkr)
        if ts is None:                       continue
        if not (TODAY <= ts.date() <= WEEK_LIMIT):   continue
        if not tkr.options:                   continue

        iv = atm_iv(sym);  hv = hist_vol(sym)
        if iv is None or hv in (None,0):      continue

        recs.append({
            "Earnings": ts.strftime("%d-%m-%Y %H:%M"),
            "Ticker"  : sym,
            "30d IV"  : f"{iv*100:5.1f}%",
            "30d HV"  : f"{hv*100:5.1f}%",
            "IV/HV"   : f"{iv/hv:4.2f}"
        })

    cols = ["Earnings","Ticker","30d IV","30d HV","IV/HV"]
    df = pd.DataFrame(recs, columns=cols)
    return df.sort_values("Earnings").reset_index(drop=True) if not df.empty else df

def clear(): os.system("cls" if os.name=="nt" else "clear")

# ─── 4. ANA DÖNGÜ ───────────────────────────────────────────────────────────
if __name__ == "__main__":
    try:
        while True:
            clear()
            print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}]  "
                  "Earnings (today + 7d)  –  IV / HV\n")
            df = build_table()
            if df.empty:
                print("No earnings with option chains in the next 7 days.")
            else:
                print(df.to_string(index=False))
            sys.stdout.flush()
            time.sleep(REFRESH_SEC)
    except KeyboardInterrupt:
        print("\nStopped.")
