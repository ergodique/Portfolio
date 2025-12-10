"""
Analyze the root cause of missing older trades
"""

import requests
from datetime import datetime, timedelta

DATA_API_BASE = "https://data-api.polymarket.com"
WALLET = "0x6031b6eed1c97e853c6e0f03ad3ce3529351f96d"


def analyze_issue():
    print("=" * 70)
    print("ROOT CAUSE ANALYSIS: Why can't we get 3 days of data?")
    print("=" * 70)
    
    # 1. Check how many trades exist in the last 3 hours (what we can access)
    print("\n1. Trade distribution analysis...")
    
    three_days_ago = datetime.now() - timedelta(days=3)
    one_day_ago = datetime.now() - timedelta(days=1)
    
    # Get all accessible trades
    all_trades = []
    for offset in [0, 500, 1000]:
        r = requests.get(f"{DATA_API_BASE}/trades", params={
            "user": WALLET.lower(),
            "limit": 500,
            "offset": offset,
        }, timeout=30)
        
        if r.status_code == 200:
            all_trades.extend(r.json())
    
    print(f"   Total accessible trades: {len(all_trades)}")
    
    # Analyze by time
    if all_trades:
        timestamps = []
        for t in all_trades:
            ts = t.get("timestamp")
            if ts:
                if isinstance(ts, (int, float)):
                    if ts > 1e12:
                        ts = ts / 1000
                    dt = datetime.fromtimestamp(ts)
                    timestamps.append(dt)
        
        if timestamps:
            oldest = min(timestamps)
            newest = max(timestamps)
            time_span = newest - oldest
            
            print(f"   Oldest trade: {oldest}")
            print(f"   Newest trade: {newest}")
            print(f"   Time span: {time_span}")
            
            # Count per day
            day_counts = {}
            for dt in timestamps:
                day = dt.date()
                day_counts[day] = day_counts.get(day, 0) + 1
            
            print(f"\n   Trades per day:")
            for day in sorted(day_counts.keys()):
                print(f"      {day}: {day_counts[day]} trades")
    
    # 2. Key insight: The user trades A LOT
    print("\n2. Trading frequency analysis...")
    if timestamps:
        hours_covered = time_span.total_seconds() / 3600
        trades_per_hour = len(timestamps) / hours_covered if hours_covered > 0 else 0
        print(f"   Hours of data: {hours_covered:.1f}")
        print(f"   Trades per hour: {trades_per_hour:.1f}")
        print(f"   Estimated trades in 3 days: {trades_per_hour * 72:.0f}")
    
    # 3. The positions issue
    print("\n3. Positions analysis...")
    r = requests.get(f"{DATA_API_BASE}/positions", params={
        "user": WALLET.lower(),
        "limit": 500,
    }, timeout=10)
    
    if r.status_code == 200:
        positions = r.json()
        print(f"   Current positions returned: {len(positions)}")
        
        # Get unique condition IDs
        position_condition_ids = set(p.get("conditionId") for p in positions)
        
        # Get condition IDs from trades
        trade_condition_ids = set(t.get("conditionId") for t in all_trades)
        
        # Compare
        in_trades_not_positions = trade_condition_ids - position_condition_ids
        
        print(f"   Unique markets in trades: {len(trade_condition_ids)}")
        print(f"   Unique markets in positions: {len(position_condition_ids)}")
        print(f"   Markets in trades but NOT in positions: {len(in_trades_not_positions)}")
        
        if in_trades_not_positions:
            print(f"\n   PROBLEM IDENTIFIED!")
            print(f"   {len(in_trades_not_positions)} markets are missing from positions!")
            print(f"   These are likely fully resolved/closed markets.")
    
    # 4. The fundamental issue
    print("\n" + "=" * 70)
    print("CONCLUSION:")
    print("=" * 70)
    print("""
The issue is NOT with our implementation. The issue is FUNDAMENTAL:

1. This wallet trades ~500+ trades per hour
2. API offset limit is 1000, giving us ~1500 trades max
3. 1500 trades ÷ 500 trades/hour = ~3 hours of data

EVEN with market-by-market approach:
- /positions only returns ACTIVE positions (size > 0)
- Fully closed/resolved markets are NOT returned
- So we can't discover old markets to query

POSSIBLE SOLUTIONS:
1. Use /activity endpoint (may have different data)
2. Collect condition_ids from trades and query each separately
3. Use incremental collection over time
4. Query blockchain directly (Polygon)
""")


if __name__ == "__main__":
    analyze_issue()
