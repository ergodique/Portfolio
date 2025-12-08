"""
Test Polymarket API pagination behavior
"""

import requests

DATA_API_BASE = "https://data-api.polymarket.com"
WALLET = "0x6031b6eed1c97e853c6e0f03ad3ce3529351f96d"

def test_pagination():
    """Test if offset parameter actually works"""
    
    print("Testing API pagination...")
    print("=" * 60)
    
    # Test 1: First page (offset=0)
    print("\n1. Fetching offset=0, limit=10")
    r1 = requests.get(f"{DATA_API_BASE}/trades", params={
        "user": WALLET.lower(),
        "limit": 10,
        "offset": 0
    })
    data1 = r1.json()
    print(f"   Got {len(data1)} trades")
    if data1:
        tx1 = [t.get("transactionHash") for t in data1]
        print(f"   First 5 transaction hashes: {tx1[:5]}")
    
    # Test 2: Second page (offset=10)
    print("\n2. Fetching offset=10, limit=10")
    r2 = requests.get(f"{DATA_API_BASE}/trades", params={
        "user": WALLET.lower(),
        "limit": 10,
        "offset": 10
    })
    data2 = r2.json()
    print(f"   Got {len(data2)} trades")
    if data2:
        tx2 = [t.get("transactionHash") for t in data2]
        print(f"   First 5 transaction hashes: {tx2[:5]}")
    
    # Test 3: Check for overlap
    print("\n3. Checking for overlap between pages")
    if data1 and data2:
        tx1_set = set(tx1)
        tx2_set = set(tx2)
        overlap = tx1_set & tx2_set
        print(f"   Overlapping transaction hashes: {len(overlap)}")
        if overlap:
            print(f"   WARNING: Same transactions appear in both pages!")
            print(f"   Overlapping hashes: {list(overlap)[:5]}")
        else:
            print(f"   OK: No overlap between pages")
    
    # Test 4: Check if offset=0 and offset=500 return different data
    print("\n4. Testing larger offset (offset=500, limit=10)")
    r3 = requests.get(f"{DATA_API_BASE}/trades", params={
        "user": WALLET.lower(),
        "limit": 10,
        "offset": 500
    })
    data3 = r3.json()
    print(f"   Got {len(data3)} trades")
    if data3:
        tx3 = [t.get("transactionHash") for t in data3]
        print(f"   First 5 transaction hashes: {tx3[:5]}")
        
        overlap_with_first = set(tx1) & set(tx3)
        print(f"   Overlap with first page: {len(overlap_with_first)}")
        if overlap_with_first:
            print(f"   WARNING: offset=500 still returns same data as offset=0!")
    
    # Test 5: Check transaction hash distribution in first page
    print("\n5. Analyzing first page (offset=0, limit=100)")
    r4 = requests.get(f"{DATA_API_BASE}/trades", params={
        "user": WALLET.lower(),
        "limit": 100,
        "offset": 0
    })
    data4 = r4.json()
    if data4:
        tx4 = [t.get("transactionHash") for t in data4]
        from collections import Counter
        tx_counts = Counter(tx4)
        duplicates = {k: v for k, v in tx_counts.items() if v > 1}
        print(f"   Total trades: {len(data4)}")
        print(f"   Unique transaction hashes: {len(set(tx4))}")
        print(f"   Duplicate transaction hashes: {len(duplicates)}")
        if duplicates:
            print(f"   WARNING: API returns duplicate transactions in same page!")
            print(f"   Most duplicated: {max(duplicates.items(), key=lambda x: x[1])}")

if __name__ == "__main__":
    test_pagination()

