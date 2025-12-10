"""
Test Data API /activity endpoint for pagination
This might bypass the offset limit
"""

import requests
from datetime import datetime

DATA_API_BASE = "https://data-api.polymarket.com"
WALLET = "0x6031b6eed1c97e853c6e0f03ad3ce3529351f96d"


def test_activity_endpoint():
    """Test activity endpoint pagination"""
    
    print("=" * 70)
    print("TESTING DATA API /ACTIVITY ENDPOINT")
    print("=" * 70)
    
    # Test 1: Get initial data and explore structure
    print("\n1. Getting initial activity data...")
    r = requests.get(f"{DATA_API_BASE}/activity", params={
        "user": WALLET.lower(),
        "limit": 10,
    }, timeout=10)
    
    print(f"   Status: {r.status_code}")
    if r.status_code == 200:
        data = r.json()
        print(f"   Got {len(data)} items")
        if data:
            print(f"   First item keys: {list(data[0].keys())}")
            print(f"\n   First item sample:")
            for key in list(data[0].keys())[:15]:
                val = data[0][key]
                if isinstance(val, str) and len(val) > 50:
                    val = val[:50] + "..."
                print(f"      {key}: {val}")
    
    # Test 2: Check offset behavior
    print("\n2. Testing offset behavior for /activity...")
    offsets_to_test = [0, 500, 1000, 1500, 2000, 2500]
    
    results = {}
    for offset in offsets_to_test:
        r = requests.get(f"{DATA_API_BASE}/activity", params={
            "user": WALLET.lower(),
            "limit": 5,
            "offset": offset,
        }, timeout=10)
        
        if r.status_code == 200:
            data = r.json()
            if data:
                # Get some identifier
                first_id = data[0].get("id") or data[0].get("transactionHash") or str(data[0])[:50]
                results[offset] = first_id
                ts = data[0].get("timestamp") or data[0].get("createdAt")
                print(f"   offset={offset}: {len(data)} items, first_id={first_id[:30]}..., ts={ts}")
            else:
                print(f"   offset={offset}: empty")
                results[offset] = None
        else:
            print(f"   offset={offset}: error {r.status_code}")
    
    # Check for duplicates
    print("\n   Overlap analysis:")
    offsets = list(results.keys())
    for i in range(len(offsets)-1):
        o1, o2 = offsets[i], offsets[i+1]
        if results[o1] and results[o2]:
            if results[o1] == results[o2]:
                print(f"   WARNING: offset={o1} and offset={o2} return SAME first item")
            else:
                print(f"   OK: offset={o1} and offset={o2} return different items")
    
    # Test 3: Look for available endpoints
    print("\n3. Testing other Data API endpoints...")
    
    endpoints = [
        "/trades",
        "/activity", 
        "/positions",
        "/pnl",
        "/orderbook",
        "/markets",
        "/events",
        "/user/trades",
        "/user/history",
    ]
    
    for endpoint in endpoints:
        try:
            r = requests.get(f"{DATA_API_BASE}{endpoint}", params={
                "user": WALLET.lower(),
                "limit": 5,
            }, timeout=5)
            if r.status_code == 200:
                data = r.json()
                if isinstance(data, list):
                    print(f"   {endpoint}: ✓ returns list with {len(data)} items")
                elif isinstance(data, dict):
                    print(f"   {endpoint}: ✓ returns dict with keys: {list(data.keys())[:5]}")
            else:
                print(f"   {endpoint}: status {r.status_code}")
        except Exception as e:
            print(f"   {endpoint}: error - {e}")
    
    # Test 4: Check if activity has cursor/next_cursor
    print("\n4. Checking for cursor-based pagination in response...")
    r = requests.get(f"{DATA_API_BASE}/activity", params={
        "user": WALLET.lower(),
        "limit": 100,
    }, timeout=10)
    
    if r.status_code == 200:
        # Check response headers
        print(f"   Response headers with pagination hints:")
        for key in ['x-next-cursor', 'next-cursor', 'x-total', 'x-offset', 'link', 'x-pagination']:
            if key.lower() in [h.lower() for h in r.headers.keys()]:
                print(f"      {key}: {r.headers.get(key)}")
        
        # Check if response is paginated object
        try:
            data = r.json()
            if isinstance(data, dict):
                print(f"   Response is dict with keys: {list(data.keys())}")
                for key in ['next_cursor', 'nextCursor', 'cursor', 'has_more', 'hasMore', 'total']:
                    if key in data:
                        print(f"   Found pagination key: {key} = {data[key]}")
            else:
                print(f"   Response is list with {len(data)} items")
        except:
            pass
    
    # Test 5: Deep test activity offset limit
    print("\n5. Deep testing activity offset limit...")
    
    all_ids = set()
    last_valid_offset = 0
    
    for offset in range(0, 5001, 500):
        r = requests.get(f"{DATA_API_BASE}/activity", params={
            "user": WALLET.lower(),
            "limit": 100,
            "offset": offset,
        }, timeout=10)
        
        if r.status_code != 200:
            print(f"   offset={offset}: error {r.status_code}")
            continue
            
        data = r.json()
        if not data:
            print(f"   offset={offset}: empty - reached end?")
            break
        
        # Get unique identifiers
        page_ids = set()
        for item in data:
            item_id = item.get("id") or item.get("transactionHash") or f"{item.get('timestamp')}_{item.get('slug')}"
            page_ids.add(item_id)
        
        new_ids = page_ids - all_ids
        all_ids.update(page_ids)
        
        print(f"   offset={offset}: {len(data)} items, {len(new_ids)} new, {len(all_ids)} total unique")
        
        if len(new_ids) == 0:
            print(f"   WARNING: No new items at offset {offset} - possible limit reached")
            break
        
        last_valid_offset = offset
    
    print(f"\n   Summary: Last valid offset = {last_valid_offset}, Total unique items = {len(all_ids)}")


if __name__ == "__main__":
    test_activity_endpoint()
