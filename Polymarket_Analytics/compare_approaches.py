"""
Compare standard approach vs market-by-market approach
"""
import pandas as pd
from datetime import datetime, timedelta
import time

from polymarket_client import PolymarketClient

WALLET = "0x6031b6eed1c97e853c6e0f03ad3ce3529351f96d"

def compare_approaches():
    client = PolymarketClient()
    
    end_date = datetime.now()
    start_date = end_date - timedelta(days=7)
    
    print("=" * 70)
    print("COMPARING STANDARD vs MARKET-BY-MARKET APPROACH")
    print("=" * 70)
    print(f"Wallet: {WALLET}")
    print(f"Date range: {start_date.date()} to {end_date.date()}")
    
    # Standard approach
    print("\n1. Standard Approach (offset-based)...")
    start_time = time.time()
    trades_standard = client.get_user_trades(
        WALLET,
        start_date=start_date,
        end_date=end_date,
        parallel=1,
        use_market_approach=False
    )
    time_standard = time.time() - start_time
    print(f"   Got {len(trades_standard)} trades in {time_standard:.2f}s")
    
    # Market-by-market approach  
    print("\n2. Market-by-Market Approach...")
    start_time = time.time()
    trades_market = client.get_user_trades(
        WALLET,
        start_date=start_date,
        end_date=end_date,
        parallel=1,
        use_market_approach=True
    )
    time_market = time.time() - start_time
    print(f"   Got {len(trades_market)} trades in {time_market:.2f}s")
    
    # Analysis
    print("\n" + "=" * 70)
    print("ANALYSIS")
    print("=" * 70)
    
    # Get unique transaction hashes
    hashes_standard = set(t.get("transactionHash") for t in trades_standard)
    hashes_market = set(t.get("transactionHash") for t in trades_market)
    
    print(f"\nStandard approach:")
    print(f"   Total trades: {len(trades_standard)}")
    print(f"   Unique tx hashes: {len(hashes_standard)}")
    if trades_standard:
        timestamps = [t.get("timestamp") for t in trades_standard if t.get("timestamp")]
        if timestamps:
            print(f"   Date range: {min(timestamps)} to {max(timestamps)}")
    
    print(f"\nMarket-by-market approach:")
    print(f"   Total trades: {len(trades_market)}")
    print(f"   Unique tx hashes: {len(hashes_market)}")
    if trades_market:
        timestamps = [t.get("timestamp") for t in trades_market if t.get("timestamp")]
        if timestamps:
            print(f"   Date range: {min(timestamps)} to {max(timestamps)}")
    
    # Overlap analysis
    common_hashes = hashes_standard & hashes_market
    only_standard = hashes_standard - hashes_market
    only_market = hashes_market - hashes_standard
    
    print(f"\nOverlap analysis:")
    print(f"   Common tx hashes: {len(common_hashes)}")
    print(f"   Only in standard: {len(only_standard)}")
    print(f"   Only in market approach: {len(only_market)}")
    
    if only_market:
        print(f"\n   Market approach found {len(only_market)} additional unique transactions!")
        print(f"   These were likely beyond the offset limit in standard approach.")
    
    # Performance comparison
    print(f"\nPerformance:")
    print(f"   Standard: {time_standard:.2f}s")
    print(f"   Market-by-market: {time_market:.2f}s")


if __name__ == "__main__":
    compare_approaches()
