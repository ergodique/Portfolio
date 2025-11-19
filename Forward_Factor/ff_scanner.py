import json
from io import StringIO
from pathlib import Path

import yfinance as yf
import pandas as pd
import numpy as np
from datetime import date, datetime
import tkinter as tk
from tkinter import ttk, messagebox
import threading
import time
import requests
from concurrent.futures import ThreadPoolExecutor, as_completed

#todo
# earnings filter, earninglerden sonraki dteler için forward factor hesaplama
# mid price kullanarak oluşturalacak calendar fiyatlarını ekle
# 

def get_optionable_symbols(
    max_pages: int = 120,
    pause: float = 0.3,
    cache_path: Path | None = None,
    use_cache_on_fail: bool = True,
):
    """
    Opsiyonlanabilir sembolleri Yahoo screener'dan, o mümkün değilse Nasdaq Trader listesinden çeker.
    """
    yahoo_symbols = _fetch_optionable_from_yahoo(max_pages=max_pages, pause=pause)

    if not yahoo_symbols:
        print("[info] Yahoo screener endpoint unavailable. Falling back to Nasdaq optionable list...")
        try:
            yahoo_symbols = _fetch_optionable_from_nasdaq()
        except Exception as e:
            print(f"[warn] Failed to fetch optionable list from Nasdaq: {e}")

    symbols = sorted(set(filter(None, yahoo_symbols)))

    if symbols and cache_path:
        try:
            cache_path.parent.mkdir(parents=True, exist_ok=True)
            with open(cache_path, "w", encoding="utf-8") as f:
                json.dump(
                    {
                        "generated_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                        "source": "yahoo_or_nasdaq_optionable",
                        "count": len(symbols),
                        "symbols": symbols,
                    },
                    f,
                    indent=2,
                )
        except Exception as e:
            print(f"[warn] Could not write cache to {cache_path}: {e}")

    if symbols:
        return symbols

    if use_cache_on_fail and cache_path and cache_path.exists():
        try:
            with open(cache_path, "r", encoding="utf-8") as f:
                cached = json.load(f)
            cached_symbols = cached.get("symbols", [])
            print(f"[info] Using cached optionable list ({len(cached_symbols)} symbols) from {cache_path}")
            return cached_symbols
        except Exception as e:
            print(f"[warn] Failed to read cached symbols from {cache_path}: {e}")

    return []


def _fetch_optionable_from_yahoo(max_pages: int, pause: float) -> list[str]:
    base_urls = [
        "https://query1.finance.yahoo.com/v7/finance/screener/predefined/saved",
        "https://query1.finance.yahoo.com/v1/finance/screener/predefined/saved",
    ]
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
        "Accept": "application/json, text/javascript, */*; q=0.01",
        "Connection": "keep-alive",
        "Referer": "https://finance.yahoo.com/",
    }

    symbols: list[str] = []
    total_hits = 0

    for page in range(max_pages):
        start = page * 100
        params = {
            "scrIds": "optionable",
            "count": 100,
            "start": start,
            "formatted": "false",
            "lang": "en-US",
            "region": "US",
            "corsDomain": "finance.yahoo.com",
        }

        page_ok = False
        last_error: str | None = None

        for base_url in base_urls:
            try:
                resp = requests.get(base_url, headers=headers, params=params, timeout=10)
                if resp.status_code == 404:
                    last_error = f"404 at {base_url}"
                    continue
                resp.raise_for_status()

                content_type = resp.headers.get("Content-Type", "")
                if not content_type.startswith("application/json"):
                    last_error = f"Non-JSON ({content_type})"
                    continue

                data = resp.json() or {}
                quotes = (
                    data.get("finance", {})
                    .get("result", [{}])[0]
                    .get("quotes", [])
                )

                if not quotes:
                    page_ok = True
                    break

                symbols.extend(q.get("symbol") for q in quotes if q.get("symbol"))
                total_hits += len(quotes)
                page_ok = True
                break
            except Exception as e:
                last_error = str(e)
                continue

        if not page_ok:
            print(f"[warn] Failed to fetch page start {start}: {last_error}")
        else:
            time.sleep(pause)

        # Yahoo bazen 1000-1500 kayıt sonra tekrar eder; yeterince veri geldiyse çıkalım.
        if total_hits == 0 and not page_ok:
            continue
        if total_hits >= 4000:
            break

    return symbols


def _fetch_optionable_from_nasdaq() -> list[str]:
    """
    Nasdaq Trader option symbology dosyasından opsiyonlanabilir underlyings listesini çeker.
    """
    url = "https://ftp.nasdaqtrader.com/SymbolDirectory/options.txt"
    headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}
    resp = requests.get(url, headers=headers, timeout=30)
    resp.raise_for_status()

    text = resp.text.strip()
    if not text:
        return []

    # Dosyanın sonunda özet satırları var; onları filtrele
    lines = [line for line in text.splitlines() if line and not line.startswith("File Creation Time")]
    buffer = "\n".join(lines)

    df = pd.read_csv(StringIO(buffer), sep="|").dropna(how="all")
    df.columns = [c.strip() for c in df.columns]

    candidate_cols = [c for c in df.columns if "Underlying" in c]
    if not candidate_cols:
        raise ValueError(f"Could not identify underlying column in Nasdaq file. Columns: {df.columns.tolist()}")
    underlyings: list[str] = []

    for col in candidate_cols:
        vals = (
            df[col]
            .astype(str)
            .str.strip()
            .str.upper()
        )
        vals = [v for v in vals if v and v != col.upper()]
        underlyings.extend(vals)

    if not underlyings:
        raise ValueError("Nasdaq option file did not return any underlyings")

    return sorted(set(underlyings))

class ForwardFactorDashboard(tk.Tk):
    """
    A dashboard to display the forward factor for stock options across all optionable stocks.
    """
    def __init__(self):
        super().__init__()
        self.title("Forward Factor Scanner - All Optionable Stocks")
        self.geometry("1200x700")
        self.min_volume = 0
        self.min_open_interest = 0

        # Paths / cache
        self.cache_dir = Path(__file__).resolve().parent / "cache"
        self.cache_file = self.cache_dir / "filtered_symbols.json"
        self.cboe_csv_path = Path(__file__).resolve().parent / "optionable_tickers_cboe.csv"

        # Master symbol universe (from CBOE CSV)
        self.master_symbols: list[str] = []
        self.batch_size: int = 500
        self.next_batch_start: int = 0

        # Test symbols - high option volume stocks (fallback only)
        self.test_symbols = [
            "SPY", "QQQ", "AAPL", "TSLA", "NVDA", "MSFT", "AMZN", "GOOGL", "META", "NFLX",
            "GLD", "SLV", "IWM", "DIA", "AMD", "INTC", "BA", "JPM", "BAC", "XLE"
        ]
        self.filtered_results: list[dict] = []
        
        # Cache mechanism for ticker data
        self.ticker_cache: dict[str, dict] = {}
        self.cache_lock = threading.Lock()
        self.progress_lock = threading.Lock()
        self.processed_count = 0

        # Control flags
        self.shutting_down: bool = False
        self.current_executor: ThreadPoolExecutor | None = None

        self._build_ui()
        self._load_initial_symbols()
        self.protocol("WM_DELETE_WINDOW", self._on_close)

    def _build_ui(self):
        main_frame = ttk.Frame(self, padding=10)
        main_frame.grid(row=0, column=0, sticky="nsew")
        self.grid_rowconfigure(0, weight=1)
        self.grid_columnconfigure(0, weight=1)

        # --- Header ---
        header_frame = ttk.Frame(main_frame)
        header_frame.grid(row=0, column=0, columnspan=2, sticky="ew", pady=(0, 10))

        title_label = ttk.Label(header_frame, text="Forward Factor Scanner - All Optionable Stocks", font=("Segoe UI", 16, "bold"))
        title_label.pack(side="left")

        self.last_updated_label = ttk.Label(header_frame, text="Last Updated: --:--:--", font=("Segoe UI", 10))
        self.last_updated_label.pack(side="right", anchor="s")
        
        # --- Results Table ---
        self.tree = ttk.Treeview(
            main_frame,
            columns=(
                "Ticker",
                "Expiry Pair",
                "Front DTE",
                "Back DTE",
                "Front IV",
                "Back IV",
                "Fwd Vol",
                "Fwd Factor",
                "Cal Mid",
            ),
            show="headings",
        )
        self.tree.grid(row=1, column=0, sticky="nsew")
        main_frame.grid_rowconfigure(1, weight=1)
        main_frame.grid_columnconfigure(0, weight=1)

        # --- Define Headings ---
        self.tree.heading("Ticker", text="Ticker")
        self.tree.heading("Expiry Pair", text="Expiry Pair")
        self.tree.heading("Front DTE", text="Front DTE")
        self.tree.heading("Back DTE", text="Back DTE")
        self.tree.heading("Front IV", text="Front IV (%)")
        self.tree.heading("Back IV", text="Back IV (%)")
        self.tree.heading("Fwd Vol", text="Fwd Vol (%)")
        self.tree.heading("Fwd Factor", text="Fwd Factor (%)")
        self.tree.heading("Cal Mid", text="Cal Mid ($)")

        # --- Define Column Styles ---
        self.tree.column("Ticker", anchor="center", width=80)
        self.tree.column("Expiry Pair", anchor="center", width=90)
        self.tree.column("Front DTE", anchor="center", width=70)
        self.tree.column("Back DTE", anchor="center", width=70)
        self.tree.column("Front IV", anchor="center", width=80)
        self.tree.column("Back IV", anchor="center", width=80)
        self.tree.column("Fwd Vol", anchor="center", width=80)
        self.tree.column("Fwd Factor", anchor="center", width=90)
        self.tree.column("Cal Mid", anchor="center", width=90)

        # --- Scrollbar ---
        scrollbar = ttk.Scrollbar(main_frame, orient="vertical", command=self.tree.yview)
        self.tree.configure(yscrollcommand=scrollbar.set)
        scrollbar.grid(row=1, column=1, sticky="ns")

        # --- Filters Frame ---
        filters_frame = ttk.LabelFrame(main_frame, text="Filters", padding=10)
        filters_frame.grid(row=2, column=0, columnspan=2, sticky="ew", pady=(10, 0))

        ttk.Label(filters_frame, text="Min Volume:").grid(row=0, column=0, padx=(0, 5), sticky="w")
        self.volume_var = tk.StringVar(value="0")
        volume_entry = ttk.Entry(filters_frame, width=15, textvariable=self.volume_var)
        volume_entry.grid(row=0, column=1, padx=(0, 20), sticky="w")

        ttk.Label(filters_frame, text="Min Open Interest:").grid(row=0, column=2, padx=(0, 5), sticky="w")
        self.oi_var = tk.StringVar(value="0")
        oi_entry = ttk.Entry(filters_frame, width=15, textvariable=self.oi_var)
        oi_entry.grid(row=0, column=3, padx=(0, 20), sticky="w")

        # Row 1: IV and calendar spread / cost filters
        ttk.Label(filters_frame, text="Min IV (%)").grid(row=1, column=0, padx=(0, 5), sticky="w")
        self.min_iv_var = tk.StringVar(value="0")
        iv_entry = ttk.Entry(filters_frame, width=15, textvariable=self.min_iv_var)
        iv_entry.grid(row=1, column=1, padx=(0, 20), sticky="w")

        ttk.Label(filters_frame, text="Max Cal Spread ($)").grid(row=1, column=2, padx=(0, 5), sticky="w")
        self.max_cal_spread_var = tk.StringVar(value="9999")
        spread_entry = ttk.Entry(filters_frame, width=15, textvariable=self.max_cal_spread_var)
        spread_entry.grid(row=1, column=3, padx=(0, 20), sticky="w")

        ttk.Label(filters_frame, text="Max Cal Mid ($)").grid(row=1, column=4, padx=(0, 5), sticky="w")
        self.max_cal_mid_var = tk.StringVar(value="9999")
        cal_mid_entry = ttk.Entry(filters_frame, width=15, textvariable=self.max_cal_mid_var)
        cal_mid_entry.grid(row=1, column=5, padx=(0, 20), sticky="w")

        filter_btn = ttk.Button(filters_frame, text="Filter (Current List)", command=self.apply_filters)
        filter_btn.grid(row=0, column=4, padx=(10, 0))
        
        load_all_btn = ttk.Button(filters_frame, text="Load All Symbols (Yahoo)", command=self._load_all_symbols)
        load_all_btn.grid(row=0, column=5, padx=(10, 0))

        refresh_btn = ttk.Button(filters_frame, text="Refresh Batch (CBOE)", command=self.refresh_batch)
        refresh_btn.grid(row=0, column=6, padx=(10, 0))

        # Row 2: Single ticker run
        ttk.Label(filters_frame, text="Single Ticker:").grid(row=2, column=0, padx=(0, 5), sticky="w")
        self.single_ticker_var = tk.StringVar()
        single_entry = ttk.Entry(filters_frame, width=15, textvariable=self.single_ticker_var)
        single_entry.grid(row=2, column=1, padx=(0, 20), sticky="w")

        single_btn = ttk.Button(filters_frame, text="Run Single", command=self.run_single_ticker)
        single_btn.grid(row=2, column=2, padx=(10, 0), sticky="w")

        # --- Status Bar ---
        self.status_label = ttk.Label(main_frame, text="Initializing symbol list...", anchor="w", relief=tk.SUNKEN)
        self.status_label.grid(row=3, column=0, columnspan=2, sticky="ew", pady=(10, 0))

    def _load_initial_symbols(self):
        """
        Load symbol universe on startup.
        Priority:
        1) CBOE CSV master list (optionable_tickers_cboe.csv)
        2) Cached filtered symbols (cache/filtered_symbols.json)
        3) Built-in test symbols
        """
        # 1) Try CBOE CSV master list
        if self.cboe_csv_path.exists():
            try:
                df = pd.read_csv(self.cboe_csv_path)
                # Try to detect ticker column
                cols = [c.strip() for c in df.columns]
                df.columns = cols
                ticker_col = None
                for candidate in ("Ticker", "Symbol", "Underlying", cols[0] if cols else None):
                    if candidate and candidate in cols:
                        ticker_col = candidate
                        break
                if ticker_col:
                    tickers = (
                        df[ticker_col]
                        .astype(str)
                        .str.strip()
                    )
                    self.master_symbols = [t for t in tickers if t and t.upper() != ticker_col.upper()]
                    self.master_symbols = sorted(set(self.master_symbols))
                    self.next_batch_start = 0
                    if self.master_symbols:
                        self.status_label.config(
                            text=(
                                f"Loaded {len(self.master_symbols)} CBOE optionable symbols. "
                                f"Click 'Refresh Batch (CBOE)' to scan the next {self.batch_size}."
                            )
                        )
                        return
                else:
                    self.status_label.config(
                        text=(
                            "Could not detect ticker column in optionable_tickers_cboe.csv. "
                            "Falling back to cached/test symbols."
                        )
                    )
            except Exception as e:
                print(f"[warn] Failed to load CBOE CSV {self.cboe_csv_path}: {e}")
                # Fall through to cached/test logic

        # 2) Cached filtered symbols
        cached_symbols = self._load_cached_symbol_list()
        if cached_symbols:
            self._set_symbol_list(
                cached_symbols,
                "Loaded cached filtered symbols"
            )
            return

        # 3) Built-in test symbols
        self._set_symbol_list(
            self.test_symbols.copy(),
            f"Ready - Using {len(self.test_symbols)} default test symbols"
        )

    def _load_cached_symbol_list(self):
        """
        Load cached filtered symbol list if the cache file exists.
        """
        if not self.cache_file.exists():
            return []
        try:
            with open(self.cache_file, "r", encoding="utf-8") as f:
                data = json.load(f)
            symbols = data.get("symbols", [])
            if isinstance(symbols, list):
                return symbols
        except Exception as e:
            print(f"[warn] Failed to read cached symbols from {self.cache_file}: {e}")
        return []

    def _set_symbol_list(self, symbols, source_description):
        """
        Helper to update the current symbol universe and reflect it in the UI.
        """
        self.all_symbols = symbols
        symbol_list = ", ".join(symbols[:10])
        if len(symbols) > 10:
            symbol_list += f", ... ({len(symbols)} total)"
        self.status_label.config(
            text=f"{source_description}. Symbols: {symbol_list}" if symbols else f"{source_description}. No symbols available."
        )

    def _on_close(self):
        """
        Called when the window is closed. Signal running scans to stop and close the app.
        """
        self.shutting_down = True
        try:
            if self.current_executor is not None:
                # Cancel pending futures; in-flight requests may still finish
                self.current_executor.shutdown(wait=False, cancel_futures=True)
        except Exception:
            pass
        try:
            self.destroy()
        except Exception:
            pass

    def refresh_batch(self):
        """
        Load the next batch of symbols from the CBOE master list and start scanning.
        Each call processes up to self.batch_size symbols using 4 workers.
        """
        if not self.master_symbols:
            messagebox.showwarning(
                "No CBOE Symbols",
                "CBOE master list not loaded. Please ensure 'optionable_tickers_cboe.csv' exists "
                "or use 'Load All Symbols (Yahoo)' instead."
            )
            return

        total = len(self.master_symbols)
        if total == 0:
            messagebox.showwarning("No Symbols", "CBOE master list is empty.")
            return

        # Wrap around when reaching the end
        if self.next_batch_start >= total:
            self.next_batch_start = 0

        start = self.next_batch_start
        end = min(start + self.batch_size, total)
        batch = self.master_symbols[start:end]
        self.next_batch_start = end

        if not batch:
            messagebox.showwarning("No Batch", "Could not determine next batch to scan.")
            return

        batch_desc = f"CBOE batch {start + 1}-{end} of {total}"
        self._set_symbol_list(batch, f"Loaded {len(batch)} symbols for {batch_desc}")

        # Start scan with current filters
        self.apply_filters()

    def _load_all_symbols(self):
        """Load all optionable symbols in background thread."""
        self.status_label.config(text="Loading all optionable symbols from Yahoo Finance... This may take a few minutes.")
        thread = threading.Thread(target=self._fetch_symbols, daemon=True)
        thread.start()

    def _fetch_symbols(self):
        """Fetch all optionable symbols."""
        try:
            optionable_cache = self.cache_dir / "optionable_symbols.json"
            symbols = get_optionable_symbols(
                max_pages=120,
                pause=0.3,
                cache_path=optionable_cache,
            )
            self.after(0, lambda s=symbols: self._set_symbol_list(s, "Loaded Yahoo Finance optionable symbols"))
        except Exception as e:
            self.after(0, self._show_error, f"Error loading symbols: {str(e)}")

    def _get_ticker_data(self, ticker_symbol):
        """
        Get ticker data with caching. Returns cached data if available, otherwise fetches and caches.
        Returns: dict with keys: options, expiries_dates, days_to_expiry, current_price
        """
        # Check cache first
        with self.cache_lock:
            if ticker_symbol in self.ticker_cache:
                return self.ticker_cache[ticker_symbol]
        
        # Fetch data
        ticker = yf.Ticker(ticker_symbol)
        
        try:
            # Get options list (only once)
            options_list = ticker.options
            if not options_list or len(options_list) == 0:
                raise Exception(f"No options available for {ticker_symbol}")
            
            # Get expiries dates
            expiries_dates = pd.to_datetime(options_list)
            today = pd.to_datetime(date.today())
            days_to_expiry = (expiries_dates - today).days
            
            # Get current stock price (only once)
            hist = ticker.history(period="1d")
            if hist.empty:
                raise Exception(f"No price data for {ticker_symbol}")
            current_price = float(hist['Close'].iloc[-1])
            if pd.isna(current_price) or current_price <= 0:
                raise Exception(f"Invalid price data for {ticker_symbol}")
            
            # Cache the data
            ticker_data = {
                'options': options_list,
                'expiries_dates': expiries_dates,
                'days_to_expiry': days_to_expiry,
                'current_price': current_price,
                'ticker': ticker  # Keep ticker object for option_chain calls
            }
            
            with self.cache_lock:
                self.ticker_cache[ticker_symbol] = ticker_data
            
            return ticker_data
            
        except Exception as e:
            raise Exception(f"Error fetching ticker data for {ticker_symbol}: {str(e)}")

    def apply_filters(self):
        """Apply filters and start scanning."""
        try:
            self.min_volume = int(self.volume_var.get() or "0")
            self.min_open_interest = int(self.oi_var.get() or "0")
            self.min_iv = float(self.min_iv_var.get() or "0")
            self.max_cal_spread = float(self.max_cal_spread_var.get() or "9999")
            self.max_cal_mid = float(self.max_cal_mid_var.get() or "9999")
        except ValueError:
            messagebox.showerror("Invalid Input", "Volume, Open Interest, IV and calendar filters must be numeric.")
            return
        
        if not self.all_symbols:
            messagebox.showwarning("No Symbols", "Please wait for symbols to load first.")
            return
        
        # Clear cache when starting new scan
        with self.cache_lock:
            self.ticker_cache.clear()
        self.processed_count = 0
        
        self.status_label.config(
            text=(
                f"Scanning {len(self.all_symbols)} symbols with filters: "
                f"Vol >= {self.min_volume}, OI >= {self.min_open_interest}, "
                f"IV >= {self.min_iv}%, CalSpread <= {self.max_cal_spread}$, "
                f"CalMid <= {self.max_cal_mid}$..."
            )
        )
        thread = threading.Thread(target=self._scan_all_symbols, daemon=True)
        thread.start()

    def run_single_ticker(self):
        """
        Run scan for a single ticker entered by the user.
        """
        ticker = (self.single_ticker_var.get() or "").strip().upper()
        if not ticker:
            messagebox.showerror("Invalid Ticker", "Please enter a ticker symbol.")
            return

        self._set_symbol_list([ticker], f"Single ticker: {ticker}")
        self.apply_filters()

    def _scan_all_symbols(self):
        """Scan all symbols and calculate forward factors using parallel processing."""
        try:
            if self.shutting_down:
                return

            all_results = []
            total = len(self.all_symbols)
            errors = []
            
            # Use ThreadPoolExecutor for parallel processing
            with ThreadPoolExecutor(max_workers=4) as executor:
                self.current_executor = executor
                try:
                    # Submit all tasks
                    future_to_symbol = {
                        executor.submit(self.fetch_forward_factor_data, symbol): symbol 
                        for symbol in self.all_symbols
                    }
                    
                    # Process completed tasks
                    for future in as_completed(future_to_symbol):
                        if self.shutting_down:
                            break

                        symbol = future_to_symbol[future]
                        
                        try:
                            results = future.result()
                            if results:
                                all_results.extend(results)
                                print(f"✓ {symbol}: Found {len(results)} results")
                            else:
                                print(f"⚠ {symbol}: No results - check debug output above for details")
                        except Exception as e:
                            error_msg = str(e)
                            errors.append(f"{symbol}: {error_msg}")
                            print(f"✗ {symbol}: {error_msg}")
                        
                        # Update progress (thread-safe)
                        with self.progress_lock:
                            self.processed_count += 1
                            processed = self.processed_count
                        
                        # Update UI every 5 symbols or on last symbol
                        if processed % 5 == 0 or processed == total:
                            def update_progress(p=processed, t=total, c=len(all_results)):
                                self.status_label.config(
                                    text=f"Scanning... {p}/{t} symbols processed. Found {c} results so far.")
                                self.update_idletasks()
                            self.after(0, update_progress)
                finally:
                    self.current_executor = None
            
            # Sort by Forward Factor (descending)
            all_results.sort(key=lambda x: x.get("Fwd Factor", -float('inf')), reverse=True)
            
            # Final status update
            if errors:
                error_summary = f"Completed. Found {len(all_results)} results. Errors: {len(errors)} symbols failed."
                print(f"\n=== Scan Complete ===")
                print(f"Results: {len(all_results)}")
                print(f"Errors: {len(errors)}")
                if len(errors) <= 10:
                    for err in errors:
                        print(f"  - {err}")
            else:
                error_summary = f"Scan complete. Found {len(all_results)} results."
            
            self.filtered_results = all_results
            self.after(0, self._populate_table, all_results)
            self.after(0, lambda: self.status_label.config(text=error_summary))
        except Exception as e:
            error_msg = f"Critical error: {str(e)}"
            print(f"✗ {error_msg}")
            import traceback
            traceback.print_exc()
            self.after(0, self._show_error, error_msg)

    def _populate_table(self, data):
        """
        Updates the Treeview with new data. Must be called on the main thread.
        """
        # Clear existing data
        for item in self.tree.get_children():
            self.tree.delete(item)
        
        # Insert new data
        for row in data:
            self.tree.insert("", "end", values=(
                row["Ticker"],
                row["Expiry Pair"],
                row["Front DTE"],
                row["Back DTE"],
                f"{row['Front IV']:.2f}",
                f"{row['Back IV']:.2f}",
                f"{row['Fwd Vol']:.2f}",
                f"{row['Fwd Factor']:.2f}",
                f"{row.get('Cal Mid', float('nan')):.3f}" if not pd.isna(row.get("Cal Mid", float("nan"))) else "n/a",
            ))
        
        self.last_updated_label.config(text=f"Last Updated: {datetime.now().strftime('%H:%M:%S')}")
        self.status_label.config(text=f"Scan complete. Found {len(data)} results. Sorted by Forward Factor (descending).")

    def _show_error(self, error_message):
        """
        Displays an error in the status bar. Must be called on the main thread.
        """
        self.status_label.config(text=f"Error: {error_message}")
        self.last_updated_label.config(text="Last Updated: Failed")

    def fetch_forward_factor_data(self, ticker_symbol):
        """
        The main data fetching and calculation logic for a single ticker.
        Uses cached ticker data to minimize API calls.
        """
        target_days_pairs = [(30, 60), (60, 90), (30, 90)]
        
        # Get ticker data from cache (or fetch if not cached)
        ticker_data = self._get_ticker_data(ticker_symbol)
        
        ticker = ticker_data['ticker']
        expiries_dates = ticker_data['expiries_dates']
        days_to_expiry = ticker_data['days_to_expiry']
        current_price = ticker_data['current_price']

        results = []
        debug_reasons = []  # Track why pairs are skipped

        for dte1_target, dte2_target in target_days_pairs:
            try:
                # Find nearest expiries
                if len(days_to_expiry) == 0:
                    debug_reasons.append(f"{dte1_target}-{dte2_target}d: No expiry dates")
                    continue
                    
                idx1 = np.abs(days_to_expiry - dte1_target).argmin()
                expiry1_date = expiries_dates[idx1]
                dte1 = int(days_to_expiry[idx1])

                idx2 = np.abs(days_to_expiry - dte2_target).argmin()
                expiry2_date = expiries_dates[idx2]
                dte2 = int(days_to_expiry[idx2])

                if dte1 >= dte2 or dte1 < 0:
                    debug_reasons.append(f"{dte1_target}-{dte2_target}d: Invalid DTE order (dte1={dte1}, dte2={dte2})")
                    continue # Skip if expiries are the same or in wrong order

                # Get ATM IV and book data for both expiries
                iv1, vol1, oi1, bid1, ask1, mid1 = self._get_atm_iv_with_filters(
                    ticker, expiry1_date.strftime('%Y-%m-%d'), current_price
                )
                iv2, vol2, oi2, bid2, ask2, mid2 = self._get_atm_iv_with_filters(
                    ticker, expiry2_date.strftime('%Y-%m-%d'), current_price
                )

                # Check if IV is valid
                if iv1 <= 0 or iv2 <= 0 or pd.isna(iv1) or pd.isna(iv2):
                    debug_reasons.append(f"{dte1_target}-{dte2_target}d: Invalid IV (iv1={iv1:.4f}, iv2={iv2:.4f})")
                    continue

                # Apply volume and OI filters
                if vol1 < self.min_volume or oi1 < self.min_open_interest:
                    debug_reasons.append(
                        f"{dte1_target}-{dte2_target}d: Front expiry filter fail "
                        f"(vol1={vol1}, oi1={oi1}, min_vol={self.min_volume}, min_oi={self.min_open_interest})"
                    )
                    continue
                if vol2 < self.min_volume or oi2 < self.min_open_interest:
                    debug_reasons.append(
                        f"{dte1_target}-{dte2_target}d: Back expiry filter fail "
                        f"(vol2={vol2}, oi2={oi2}, min_vol={self.min_volume}, min_oi={self.min_open_interest})"
                    )
                    continue

                # Apply IV filter (in %)
                if (iv1 * 100.0) < self.min_iv or (iv2 * 100.0) < self.min_iv:
                    debug_reasons.append(
                        f"{dte1_target}-{dte2_target}d: IV filter fail "
                        f"(iv1%={iv1*100:.2f}, iv2%={iv2*100:.2f}, min_iv%={self.min_iv})"
                    )
                    continue

                # Calendar pricing: long back-month, short front-month (call calendar)
                # Worst-case debit (buy back at ask, sell front at bid)
                if bid1 <= 0 or ask2 <= 0:
                    debug_reasons.append(
                        f"{dte1_target}-{dte2_target}d: No usable bid/ask for calendar legs "
                        f"(front_bid={bid1}, back_ask={ask2})"
                    )
                    continue
                if mid1 <= 0 or mid2 <= 0:
                    debug_reasons.append(
                        f"{dte1_target}-{dte2_target}d: No usable mid prices for calendar legs "
                        f"(front_mid={mid1}, back_mid={mid2})"
                    )
                    continue

                cal_spread = ask2 - bid1
                cal_mid = mid2 - mid1

                # Apply calendar spread / mid filters (absolute $)
                if cal_spread > self.max_cal_spread:
                    debug_reasons.append(
                        f"{dte1_target}-{dte2_target}d: CalSpread filter fail "
                        f"(cal_spread={cal_spread:.3f}, max={self.max_cal_spread})"
                    )
                    continue
                if cal_mid > self.max_cal_mid:
                    debug_reasons.append(
                        f"{dte1_target}-{dte2_target}d: CalMid filter fail "
                        f"(cal_mid={cal_mid:.3f}, max={self.max_cal_mid})"
                    )
                    continue

                # Calculate forward vol and factor
                fwd_sigma, ff_ratio, fwd_var = self._calculate_forward_vol_and_factor(dte1, iv1, dte2, iv2)

                if fwd_sigma is None:
                    debug_reasons.append(f"{dte1_target}-{dte2_target}d: Forward variance negative (fwd_var={fwd_var})")
                    continue
                    
                if np.isinf(ff_ratio) or pd.isna(ff_ratio):
                    debug_reasons.append(f"{dte1_target}-{dte2_target}d: Forward factor invalid (ff_ratio={ff_ratio})")
                    continue

                results.append({
                    "Ticker": ticker_symbol,
                    "Expiry Pair": f"{dte1_target}-{dte2_target}d",
                    "Front DTE": dte1,
                    "Back DTE": dte2,
                    "Front IV": iv1 * 100,
                    "Back IV": iv2 * 100,
                    "Fwd Vol": fwd_sigma * 100,
                    "Fwd Factor": ff_ratio * 100,
                    "Cal Mid": cal_mid if cal_mid != float("inf") else float("nan"),
                })
            except Exception as e:
                # Continue to next pair if this one fails
                debug_reasons.append(f"{dte1_target}-{dte2_target}d: Exception - {str(e)[:50]}")
                continue
        
        # If no results, print debug reasons
        if not results and debug_reasons:
            print(f"  {ticker_symbol} debug reasons:")
            for reason in debug_reasons:
                print(f"    - {reason}")
        
        return results

    def _get_atm_iv_with_filters(self, ticker, expiry_date, current_price):
        """
        Gets the implied volatility and order book data of the ATM call.
        Returns: (iv, volume, open_interest, bid, ask, mid)
        """
        opt_chain = ticker.option_chain(expiry_date)
        calls = opt_chain.calls
        
        if calls.empty:
            raise Exception(f"No call options found for {expiry_date}")

        # Find the at-the-money strike
        atm_strike_idx = (calls['strike'] - current_price).abs().argmin()
        atm_call = calls.iloc[atm_strike_idx]
        
        iv = atm_call.get('impliedVolatility', 0)
        volume = atm_call.get('volume', 0) if 'volume' in atm_call else 0
        open_interest = atm_call.get('openInterest', 0) if 'openInterest' in atm_call else 0

        bid = float(atm_call.get('bid', 0.0)) if 'bid' in atm_call else 0.0
        ask = float(atm_call.get('ask', 0.0)) if 'ask' in atm_call else 0.0
        last = float(atm_call.get('lastPrice', 0.0)) if 'lastPrice' in atm_call else 0.0

        # Fallback: if bid/ask yoksa veya 0 ise, lastPrice'i mid/bid/ask olarak kullan
        if not (bid > 0 and ask > 0):
            if last > 0 and not pd.isna(last):
                bid = ask = last
            else:
                raise Exception(f"No usable bid/ask/lastPrice for {expiry_date}")

        mid = (bid + ask) / 2.0 if bid > 0 and ask > 0 else 0.0
        
        # Handle NaN values
        if pd.isna(iv):
            iv = 0
        if pd.isna(volume):
            volume = 0
        if pd.isna(open_interest):
            open_interest = 0
        
        return float(iv), int(volume), int(open_interest), bid, ask, mid

    def _calculate_forward_vol_and_factor(self, dte1, iv1, dte2, iv2):
        """
        Calculates forward volatility and forward factor.
        """
        if dte2 <= dte1:
            return None, None, -1 # Invalid input

        T1 = dte1 / 365.0
        T2 = dte2 / 365.0
        s1 = iv1
        s2 = iv2

        total_variance1 = (s1 ** 2) * T1
        total_variance2 = (s2 ** 2) * T2
        
        fwd_var = (total_variance2 - total_variance1) / (T2 - T1)
        
        if fwd_var < 0:
            return None, None, fwd_var

        fwd_sigma = np.sqrt(fwd_var)
        
        if fwd_sigma == 0.0:
            ff_ratio = np.inf
        else:
            ff_ratio = (s1 - fwd_sigma) / fwd_sigma
            
        return fwd_sigma, ff_ratio, fwd_var

if __name__ == "__main__":
    try:
        app = ForwardFactorDashboard()
        app.mainloop()
    except Exception as e:
        print(f"Failed to start the application: {e}")
        print("Please ensure 'yfinance', 'pandas', 'numpy', and 'requests' are installed.")