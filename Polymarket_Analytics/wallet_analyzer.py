"""
Polymarket Wallet Trade Analyzer
Fetches trade history for a wallet and saves to parquet file.
Supports graceful interruption with Ctrl+C - saves partial data.
"""

import argparse
import signal
import sys
import time
from datetime import datetime, timedelta
from pathlib import Path

import pandas as pd

from polymarket_client import PolymarketClient


_partial_trades = []
_output_path = None
_wallet_address = None


def process_trades_to_df(trades: list, wallet_address: str) -> pd.DataFrame:
    """Convert raw trades to DataFrame."""
    if not trades:
        return pd.DataFrame()
    
    records = []
    
    for trade in trades:
        timestamp = trade.get("timestamp")
        if isinstance(timestamp, str):
            try:
                timestamp = pd.to_datetime(timestamp)
            except Exception:
                timestamp = None
        elif isinstance(timestamp, (int, float)):
            if timestamp > 1e12:
                timestamp = timestamp / 1000
            timestamp = pd.to_datetime(timestamp, unit='s')
        
        side = trade.get("side", "")
        if isinstance(side, str):
            side = side.upper()
        
        outcome = trade.get("outcome", "")
        condition_id = trade.get("conditionId", "")
        
        size = trade.get("size", 0)
        amount = float(size) if size else 0.0
        
        price_val = trade.get("price", 0)
        price = float(price_val) if price_val else 0.0
        
        record = {
            "timestamp": timestamp,
            "trader": trade.get("proxyWallet", wallet_address).lower(),
            "side": side,
            "market_slug": trade.get("slug", ""),
            "event_slug": trade.get("eventSlug", ""),
            "market_question": trade.get("title", ""),
            "outcome": outcome,
            "outcome_index": trade.get("outcomeIndex", ""),
            "amount": amount,
            "price": price,
            "pnl": 0.0,
            "market_resolved": False,
            "winning_outcome": "",
            "condition_id": condition_id,
            "asset": trade.get("asset", ""),
            "transaction_hash": trade.get("transactionHash", ""),
        }
        
        records.append(record)
    
    df = pd.DataFrame(records)
    
    if not df.empty and "timestamp" in df.columns:
        df = df.sort_values("timestamp", ascending=False)
    
    return df


def save_to_parquet(df: pd.DataFrame, output_path: str):
    """Save DataFrame to parquet file."""
    if df.empty:
        print("No data to save.")
        return
    
    path = Path(output_path)
    data_dir = Path("Data")
    data_dir.mkdir(exist_ok=True)
    
    if path.is_absolute():
        final_path = data_dir / path.name
    else:
        final_path = data_dir / path.name
    
    df.to_parquet(final_path, index=False, engine="pyarrow")
    print(f"Saved {len(df)} records to {final_path}")


def handle_interrupt(signum, frame):
    """Handle Ctrl+C - save partial data and exit."""
    global _partial_trades, _output_path, _wallet_address
    
    print("\n\n[!] Interrupted! Saving partial data...")
    
    if _partial_trades and _output_path and _wallet_address:
        df = process_trades_to_df(_partial_trades, _wallet_address)
        if not df.empty:
            partial_output = _output_path.replace(".parquet", "_partial.parquet")
            save_to_parquet(df, partial_output)
            print(f"Partial data saved to: {partial_output}")
    else:
        print("No data collected yet.")
    
    sys.exit(0)


def fetch_and_process_trades(
    client: PolymarketClient,
    wallet_address: str,
    days: int = 30,
    parallel: int = 1,
    fetch_market_info: bool = False
) -> pd.DataFrame:
    """
    Fetch trades for a wallet and process into a DataFrame.
    
    Args:
        client: PolymarketClient instance
        wallet_address: Ethereum wallet address
        days: Number of days of history to fetch
        parallel: Number of parallel requests (1=sync, >1=async)
        fetch_market_info: Whether to fetch additional market info (slower)
    
    Returns:
        DataFrame with processed trade data
    """
    global _partial_trades, _wallet_address
    _wallet_address = wallet_address
    
    end_date = datetime.now()
    start_date = end_date - timedelta(days=days)
    
    fetch_start = time.time()
    
    def on_trades_received(trades):
        global _partial_trades
        _partial_trades = trades
    
    trades = client.get_user_trades(
        wallet_address,
        start_date=start_date,
        end_date=end_date,
        parallel=parallel,
        on_progress=on_trades_received
    )
    
    _partial_trades = trades
    
    fetch_time = time.time() - fetch_start
    print(f"Fetch completed in {fetch_time:.2f} seconds")
    
    if not trades:
        print("No trades found for this wallet in the specified period.")
        return pd.DataFrame()
    
    print(f"Processing {len(trades)} trades...")
    process_start = time.time()
    
    df = process_trades_to_df(trades, wallet_address)
    
    if fetch_market_info and not df.empty:
        print("Fetching market info...")
        market_cache = {}
        
        for i, (idx, row) in enumerate(df.iterrows()):
            if (i + 1) % 100 == 0:
                print(f"Fetching market info {i + 1}/{len(df)}...")
            
            condition_id = row.get("condition_id", "")
            if condition_id and condition_id not in market_cache:
                market_info = client.get_market_info(condition_id)
                market_cache[condition_id] = market_info
            else:
                market_info = market_cache.get(condition_id, {})
            
            if market_info:
                market_resolved = market_info.get("resolved", False)
                if isinstance(market_resolved, str):
                    market_resolved = market_resolved.lower() == "true"
                
                df.at[idx, "market_resolved"] = market_resolved
                
                if market_resolved:
                    winning_outcome = market_info.get("outcome", "")
                    if not winning_outcome:
                        outcomes = market_info.get("outcomes", [])
                        if outcomes:
                            for out in outcomes:
                                if out.get("winner", False):
                                    winning_outcome = out.get("name", "")
                                    break
                    df.at[idx, "winning_outcome"] = winning_outcome
    
    process_time = time.time() - process_start
    print(f"Processing completed in {process_time:.2f} seconds")
    
    return df


def main():
    global _output_path
    
    signal.signal(signal.SIGINT, handle_interrupt)
    
    parser = argparse.ArgumentParser(
        description="Fetch Polymarket trade history for a wallet address"
    )
    parser.add_argument(
        "wallet_address",
        type=str,
        help="Ethereum wallet address to analyze"
    )
    parser.add_argument(
        "-d", "--days",
        type=int,
        default=None,
        help="Number of days of history to fetch"
    )
    parser.add_argument(
        "-m", "--months",
        type=int,
        default=None,
        help="Number of months of history to fetch"
    )
    parser.add_argument(
        "-o", "--output",
        type=str,
        default=None,
        help="Output parquet file path (default: trades_<wallet>.parquet)"
    )
    parser.add_argument(
        "-p", "--parallel",
        type=int,
        default=1,
        help="Number of parallel requests (1=sync, 5-10 recommended for speed)"
    )
    parser.add_argument(
        "--fetch-market-info",
        action="store_true",
        help="Fetch additional market info (resolved status, winning outcome) - slower"
    )
    
    args = parser.parse_args()
    
    wallet = args.wallet_address.strip()
    if not wallet.startswith("0x"):
        print("Error: Wallet address must start with 0x", file=sys.stderr)
        sys.exit(1)
    
    if args.days is not None:
        days = args.days
        period_str = f"{days} day(s)"
    elif args.months is not None:
        days = args.months * 30
        period_str = f"{args.months} month(s)"
    else:
        days = 30
        period_str = "30 days (default)"
    
    data_dir = Path("Data")
    data_dir.mkdir(exist_ok=True)
    
    if args.output:
        output_path = args.output
        path = Path(output_path)
        if path.is_absolute():
            output_path = str(data_dir / path.name)
        else:
            output_path = str(data_dir / path.name)
    else:
        short_wallet = wallet[:10]
        output_path = str(data_dir / f"trades_{short_wallet}.parquet")
    
    _output_path = output_path
    
    print(f"Polymarket Wallet Analyzer")
    print(f"{'=' * 50}")
    print(f"Wallet: {wallet}")
    print(f"Period: Last {period_str}")
    print(f"Output: {output_path}")
    print(f"Parallel: {args.parallel} {'(async)' if args.parallel > 1 else '(sync)'}")
    print(f"Fetch market info: {args.fetch_market_info}")
    print(f"[Ctrl+C to stop and save partial data]")
    print(f"{'=' * 50}")
    
    total_start = time.time()
    
    client = PolymarketClient()
    
    try:
        df = fetch_and_process_trades(
            client,
            wallet,
            days=days,
            parallel=args.parallel,
            fetch_market_info=args.fetch_market_info
        )
    except KeyboardInterrupt:
        handle_interrupt(None, None)
        return
    
    if df.empty:
        print("No data to save.")
        sys.exit(0)
    
    print(f"\nDataFrame Summary:")
    print(f"  Total trades: {len(df)}")
    if "timestamp" in df.columns and not df["timestamp"].isna().all():
        print(f"  Date range: {df['timestamp'].min()} to {df['timestamp'].max()}")
    if "pnl" in df.columns:
        total_pnl = df["pnl"].sum()
        print(f"  Total PnL: ${total_pnl:.2f}")
    if "market_question" in df.columns:
        unique_markets = df["market_question"].nunique()
        print(f"  Unique markets: {unique_markets}")
    
    save_to_parquet(df, output_path)
    
    total_time = time.time() - total_start
    print(f"\nTotal execution time: {total_time:.2f} seconds")
    
    print("\nFirst 5 trades:")
    pd.set_option('display.max_columns', None)
    pd.set_option('display.width', None)
    print(df[["timestamp", "side", "market_question", "outcome", "amount", "price"]].head().to_string())


if __name__ == "__main__":
    main()
