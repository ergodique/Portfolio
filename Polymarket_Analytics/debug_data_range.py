"""
Debug: Why can't we get 3 days of data?
Analyze the issue with market-by-market approach
"""

import requests
from datetime import datetime, timedelta

DATA_API_BASE = "https://data-api.polymarket.com"
WALLET = "0x6031b6eed1c97e853c6e0f03ad3ce3529351f96d"


def debug_data_range():
    """Analyze why we can't get 3 days of data"""
    
    print("=" * 70)
    print("DEBUG: Why can't we get 3 days of data?")
    print("=" * 70)
    
    # Test 1: What does the API return for different offsets?
    print("\n1. Testing offset behavior to understand data distribution...")
    
    for offset in [0, 500, 1000]:
        r = requests.get(f"{DATA_API_BASE}/trades", params={
            "user": WALLET.lower(),
            "limit": 10,
            "offset": offset,
        }, timeout=10)
        
        if r.status_code == 200:
            data = r.json()
            if data:
                first_ts = data[0].get("timestamp")
                last_ts = data[-1].get("timestamp")
                
                # Convert to datetime
                if first_ts:
                    if isinstance(first_ts, (int, float)):
                        if first_ts > 1e12:
                            first_ts = first_ts / 1000
                        first_dt = datetime.fromtimestamp(first_ts)
                    else:
                        first_dt = first_ts
                else:
                    first_dt = "N/A"
                    
                if last_ts:
                    if isinstance(last_ts, (int, float)):
                        if last_ts > 1e12:
                            last_ts = last_ts / 1000
                        last_dt = datetime.fromtimestamp(last_ts)
                    else:
                        last_dt = last_ts
                else:
                    last_dt = "N/A"
                
                print(f"   offset={offset}: first={first_dt}, last={last_dt}")
    
    # Test 2: Check positions - how many and what are they?
    print("\n2. Analyzing user positions...")
    r = requests.get(f"{DATA_API_BASE}/positions", params={
        "user": WALLET.lower(),
        "limit": 500,
    }, timeout=10)
    
    if r.status_code == 200:
        positions = r.json()
        print(f"   Total positions: {len(positions)}")
        
        if positions:
            # Check position sizes
            active_positions = [p for p in positions if float(p.get("size", 0)) > 0]
            zero_positions = [p for p in positions if float(p.get("size", 0)) == 0]
            print(f"   Active positions (size > 0): {len(active_positions)}")
            print(f"   Closed positions (size = 0): {len(zero_positions)}")
            
            # Get unique condition IDs
            condition_ids = set(p.get("conditionId") for p in positions)
            print(f"   Unique condition IDs: {len(condition_ids)}")
            
            # Check timestamps
            print("\n   Position details:")
            for i, pos in enumerate(positions[:5]):
                print(f"   {i+1}. Market: {pos.get('slug', 'N/A')[:40]}...")
                print(f"      Size: {pos.get('size', 0)}, Condition ID: {pos.get('conditionId', 'N/A')[:20]}...")
    
    # Test 3: Check activity endpoint
    print("\n3. Checking activity endpoint for older data...")
    
    r = requests.get(f"{DATA_API_BASE}/activity", params={
        "user": WALLET.lower(),
        "limit": 10,
        "offset": 1000,  # Try to get data beyond offset limit
    }, timeout=10)
    
    if r.status_code == 200:
        data = r.json()
        if data:
            print(f"   Activity at offset 1000: {len(data)} items")
            first_ts = data[0].get("timestamp")
            last_ts = data[-1].get("timestamp")
            print(f"   First: {first_ts}, Last: {last_ts}")
    
    # Test 4: What trades exist for specific markets?
    print("\n4. Testing trades per market...")
    
    if positions:
        for pos in positions[:3]:
            condition_id = pos.get("conditionId")
            slug = pos.get("slug", "unknown")[:30]
            
            # Get all trades for this market
            r = requests.get(f"{DATA_API_BASE}/trades", params={
                "user": WALLET.lower(),
                "market": condition_id,
                "limit": 500,
            }, timeout=10)
            
            if r.status_code == 200:
                trades = r.json()
                if trades:
                    first_ts = trades[0].get("timestamp")
                    last_ts = trades[-1].get("timestamp")
                    
                    if isinstance(first_ts, (int, float)):
                        if first_ts > 1e12:
                            first_ts = first_ts / 1000
                        first_dt = datetime.fromtimestamp(first_ts)
                    else:
                        first_dt = first_ts
                    
                    if isinstance(last_ts, (int, float)):
                        if last_ts > 1e12:
                            last_ts = last_ts / 1000
                        last_dt = datetime.fromtimestamp(last_ts)
                    else:
                        last_dt = last_ts
                    
                    print(f"   {slug}...: {len(trades)} trades, range: {last_dt} to {first_dt}")
    
    # Test 5: Check if user has trades before Dec 7
    print("\n5. Searching for older trades...")
    
    # Get the oldest trade from current data
    r = requests.get(f"{DATA_API_BASE}/trades", params={
        "user": WALLET.lower(),
        "limit": 500,
        "offset": 1000,  # Max offset
    }, timeout=10)
    
    if r.status_code == 200:
        data = r.json()
        if data:
            # Find oldest timestamp
            oldest_ts = min(t.get("timestamp", float('inf')) for t in data if t.get("timestamp"))
            if isinstance(oldest_ts, (int, float)):
                if oldest_ts > 1e12:
                    oldest_ts = oldest_ts / 1000
                oldest_dt = datetime.fromtimestamp(oldest_ts)
                print(f"   Oldest trade accessible: {oldest_dt}")
            
            # Check what percentage of trades are from each day
            day_counts = {}
            for t in data:
                ts = t.get("timestamp")
                if ts:
                    if isinstance(ts, (int, float)):
                        if ts > 1e12:
                            ts = ts / 1000
                        dt = datetime.fromtimestamp(ts)
                        day = dt.date()
                        day_counts[day] = day_counts.get(day, 0) + 1
            
            print(f"   Trades per day at offset=1000:")
            for day in sorted(day_counts.keys()):
                print(f"      {day}: {day_counts[day]} trades")
    
    # Test 6: Total trade count estimation
    print("\n6. Estimating total user trades...")
    
    # The user might have thousands of trades, but API only allows 1500
    r = requests.get(f"{DATA_API_BASE}/trades", params={
        "user": WALLET.lower(),
        "limit": 1,
    }, timeout=10)
    
    if r.status_code == 200:
        # Check response headers for total count
        print(f"   Response headers: {dict(r.headers)}")


if __name__ == "__main__":
    debug_data_range()
