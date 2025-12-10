"""
Test CLOB API for trades with before/after timestamp pagination
This should bypass the Data-API offset limit of 1000
"""

import requests
from datetime import datetime, timedelta

CLOB_API_BASE = "https://clob.polymarket.com"
DATA_API_BASE = "https://data-api.polymarket.com"
WALLET = "0x6031b6eed1c97e853c6e0f03ad3ce3529351f96d"


def test_clob_trades():
    """Test CLOB API trades endpoint"""
    
    print("=" * 70)
    print("TESTING CLOB API TRADES ENDPOINT")
    print("=" * 70)
    
    # Test 1: Basic trades endpoint
    print("\n1. Testing basic CLOB trades endpoint...")
    
    endpoints_to_try = [
        f"{CLOB_API_BASE}/trades",
        f"{CLOB_API_BASE}/data/trades",
    ]
    
    for endpoint in endpoints_to_try:
        print(f"\n   Trying: {endpoint}")
        try:
            r = requests.get(endpoint, params={
                "taker": WALLET.lower(),
                "limit": 10,
            }, timeout=10)
            print(f"   Status: {r.status_code}")
            if r.status_code == 200:
                data = r.json()
                print(f"   Got {len(data) if isinstance(data, list) else 'unknown'} trades")
                if data and isinstance(data, list):
                    print(f"   First trade keys: {list(data[0].keys())[:10]}")
                    # Check for timestamp field
                    ts_field = None
                    for key in ['timestamp', 'created_at', 'matchTime', 'time']:
                        if key in data[0]:
                            ts_field = key
                            print(f"   Timestamp field: {ts_field} = {data[0][ts_field]}")
                            break
        except Exception as e:
            print(f"   Error: {e}")
    
    # Test 2: Try with maker parameter
    print("\n2. Testing with 'maker' parameter...")
    try:
        r = requests.get(f"{CLOB_API_BASE}/trades", params={
            "maker": WALLET.lower(),
            "limit": 10,
        }, timeout=10)
        print(f"   Status: {r.status_code}")
        if r.status_code == 200:
            data = r.json()
            print(f"   Got {len(data) if isinstance(data, list) else 'unknown'} trades")
    except Exception as e:
        print(f"   Error: {e}")
    
    # Test 3: Test before/after parameters
    print("\n3. Testing 'before' and 'after' parameters...")
    
    # First get some trades to get timestamps
    try:
        r = requests.get(f"{CLOB_API_BASE}/trades", params={
            "taker": WALLET.lower(),
            "limit": 10,
        }, timeout=10)
        
        if r.status_code == 200:
            data = r.json()
            if data and isinstance(data, list):
                # Get timestamp from last trade
                last_trade = data[-1]
                ts_field = None
                for key in ['timestamp', 'created_at', 'matchTime', 'time']:
                    if key in last_trade:
                        ts_field = key
                        break
                
                if ts_field:
                    last_ts = last_trade[ts_field]
                    print(f"   Last timestamp: {last_ts}")
                    
                    # Try fetching older trades with 'before'
                    print("\n   3a. Testing 'before' parameter...")
                    r2 = requests.get(f"{CLOB_API_BASE}/trades", params={
                        "taker": WALLET.lower(),
                        "before": last_ts,
                        "limit": 10,
                    }, timeout=10)
                    print(f"   Status: {r2.status_code}")
                    if r2.status_code == 200:
                        data2 = r2.json()
                        print(f"   Got {len(data2) if isinstance(data2, list) else 'unknown'} trades")
                        if data2 and isinstance(data2, list):
                            # Check if we got different trades
                            ids1 = set(str(t) for t in data[:5])
                            ids2 = set(str(t) for t in data2[:5])
                            overlap = ids1 & ids2
                            print(f"   Overlap check: {len(overlap)} overlapping entries")
                            if len(overlap) == 0:
                                print("   SUCCESS: 'before' parameter works!")
                            
                            # Check timestamps
                            if ts_field in data2[0]:
                                print(f"   First trade timestamp: {data2[0][ts_field]}")
                                print(f"   Last trade timestamp: {data2[-1][ts_field]}")
    except Exception as e:
        print(f"   Error: {e}")
    
    # Test 4: Check user activity endpoint
    print("\n4. Testing user activity endpoint...")
    
    activity_endpoints = [
        f"{DATA_API_BASE}/activity",
        f"{CLOB_API_BASE}/activity",
        f"{DATA_API_BASE}/history",
    ]
    
    for endpoint in activity_endpoints:
        print(f"\n   Trying: {endpoint}")
        try:
            r = requests.get(endpoint, params={
                "user": WALLET.lower(),
                "limit": 10,
            }, timeout=10)
            print(f"   Status: {r.status_code}")
            if r.status_code == 200:
                data = r.json()
                print(f"   Got data type: {type(data)}")
                if isinstance(data, list):
                    print(f"   Items: {len(data)}")
                elif isinstance(data, dict):
                    print(f"   Keys: {list(data.keys())}")
        except Exception as e:
            print(f"   Error: {e}")
    
    # Test 5: Check if Data API really ignores before/after
    print("\n5. Double-checking Data API before/after behavior...")
    try:
        # Get first page
        r1 = requests.get(f"{DATA_API_BASE}/trades", params={
            "user": WALLET.lower(),
            "limit": 10,
            "offset": 0
        }, timeout=10)
        
        if r1.status_code == 200:
            data1 = r1.json()
            if data1:
                last_ts = data1[-1].get("timestamp")
                print(f"   First page last timestamp: {last_ts}")
                
                # Try with before
                r2 = requests.get(f"{DATA_API_BASE}/trades", params={
                    "user": WALLET.lower(),
                    "limit": 10,
                    "before": last_ts
                }, timeout=10)
                
                if r2.status_code == 200:
                    data2 = r2.json()
                    print(f"   With 'before' parameter: got {len(data2)} trades")
                    if data2:
                        print(f"   New first timestamp: {data2[0].get('timestamp')}")
                        print(f"   New last timestamp: {data2[-1].get('timestamp')}")
                        
                        # Check overlap
                        hash1 = set(t.get('transactionHash') for t in data1)
                        hash2 = set(t.get('transactionHash') for t in data2)
                        overlap = hash1 & hash2
                        print(f"   Overlap: {len(overlap)} trades")
                        
                        if len(overlap) == len(hash1):
                            print("   CONFIRMED: Data API ignores 'before' parameter")
                        else:
                            print("   INTERESTING: Data API might support 'before' now!")
    except Exception as e:
        print(f"   Error: {e}")
    
    # Test 6: Try Data API with Unix timestamp format
    print("\n6. Testing Data API with Unix timestamp format...")
    try:
        now = int(datetime.now().timestamp())
        one_hour_ago = now - 3600
        
        params_to_try = [
            {"user": WALLET.lower(), "limit": 10, "before": one_hour_ago},
            {"user": WALLET.lower(), "limit": 10, "after": one_hour_ago},
            {"user": WALLET.lower(), "limit": 10, "startTs": one_hour_ago},
            {"user": WALLET.lower(), "limit": 10, "endTs": now},
        ]
        
        for params in params_to_try:
            extra_param = [k for k in params.keys() if k not in ['user', 'limit']][0]
            r = requests.get(f"{DATA_API_BASE}/trades", params=params, timeout=10)
            if r.status_code == 200:
                data = r.json()
                if data:
                    print(f"   {extra_param}={params[extra_param]}: got {len(data)} trades, "
                          f"first ts: {data[0].get('timestamp')[:16] if data[0].get('timestamp') else 'N/A'}")
    except Exception as e:
        print(f"   Error: {e}")


if __name__ == "__main__":
    test_clob_trades()
