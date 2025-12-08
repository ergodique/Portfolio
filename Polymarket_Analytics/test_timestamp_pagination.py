"""
Test if Polymarket API supports timestamp-based pagination
"""

import requests
from datetime import datetime, timedelta

DATA_API_BASE = "https://data-api.polymarket.com"
WALLET = "0x6031b6eed1c97e853c6e0f03ad3ce3529351f96d"

def test_timestamp_params():
    """Test if API supports before/after timestamp parameters"""
    
    print("Testing timestamp-based pagination...")
    print("=" * 60)
    
    # Get first page
    r1 = requests.get(f"{DATA_API_BASE}/trades", params={
        "user": WALLET.lower(),
        "limit": 10,
        "offset": 0
    })
    data1 = r1.json()
    
    if not data1:
        print("No data returned")
        return
    
    # Get timestamp from last trade
    last_trade = data1[-1]
    last_timestamp = last_trade.get("timestamp")
    print(f"Last trade timestamp from first page: {last_timestamp}")
    
    # Try with before parameter
    print("\n1. Testing 'before' parameter...")
    r2 = requests.get(f"{DATA_API_BASE}/trades", params={
        "user": WALLET.lower(),
        "limit": 10,
        "before": last_timestamp
    })
    print(f"   Status: {r2.status_code}")
    if r2.status_code == 200:
        data2 = r2.json()
        print(f"   Got {len(data2)} trades")
        if data2:
            print(f"   First trade timestamp: {data2[0].get('timestamp')}")
            print(f"   Last trade timestamp: {data2[-1].get('timestamp')}")
    
    # Try with after parameter
    print("\n2. Testing 'after' parameter...")
    r3 = requests.get(f"{DATA_API_BASE}/trades", params={
        "user": WALLET.lower(),
        "limit": 10,
        "after": last_timestamp
    })
    print(f"   Status: {r3.status_code}")
    if r3.status_code == 200:
        data3 = r3.json()
        print(f"   Got {len(data3)} trades")
        if data3:
            print(f"   First trade timestamp: {data3[0].get('timestamp')}")
            print(f"   Last trade timestamp: {data3[-1].get('timestamp')}")
    
    # Try with start_time and end_time
    print("\n3. Testing 'start_time' and 'end_time' parameters...")
    end_time = datetime.now()
    start_time = end_time - timedelta(days=1)
    
    r4 = requests.get(f"{DATA_API_BASE}/trades", params={
        "user": WALLET.lower(),
        "limit": 10,
        "start_time": int(start_time.timestamp()),
        "end_time": int(end_time.timestamp())
    })
    print(f"   Status: {r4.status_code}")
    if r4.status_code == 200:
        data4 = r4.json()
        print(f"   Got {len(data4)} trades")
    
    # Check response headers for pagination info
    print("\n4. Checking response headers...")
    print(f"   Headers: {dict(r1.headers)}")

if __name__ == "__main__":
    test_timestamp_params()

