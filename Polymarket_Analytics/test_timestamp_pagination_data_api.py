"""
Test timestamp-based pagination for Polymarket Data API
"""

import requests
from datetime import datetime

DATA_API_BASE = "https://data-api.polymarket.com"
WALLET = "0x6031b6eed1c97e853c6e0f03ad3ce3529351f96d"

def test_timestamp_pagination():
    """Test if data-api supports before/after timestamp parameters"""
    
    print("Testing timestamp-based pagination for Data API...")
    print("=" * 60)
    
    # Get first page
    print("\n1. Fetching first page (offset=0, limit=10)...")
    r1 = requests.get(f"{DATA_API_BASE}/trades", params={
        "user": WALLET.lower(),
        "limit": 10,
        "offset": 0
    })
    data1 = r1.json()
    
    if not data1:
        print("No data returned")
        return
    
    print(f"   Got {len(data1)} trades")
    first_timestamp = data1[0].get("timestamp")
    last_timestamp = data1[-1].get("timestamp")
    print(f"   First trade timestamp: {first_timestamp}")
    print(f"   Last trade timestamp: {last_timestamp}")
    
    # Try with 'before' parameter (should get older trades)
    print(f"\n2. Testing 'before' parameter with timestamp {last_timestamp}...")
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
            
            # Check if we got different trades
            hashes1 = {t.get("transactionHash") for t in data1}
            hashes2 = {t.get("transactionHash") for t in data2}
            overlap = hashes1 & hashes2
            print(f"   Overlap with first page: {len(overlap)} trades")
            if len(overlap) == 0:
                print("   SUCCESS: 'before' parameter works! Got different trades.")
            else:
                print(f"   WARNING: {len(overlap)} trades overlap with first page")
    
    # Try with 'after' parameter (should get newer trades)
    print(f"\n3. Testing 'after' parameter with timestamp {first_timestamp}...")
    r3 = requests.get(f"{DATA_API_BASE}/trades", params={
        "user": WALLET.lower(),
        "limit": 10,
        "after": first_timestamp
    })
    print(f"   Status: {r3.status_code}")
    if r3.status_code == 200:
        data3 = r3.json()
        print(f"   Got {len(data3)} trades")
        if data3:
            print(f"   First trade timestamp: {data3[0].get('timestamp')}")
            print(f"   Last trade timestamp: {data3[-1].get('timestamp')}")
    
    # Try with 'start_time' and 'end_time' (Unix timestamp)
    print(f"\n4. Testing 'start_time' and 'end_time' parameters...")
    end_time = int(datetime.now().timestamp())
    start_time = end_time - 86400  # 1 day ago
    
    r4 = requests.get(f"{DATA_API_BASE}/trades", params={
        "user": WALLET.lower(),
        "limit": 10,
        "start_time": start_time,
        "end_time": end_time
    })
    print(f"   Status: {r4.status_code}")
    if r4.status_code == 200:
        data4 = r4.json()
        print(f"   Got {len(data4)} trades")
        if data4:
            print(f"   First trade timestamp: {data4[0].get('timestamp')}")
            print(f"   Last trade timestamp: {data4[-1].get('timestamp')}")
    
    # Try with 'from' and 'to' parameters
    print(f"\n5. Testing 'from' and 'to' parameters...")
    r5 = requests.get(f"{DATA_API_BASE}/trades", params={
        "user": WALLET.lower(),
        "limit": 10,
        "from": start_time,
        "to": end_time
    })
    print(f"   Status: {r5.status_code}")
    if r5.status_code == 200:
        data5 = r5.json()
        print(f"   Got {len(data5)} trades")
    
    # Try pagination with before - simulate getting multiple pages
    if r2.status_code == 200 and data2 and len(overlap) == 0:
        print(f"\n6. Simulating pagination with 'before' parameter...")
        current_before = last_timestamp
        all_trades = []
        page = 0
        
        while page < 5:  # Get 5 pages
            r = requests.get(f"{DATA_API_BASE}/trades", params={
                "user": WALLET.lower(),
                "limit": 10,
                "before": current_before
            })
            
            if r.status_code != 200:
                print(f"   Error at page {page}: {r.status_code}")
                break
            
            page_data = r.json()
            if not page_data:
                print(f"   No more data at page {page}")
                break
            
            all_trades.extend(page_data)
            current_before = page_data[-1].get("timestamp")
            
            print(f"   Page {page + 1}: Got {len(page_data)} trades, last timestamp: {current_before}")
            page += 1
        
        print(f"\n   Total trades collected: {len(all_trades)}")
        unique_hashes = len({t.get("transactionHash") for t in all_trades})
        print(f"   Unique transaction hashes: {unique_hashes}")

if __name__ == "__main__":
    test_timestamp_pagination()

