import argparse
import json
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, List, Set

import pandas as pd
import requests
import yfinance as yf


WIKI_SP500 = "https://en.wikipedia.org/wiki/List_of_S%26P_500_companies"
WIKI_NASDAQ100 = "https://en.wikipedia.org/wiki/Nasdaq-100"
WIKI_RUSSELL1000 = "https://en.wikipedia.org/wiki/Russell_1000_Index"

DEFAULT_WORKERS = 8
DEFAULT_OUTPUT = "cache/optionable_symbols.json"


@dataclass
class UniverseConfig:
    include_sp500: bool = True
    include_nasdaq100: bool = True
    include_russell1000: bool = True


def scrape_column(url: str, candidate_cols: Iterable[str]) -> List[str]:
    """
    Scrape a single column from a Wikipedia table.
    Returns list of ticker strings (may be empty on failure).
    """
    try:
        # Use requests with a browser-like User-Agent to avoid 403
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
            "AppleWebKit/537.36 (KHTML, like Gecko) "
            "Chrome/122.0 Safari/537.36",
        }
        resp = requests.get(url, headers=headers, timeout=15)
        resp.raise_for_status()
        html = resp.text

        dfs = pd.read_html(html)
    except Exception as e:
        print(f"[warn] Failed to read HTML from {url}: {e}")
        return []

    for df in dfs:
        for col in candidate_cols:
            if col in df.columns:
                tickers = (
                    df[col]
                    .astype(str)
                    .str.strip()
                    .str.replace(".", "-", regex=False)  # BRK.B -> BRK-B
                )
                tickers = [t for t in tickers if t and t.upper() != col.upper()]
                print(f"[info] {url} -> {len(tickers)} tickers from column '{col}'")
                return tickers

    print(f"[warn] No matching columns {list(candidate_cols)} found in {url}")
    return []


def build_universe(cfg: UniverseConfig) -> List[str]:
    """
    Build raw ticker universe from Wikipedia (SP500 + Nasdaq100 + Russell1000).
    """
    tickers: List[str] = []

    if cfg.include_sp500:
        tickers.extend(
            scrape_column(WIKI_SP500, ["Symbol"])
        )
    if cfg.include_nasdaq100:
        tickers.extend(
            scrape_column(WIKI_NASDAQ100, ["Ticker", "Ticker symbol"])
        )
    if cfg.include_russell1000:
        tickers.extend(
            scrape_column(WIKI_RUSSELL1000, ["Ticker symbol", "Symbol", "Ticker"])
        )

    unique = sorted(set(tickers))
    print(f"[info] Raw universe size (deduplicated): {len(unique)}")
    return unique


def has_options(symbol: str, min_expiries: int = 1) -> bool:
    """
    Return True if the given symbol has an option chain on Yahoo Finance.
    """
    try:
        t = yf.Ticker(symbol)
        opts = t.options
        if not opts or len(opts) < min_expiries:
            return False
        return True
    except Exception:
        return False


def filter_optionable_symbols(
    symbols: Iterable[str],
    workers: int = DEFAULT_WORKERS,
    min_expiries: int = 1,
) -> List[str]:
    """
    Given a universe of symbols, keep only those with option chains.
    Uses ThreadPoolExecutor for concurrency.
    """
    symbols = list(dict.fromkeys(symbols))  # preserve order, drop dups
    total = len(symbols)
    print(f"[info] Checking option chains for {total} symbols...")

    optionable: List[str] = []
    checked: Set[str] = set()

    def worker(sym: str):
        return sym, has_options(sym, min_expiries=min_expiries)

    with ThreadPoolExecutor(max_workers=workers) as executor:
        futures = {executor.submit(worker, sym): sym for sym in symbols}
        for i, fut in enumerate(as_completed(futures), start=1):
            sym, ok = fut.result()
            checked.add(sym)
            if ok:
                optionable.append(sym)
                print(f"  ✓ {sym}")
            else:
                print(f"  ✗ {sym}")

            if i % 50 == 0 or i == total:
                print(f"[info] Progress: {i}/{total} checked, {len(optionable)} optionable.")

    print(f"[info] Finished: {len(optionable)} / {total} symbols have options.")
    return optionable


def save_universe(symbols: List[str], output_path: Path) -> None:
    """
    Save optionable universe to JSON file.
    """
    output_path.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "generated_at": time.strftime("%Y-%m-%d %H:%M:%S"),
        "source": {
            "sp500": True,
            "nasdaq100": True,
            "russell1000": True,
            "provider": "wikipedia + yfinance",
        },
        "symbol_count": len(symbols),
        "symbols": symbols,
    }
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2)
    print(f"[info] Saved {len(symbols)} optionable symbols to {output_path}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Build a list of US stocks with option chains using Wikipedia + Yahoo Finance."
    )
    parser.add_argument(
        "--workers",
        type=int,
        default=DEFAULT_WORKERS,
        help=f"Number of concurrent workers (default: {DEFAULT_WORKERS})",
    )
    parser.add_argument(
        "--min-expiries",
        type=int,
        default=1,
        help="Minimum number of expiries required to treat symbol as optionable (default: 1)",
    )
    parser.add_argument(
        "--output",
        type=str,
        default=DEFAULT_OUTPUT,
        help=f"Output JSON path (default: {DEFAULT_OUTPUT})",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    start = time.time()

    cfg = UniverseConfig()
    raw_universe = build_universe(cfg)
    optionable = filter_optionable_symbols(
        raw_universe,
        workers=args.workers,
        min_expiries=args.min_expiries,
    )

    output_path = Path(__file__).resolve().parent / args.output
    save_universe(optionable, output_path)

    elapsed = time.time() - start
    print(f"[info] Completed in {elapsed:.1f} seconds.")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n[info] Interrupted by user.")
        sys.exit(1)


