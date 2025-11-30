"""
Forward Factor Scanner - Schwab API Version
Real-time option data from Charles Schwab API.
"""

import json
from io import StringIO
from pathlib import Path

import pandas as pd
import numpy as np
from datetime import date, datetime
import tkinter as tk
from tkinter import ttk, messagebox
import threading
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

# Import Schwab client and config
from schwab_client import SchwabClient
try:
    from config import APP_KEY, APP_SECRET, CALLBACK_URL, TOKENS_FILE
except ImportError:
    APP_KEY = None
    APP_SECRET = None
    CALLBACK_URL = "https://127.0.0.1"
    TOKENS_FILE = "tokens.json"


class ForwardFactorDashboard(tk.Tk):
    """
    A dashboard to display the forward factor for stock options across all optionable stocks.
    Uses Charles Schwab API for real-time data.
    """
    def __init__(self):
        super().__init__()
        self.title("Forward Factor Scanner - Schwab (Real-Time)")
        self.geometry("1400x700")
        self.min_volume = 0
        self.min_open_interest = 0

        # Paths / cache
        self.cache_dir = Path(__file__).resolve().parent / "cache"
        self.cache_file = self.cache_dir / "filtered_symbols.json"
        # Use parent folder's CBOE CSV if available
        self.cboe_csv_path = Path(__file__).resolve().parent.parent / "Forward_Factor" / "optionable_tickers_cboe.csv"
        if not self.cboe_csv_path.exists():
            self.cboe_csv_path = Path(__file__).resolve().parent / "optionable_tickers_cboe.csv"

        # Master symbol universe (from CBOE CSV)
        self.master_symbols: list[str] = []
        self.batch_size: int = 100  # Smaller batches for real-time API
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
        
        # Schwab client (initialized later)
        self.schwab_client: SchwabClient | None = None
        self.client_initialized = False

        self._build_ui()
        self._load_initial_symbols()
        self.protocol("WM_DELETE_WINDOW", self._on_close)
        
        # Initialize Schwab client in background
        threading.Thread(target=self._init_schwab_client, daemon=True).start()

    def _init_schwab_client(self):
        """Initialize Schwab API client in background."""
        try:
            if not APP_KEY or APP_KEY == "YOUR_APP_KEY_HERE":
                self.after(0, lambda: self.status_label.config(
                    text="Please configure your Schwab API credentials in config.py"
                ))
                return
            
            self.after(0, lambda: self.status_label.config(
                text="Initializing Schwab API connection..."
            ))
            
            self.schwab_client = SchwabClient(
                app_key=APP_KEY,
                app_secret=APP_SECRET,
                callback_url=CALLBACK_URL,
                tokens_file=str(Path(__file__).resolve().parent / TOKENS_FILE),
                verbose=True
            )
            self.client_initialized = True
            
            self.after(0, lambda: self.status_label.config(
                text=f"Schwab API connected. {len(self.master_symbols)} symbols loaded. Ready to scan."
            ))
            
        except Exception as e:
            error_msg = str(e)
            self.after(0, lambda: self.status_label.config(
                text=f"Schwab API error: {error_msg}"
            ))
            print(f"Schwab client initialization error: {e}")

    def _build_ui(self):
        main_frame = ttk.Frame(self, padding=10)
        main_frame.grid(row=0, column=0, sticky="nsew")
        self.grid_rowconfigure(0, weight=1)
        self.grid_columnconfigure(0, weight=1)

        # --- Header ---
        header_frame = ttk.Frame(main_frame)
        header_frame.grid(row=0, column=0, columnspan=2, sticky="ew", pady=(0, 10))

        title_label = ttk.Label(header_frame, text="Forward Factor Scanner - Schwab (Real-Time)", font=("Segoe UI", 16, "bold"))
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
                "Front Vol",
                "Front OI",
                "Stock Price",
                "Front Bid/Ask",
                "Back Bid/Ask",
                "Cal Debit",
                "Earnings",
                "FF",
                "R/R",
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
        self.tree.heading("Front Vol", text="Front Vol")
        self.tree.heading("Front OI", text="Front OI")
        self.tree.heading("Stock Price", text="Stock Price ($)")
        self.tree.heading("Front Bid/Ask", text="Front Bid/Ask ($)")
        self.tree.heading("Back Bid/Ask", text="Back Bid/Ask ($)")
        self.tree.heading("Cal Debit", text="Cal Debit ($)")
        self.tree.heading("Earnings", text="Earnings")
        self.tree.heading("FF", text="FF (%)")
        self.tree.heading("R/R", text="R/R")

        # --- Define Column Styles ---
        self.tree.column("Ticker", anchor="center", width=80)
        self.tree.column("Expiry Pair", anchor="center", width=90)
        self.tree.column("Front DTE", anchor="center", width=70)
        self.tree.column("Back DTE", anchor="center", width=70)
        self.tree.column("Front IV", anchor="center", width=80)
        self.tree.column("Back IV", anchor="center", width=80)
        self.tree.column("Fwd Vol", anchor="center", width=80)
        self.tree.column("Front Vol", anchor="center", width=80)
        self.tree.column("Front OI", anchor="center", width=80)
        self.tree.column("Stock Price", anchor="center", width=90)
        self.tree.column("Front Bid/Ask", anchor="center", width=130)
        self.tree.column("Back Bid/Ask", anchor="center", width=130)
        self.tree.column("Cal Debit", anchor="center", width=90)
        self.tree.column("Earnings", anchor="center", width=120)
        self.tree.column("FF", anchor="center", width=70)
        self.tree.column("R/R", anchor="center", width=60)

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

        # Row 1: IV and calendar debit filter
        ttk.Label(filters_frame, text="Min IV (%)").grid(row=1, column=0, padx=(0, 5), sticky="w")
        self.min_iv_var = tk.StringVar(value="0")
        iv_entry = ttk.Entry(filters_frame, width=15, textvariable=self.min_iv_var)
        iv_entry.grid(row=1, column=1, padx=(0, 20), sticky="w")

        ttk.Label(filters_frame, text="Max Cal Debit ($)").grid(row=1, column=2, padx=(0, 5), sticky="w")
        self.max_cal_debit_var = tk.StringVar(value="6")
        cal_debit_entry = ttk.Entry(filters_frame, width=15, textvariable=self.max_cal_debit_var)
        cal_debit_entry.grid(row=1, column=3, padx=(0, 20), sticky="w")

        # Row 2: DTE limits and Forward Factor Filter
        ttk.Label(filters_frame, text="Min Front DTE").grid(row=2, column=0, padx=(0, 5), sticky="w")
        self.min_front_dte_var = tk.StringVar(value="25")
        min_front_entry = ttk.Entry(filters_frame, width=10, textvariable=self.min_front_dte_var)
        min_front_entry.grid(row=2, column=1, padx=(0, 20), sticky="w")

        ttk.Label(filters_frame, text="Max Back DTE").grid(row=2, column=2, padx=(0, 5), sticky="w")
        self.max_back_dte_var = tk.StringVar(value="95")
        max_back_entry = ttk.Entry(filters_frame, width=10, textvariable=self.max_back_dte_var)
        max_back_entry.grid(row=2, column=3, padx=(0, 20), sticky="w")

        ttk.Label(filters_frame, text="Min Fwd Factor (%):").grid(row=2, column=4, padx=(0, 5), sticky="w")
        self.min_ff_var = tk.StringVar(value="5")
        ff_entry = ttk.Entry(filters_frame, width=15, textvariable=self.min_ff_var)
        ff_entry.grid(row=2, column=5, padx=(0, 20), sticky="w")

        # Row 3: R/R Filter
        ttk.Label(filters_frame, text="Min R/R:").grid(row=3, column=0, padx=(0, 5), sticky="w")
        self.min_rr_var = tk.StringVar(value="1.5")
        rr_entry = ttk.Entry(filters_frame, width=10, textvariable=self.min_rr_var)
        rr_entry.grid(row=3, column=1, padx=(0, 20), sticky="w")
        
        # Row 3: Buttons
        filter_btn = ttk.Button(filters_frame, text="Filter (Current List)", command=self.apply_filters)
        filter_btn.grid(row=3, column=4, padx=(10, 0))
        
        load_all_btn = ttk.Button(filters_frame, text="Load All Symbols (CBOE)", command=self._load_all_symbols)
        load_all_btn.grid(row=3, column=5, padx=(10, 0))

        refresh_btn = ttk.Button(filters_frame, text="Refresh Batch", command=self.refresh_batch)
        refresh_btn.grid(row=3, column=6, padx=(10, 0))

        # Row 4: Single ticker run + STOP
        ttk.Label(filters_frame, text="Single Ticker:").grid(row=4, column=0, padx=(0, 5), sticky="w")
        self.single_ticker_var = tk.StringVar()
        single_entry = ttk.Entry(filters_frame, width=15, textvariable=self.single_ticker_var)
        single_entry.grid(row=4, column=1, padx=(0, 20), sticky="w")

        single_btn = ttk.Button(filters_frame, text="Run Single", command=self.run_single_ticker)
        single_btn.grid(row=4, column=2, padx=(10, 0), sticky="w")

        # Stop scan button
        stop_btn = ttk.Button(filters_frame, text="STOP", command=self.stop_scan)
        stop_btn.grid(row=4, column=3, padx=(10, 0), sticky="w")

        # --- Status Bar ---
        self.status_label = ttk.Label(main_frame, text="Initializing...", anchor="w", relief=tk.SUNKEN)
        self.status_label.grid(row=3, column=0, columnspan=2, sticky="ew", pady=(10, 0))

    def _load_initial_symbols(self):
        """Load symbol universe on startup from CBOE CSV."""
        if self.cboe_csv_path.exists():
            try:
                df = pd.read_csv(self.cboe_csv_path)
                cols = [c.strip() for c in df.columns]
                df.columns = cols
                ticker_col = None
                for candidate in ("Ticker", "Symbol", "Underlying", cols[0] if cols else None):
                    if candidate and candidate in cols:
                        ticker_col = candidate
                        break
                if ticker_col:
                    tickers = df[ticker_col].astype(str).str.strip()
                    self.master_symbols = [t for t in tickers if t and t.upper() != ticker_col.upper()]
                    self.master_symbols = sorted(set(self.master_symbols))
                    self.next_batch_start = 0
                    if self.master_symbols:
                        self.status_label.config(
                            text=f"Loaded {len(self.master_symbols)} CBOE symbols. Waiting for Schwab API..."
                        )
                        return
            except Exception as e:
                print(f"[warn] Failed to load CBOE CSV: {e}")

        # Fallback to test symbols
        self._set_symbol_list(
            self.test_symbols.copy(),
            f"Using {len(self.test_symbols)} default test symbols"
        )

    def _set_symbol_list(self, symbols, source_description):
        """Update the current symbol universe."""
        self.all_symbols = symbols
        symbol_list = ", ".join(symbols[:10])
        if len(symbols) > 10:
            symbol_list += f", ... ({len(symbols)} total)"
        self.status_label.config(
            text=f"{source_description}. Symbols: {symbol_list}" if symbols else f"{source_description}. No symbols available."
        )

    def _on_close(self):
        """Called when the window is closed."""
        self.shutting_down = True
        try:
            if self.current_executor is not None:
                self.current_executor.shutdown(wait=False, cancel_futures=True)
        except Exception:
            pass
        try:
            self.destroy()
        except Exception:
            pass

    def refresh_batch(self):
        """Load the next batch of symbols and start scanning."""
        if not self.client_initialized:
            messagebox.showwarning("Not Ready", "Schwab API is not initialized yet. Please wait.")
            return
            
        if not self.master_symbols:
            messagebox.showwarning("No Symbols", "No symbols loaded.")
            return

        total = len(self.master_symbols)
        if self.next_batch_start >= total:
            self.next_batch_start = 0

        end_idx = min(self.next_batch_start + self.batch_size, total)
        batch_symbols = self.master_symbols[self.next_batch_start:end_idx]
        
        self._set_symbol_list(
            batch_symbols,
            f"Batch {self.next_batch_start + 1}-{end_idx} of {total}"
        )
        
        self.next_batch_start = end_idx
        self.apply_filters()

    def _load_all_symbols(self):
        """Load all symbols from the CBOE list."""
        if not self.master_symbols:
            messagebox.showwarning("No Symbols", "CBOE master list not loaded.")
            return
            
        self._set_symbol_list(
            self.master_symbols,
            f"Loaded full CBOE optionable universe ({len(self.master_symbols)} symbols)"
        )

    def _get_ticker_data(self, ticker_symbol):
        """
        Get ticker data from Schwab API with caching.
        Returns: dict with keys: expiry_dates, current_price, option_chain
        """
        # Check cache first
        with self.cache_lock:
            if ticker_symbol in self.ticker_cache:
                return self.ticker_cache[ticker_symbol]
        
        if not self.schwab_client:
            raise Exception("Schwab client not initialized")
        
        # Get option chain (includes underlying quote)
        chain = self.schwab_client.get_option_chain(
            symbol=ticker_symbol,
            contract_type="CALL",
            strike_count=20,
            include_underlying_quote=True
        )
        
        if not chain:
            raise Exception(f"No option chain data for {ticker_symbol}")
        
        # Extract underlying price
        underlying = chain.get('underlying', {})
        current_price = underlying.get('last', underlying.get('mark', 0))
        
        if not current_price or current_price <= 0:
            # Try to get from quote
            quote = self.schwab_client.get_quote(ticker_symbol)
            if quote:
                current_price = quote.get('lastPrice', quote.get('mark', 0))
        
        if not current_price or current_price <= 0:
            raise Exception(f"Could not get price for {ticker_symbol}")
        
        # Extract expiry dates from call map
        call_exp_map = chain.get('callExpDateMap', {})
        expiry_dates = sorted(call_exp_map.keys())
        
        if not expiry_dates:
            raise Exception(f"No expiry dates for {ticker_symbol}")
        
        # Cache the data
        ticker_data = {
            'current_price': float(current_price),
            'expiry_dates': expiry_dates,
            'call_exp_map': call_exp_map,
            'underlying': underlying
        }
        
        with self.cache_lock:
            self.ticker_cache[ticker_symbol] = ticker_data
        
        return ticker_data

    def apply_filters(self):
        """Apply filters and start scanning."""
        if not self.client_initialized:
            messagebox.showwarning("Not Ready", "Schwab API is not initialized yet.")
            return
            
        try:
            self.min_volume = int(self.volume_var.get() or "0")
            self.min_open_interest = int(self.oi_var.get() or "0")
            self.min_iv = float(self.min_iv_var.get() or "0")
            self.min_ff = float(self.min_ff_var.get() or "5")
            self.max_cal_debit = float(self.max_cal_debit_var.get() or "9999")
            self.min_front_dte = int(self.min_front_dte_var.get() or "0")
            self.max_back_dte = int(self.max_back_dte_var.get() or "365")
            self.min_rr = float(self.min_rr_var.get() or "0")
        except ValueError:
            messagebox.showerror(
                "Invalid Input",
                "Filter values must be numeric."
            )
            return
        
        if not hasattr(self, 'all_symbols') or not self.all_symbols:
            messagebox.showwarning("No Symbols", "Please load symbols first.")
            return
        
        # Clear cache when starting new scan
        with self.cache_lock:
            self.ticker_cache.clear()
        self.processed_count = 0
        self.shutting_down = False
        
        self.status_label.config(
            text=f"Scanning {len(self.all_symbols)} symbols with Schwab API..."
        )
        thread = threading.Thread(target=self._scan_all_symbols, daemon=True)
        thread.start()

    def stop_scan(self):
        """Stop the current scan."""
        self.shutting_down = True
        try:
            if self.current_executor is not None:
                self.current_executor.shutdown(wait=False, cancel_futures=True)
        except Exception:
            pass
        self.status_label.config(text="Scan stopped by user.")

    def run_single_ticker(self):
        """Run scan for a single ticker."""
        if not self.client_initialized:
            messagebox.showwarning("Not Ready", "Schwab API is not initialized yet.")
            return
            
        ticker = (self.single_ticker_var.get() or "").strip().upper()
        if not ticker:
            messagebox.showerror("Invalid Ticker", "Please enter a ticker symbol.")
            return

        self._set_symbol_list([ticker], f"Single ticker: {ticker}")
        self.apply_filters()

    def _scan_all_symbols(self):
        """Scan all symbols using Schwab API."""
        try:
            if self.shutting_down:
                return

            all_results = []
            total = len(self.all_symbols)
            errors = []
            chunk_size = 50  # Smaller chunks for real-time API
            
            # Use ThreadPoolExecutor with fewer workers (Schwab has rate limits)
            with ThreadPoolExecutor(max_workers=3) as executor:
                self.current_executor = executor
                
                for i in range(0, total, chunk_size):
                    if self.shutting_down:
                        break
                        
                    if i > 0:
                        print(f"Processed {i}/{total} symbols...")
                        time.sleep(1)  # Small delay between chunks

                    chunk_symbols = self.all_symbols[i:i + chunk_size]
                    retry_queue = list(chunk_symbols)
                    
                    while retry_queue and not self.shutting_down:
                        try:
                            future_to_symbol = {
                                executor.submit(self.fetch_forward_factor_data, symbol): symbol 
                                for symbol in retry_queue
                            }
                            
                            retry_queue = []
                            
                            for future in as_completed(future_to_symbol):
                                if self.shutting_down:
                                    break

                                symbol = future_to_symbol[future]
                                
                                try:
                                    results = future.result()
                                    if results:
                                        all_results.extend(results)
                                        print(f"+ {symbol}: Found {len(results)} results")
                                    else:
                                        print(f"- {symbol}: No results")
                                except Exception as e:
                                    error_msg = str(e).lower()
                                    if "rate" in error_msg or "limit" in error_msg:
                                        print(f"[Rate Limit] {symbol}: Retrying...")
                                        retry_queue.append(symbol)
                                    else:
                                        errors.append(f"{symbol}: {str(e)}")
                                        print(f"X {symbol}: {str(e)}")
                                
                                with self.progress_lock:
                                    self.processed_count += 1
                                    processed = self.processed_count
                                
                                if processed % 5 == 0 or processed == total:
                                    def update_progress(p=processed, t=total, c=len(all_results)):
                                        self.status_label.config(
                                            text=f"Scanning... {p}/{t} symbols. Found {c} results.")
                                        self.update_idletasks()
                                    self.after(0, update_progress)
                            
                            if retry_queue:
                                print(f"Waiting 30s before retrying {len(retry_queue)} symbols...")
                                time.sleep(30)
                                with self.progress_lock:
                                    self.processed_count -= len(retry_queue)
                                    
                        except Exception as e:
                            print(f"Chunk error: {e}")
                            break
                    
                    # Update table after each chunk
                    all_results.sort(key=lambda x: x.get("Fwd Factor", -float('inf')), reverse=True)
                    results_copy = list(all_results)
                    self.after(0, self._populate_table, results_copy)
                
                self.current_executor = None
            
            # Final update
            all_results.sort(key=lambda x: x.get("Fwd Factor", -float('inf')), reverse=True)
            
            if errors:
                error_summary = f"Completed. Found {len(all_results)} results. Errors: {len(errors)}"
            else:
                error_summary = f"Scan complete. Found {len(all_results)} results."
            
            self.filtered_results = all_results
            self.after(0, self._populate_table, all_results)
            self.after(0, lambda: self.status_label.config(text=error_summary))
            
        except Exception as e:
            error_msg = f"Critical error: {str(e)}"
            print(f"X {error_msg}")
            import traceback
            traceback.print_exc()
            self.after(0, self._show_error, error_msg)

    def _populate_table(self, data):
        """Updates the Treeview with new data."""
        for item in self.tree.get_children():
            self.tree.delete(item)
        
        for row in data:
            # Format Front Bid/Ask
            front_bid = row.get("Front Bid", float("nan"))
            front_ask = row.get("Front Ask", float("nan"))
            if not pd.isna(front_bid) and not pd.isna(front_ask):
                front_spread = front_ask - front_bid
                front_ba_str = f"{front_bid:.2f} / {front_ask:.2f} ({front_spread:.2f})"
            else:
                front_ba_str = "n/a"
            
            # Format Back Bid/Ask
            back_bid = row.get("Back Bid", float("nan"))
            back_ask = row.get("Back Ask", float("nan"))
            if not pd.isna(back_bid) and not pd.isna(back_ask):
                back_spread = back_ask - back_bid
                back_ba_str = f"{back_bid:.2f} / {back_ask:.2f} ({back_spread:.2f})"
            else:
                back_ba_str = "n/a"
            
            # Format R/R
            rr = row.get("R/R", float("nan"))
            rr_str = f"{rr:.2f}" if not pd.isna(rr) and not np.isinf(rr) else "n/a"
            
            # Format Stock Price
            stock_price = row.get("Stock Price", float("nan"))
            stock_price_str = f"{stock_price:.2f}" if not pd.isna(stock_price) else "n/a"
            
            # Format Cal Debit
            cal_debit = row.get("Cal Debit", float("nan"))
            cal_debit_str = f"{cal_debit:.2f}" if not pd.isna(cal_debit) else "n/a"
            
            # Format Earnings
            earnings_str = row.get("Earnings", "N/E")
            
            # Format FF
            ff = row.get("Fwd Factor", float("nan"))
            ff_str = f"{ff:.2f}" if not pd.isna(ff) else "n/a"
            
            self.tree.insert("", "end", values=(
                row["Ticker"],
                row["Expiry Pair"],
                row["Front DTE"],
                row["Back DTE"],
                f"{row['Front IV']:.2f}",
                f"{row['Back IV']:.2f}",
                f"{row['Fwd Vol']:.2f}",
                row.get("Front Vol", ""),
                row.get("Front OI", ""),
                stock_price_str,
                front_ba_str,
                back_ba_str,
                cal_debit_str,
                earnings_str,
                ff_str,
                rr_str,
            ))
        
        self.last_updated_label.config(text=f"Last Updated: {datetime.now().strftime('%H:%M:%S')}")
        self.status_label.config(text=f"Scan complete. Found {len(data)} results. Sorted by FF (descending).")

    def _show_error(self, error_message):
        """Displays an error in the status bar."""
        self.status_label.config(text=f"Error: {error_message}")
        self.last_updated_label.config(text="Last Updated: Failed")

    def fetch_forward_factor_data(self, ticker_symbol):
        """
        Fetch and calculate forward factor data for a single ticker using Schwab API.
        """
        target_days_pairs = [(30, 60), (60, 90), (30, 90)]
        
        # Get ticker data from Schwab
        ticker_data = self._get_ticker_data(ticker_symbol)
        
        current_price = ticker_data['current_price']
        expiry_dates = ticker_data['expiry_dates']
        call_exp_map = ticker_data['call_exp_map']

        results = []
        debug_reasons = []
        processed_dte_pairs = set()
        today = date.today()

        # Parse expiry dates and calculate DTEs
        expiry_info = []
        for exp_str in expiry_dates:
            try:
                # Schwab format: "2024-01-19:30" (date:DTE)
                parts = exp_str.split(':')
                exp_date = datetime.strptime(parts[0], '%Y-%m-%d').date()
                dte = (exp_date - today).days
                if dte > 0:
                    expiry_info.append((exp_str, exp_date, dte))
            except Exception:
                continue

        if not expiry_info:
            return []

        for dte1_target, dte2_target in target_days_pairs:
            try:
                # Find nearest expiries
                idx1 = min(range(len(expiry_info)), key=lambda i: abs(expiry_info[i][2] - dte1_target))
                idx2 = min(range(len(expiry_info)), key=lambda i: abs(expiry_info[i][2] - dte2_target))
                
                exp1_str, exp1_date, dte1 = expiry_info[idx1]
                exp2_str, exp2_date, dte2 = expiry_info[idx2]

                # Avoid duplicates
                if (dte1, dte2) in processed_dte_pairs:
                    continue
                processed_dte_pairs.add((dte1, dte2))

                if dte1 >= dte2 or dte1 < 0:
                    continue

                # Apply DTE filters
                if dte1 < self.min_front_dte or dte2 > self.max_back_dte:
                    continue

                # Get ATM option data for both expiries
                iv1, vol1, oi1, bid1, ask1, mid1 = self._get_atm_option_data(
                    call_exp_map, exp1_str, current_price
                )
                iv2, vol2, oi2, bid2, ask2, mid2 = self._get_atm_option_data(
                    call_exp_map, exp2_str, current_price
                )

                # Validate IV
                if iv1 <= 0 or iv2 <= 0 or pd.isna(iv1) or pd.isna(iv2):
                    continue

                # Apply volume/OI filters
                if vol1 < self.min_volume or oi1 < self.min_open_interest:
                    continue
                if vol2 < self.min_volume or oi2 < self.min_open_interest:
                    continue

                # Apply IV filter
                if (iv1 * 100.0) < self.min_iv or (iv2 * 100.0) < self.min_iv:
                    continue

                # Calendar pricing
                if bid1 <= 0 or ask2 <= 0 or mid1 <= 0 or mid2 <= 0:
                    continue

                cal_spread = ask2 - bid1
                cal_debit = mid2 - mid1

                # Apply calendar debit filter
                if cal_debit > self.max_cal_debit:
                    continue

                # Calculate forward vol and factor
                fwd_sigma, ff_ratio, fwd_var = self._calculate_forward_vol_and_factor(dte1, iv1, dte2, iv2)

                if fwd_sigma is None or np.isinf(ff_ratio) or pd.isna(ff_ratio):
                    continue

                # Apply Forward Factor filter
                if (ff_ratio * 100.0) < self.min_ff:
                    continue

                # Calculate R/R
                remaining_dte = dte2 - dte1
                if dte2 > 0 and remaining_dte > 0:
                    back_value_at_front_exp = mid2 * np.sqrt(remaining_dte / dte2)
                    max_profit = back_value_at_front_exp - cal_debit
                    reward_risk = max_profit / cal_debit if cal_debit > 0 and max_profit > 0 else float("nan")
                else:
                    reward_risk = float("nan")

                # Apply R/R filter
                if pd.isna(reward_risk) or reward_risk < self.min_rr:
                    continue

                # Earnings info (Schwab doesn't provide this directly, mark as N/E)
                earnings_info = "N/E"

                results.append({
                    "Ticker": ticker_symbol,
                    "Expiry Pair": f"{dte1_target}-{dte2_target}d",
                    "Front DTE": dte1,
                    "Back DTE": dte2,
                    "Front IV": iv1 * 100,
                    "Back IV": iv2 * 100,
                    "Fwd Vol": fwd_sigma * 100,
                    "Fwd Factor": ff_ratio * 100,
                    "Front Vol": vol1,
                    "Front OI": oi1,
                    "Stock Price": current_price,
                    "Earnings": earnings_info,
                    "Front Bid": bid1,
                    "Front Ask": ask1,
                    "Back Bid": bid2,
                    "Back Ask": ask2,
                    "Cal Spread": cal_spread,
                    "Cal Debit": cal_debit if cal_debit != float("inf") else float("nan"),
                    "R/R": reward_risk,
                })
            except Exception as e:
                debug_reasons.append(f"{dte1_target}-{dte2_target}d: {str(e)[:50]}")
                continue
        
        if not results and debug_reasons:
            print(f"  {ticker_symbol} debug: {debug_reasons[:3]}")
        
        return results

    def _get_atm_option_data(self, call_exp_map, exp_str, current_price):
        """
        Get ATM option data from Schwab option chain.
        Returns: (iv, volume, open_interest, bid, ask, mid)
        """
        strikes_map = call_exp_map.get(exp_str, {})
        
        if not strikes_map:
            raise Exception(f"No strikes for {exp_str}")
        
        # Find ATM strike
        strikes = sorted([float(s) for s in strikes_map.keys()])
        atm_strike = min(strikes, key=lambda s: abs(s - current_price))
        atm_strike_str = str(atm_strike)
        
        # Handle different key formats
        if atm_strike_str not in strikes_map:
            atm_strike_str = f"{atm_strike:.1f}"
        if atm_strike_str not in strikes_map:
            atm_strike_str = f"{int(atm_strike)}"
        if atm_strike_str not in strikes_map:
            # Try to find the closest key
            for key in strikes_map.keys():
                if abs(float(key) - atm_strike) < 0.01:
                    atm_strike_str = key
                    break
        
        options = strikes_map.get(atm_strike_str, [])
        if not options:
            raise Exception(f"No options at strike {atm_strike_str}")
        
        # Take first option (should be only one for a specific strike/expiry)
        opt = options[0] if isinstance(options, list) else options
        
        iv = opt.get('volatility', 0) / 100.0  # Schwab returns as percentage
        volume = int(opt.get('totalVolume', 0))
        oi = int(opt.get('openInterest', 0))
        bid = float(opt.get('bid', 0))
        ask = float(opt.get('ask', 0))
        
        # Fallback to mark/last if bid/ask not available
        if bid <= 0 or ask <= 0:
            mark = float(opt.get('mark', 0))
            last = float(opt.get('last', 0))
            if mark > 0:
                bid = ask = mark
            elif last > 0:
                bid = ask = last
        
        mid = (bid + ask) / 2.0 if bid > 0 and ask > 0 else 0.0
        
        return float(iv), volume, oi, bid, ask, mid

    def _calculate_forward_vol_and_factor(self, dte1, iv1, dte2, iv2):
        """Calculates forward volatility and forward factor."""
        if dte2 <= dte1:
            return None, None, -1

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
        import traceback
        traceback.print_exc()

