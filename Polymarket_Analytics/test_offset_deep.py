"""
Test if API offset actually changes the results
"""

import requests

DATA_API_BASE = "https://data-api.polymarket.com"
WALLET = "0x6031b6eed1c97e853c6e0f03ad3ce3529351f96d"

def test_offset():
    """Test if offset parameter actually works for this wallet"""
    
    print("Testing API offset behavior...")
    print("=" * 60)
    
    # Test multiple offsets
    offsets = [0, 500, 1000, 1500, 2000, 2500]
    
    all_hashes = {}
    
    for offset in offsets:
        print(f"\nFetching offset={offset}, limit=10")
        r = requests.get(f"{DATA_API_BASE}/trades", params={
            "user": WALLET.lower(),
            "limit": 10,
            "offset": offset
        })
        
        if r.status_code != 200:
            print(f"   Error: {r.status_code}")
            continue
            
        data = r.json()
        print(f"   Got {len(data)} trades")
        
        if data:
            hashes = [t.get("transactionHash") for t in data]
            timestamps = [t.get("timestamp") for t in data]
            
            print(f"   First 3 transaction hashes: {hashes[:3]}")
            print(f"   First 3 timestamps: {timestamps[:3]}")
            
            all_hashes[offset] = set(hashes)
    
    # Check for overlap
    print("\n" + "=" * 60)
    print("OVERLAP ANALYSIS")
    print("=" * 60)
    
    for i, offset1 in enumerate(offsets):
        for offset2 in offsets[i+1:]:
            if offset1 in all_hashes and offset2 in all_hashes:
                overlap = all_hashes[offset1] & all_hashes[offset2]
                if overlap:
                    print(f"WARNING: offset={offset1} and offset={offset2} share {len(overlap)} transactions!")
                    print(f"  Overlapping: {list(overlap)[:3]}")
                else:
                    print(f"OK: offset={offset1} and offset={offset2} have no overlap")

if __name__ == "__main__":
    test_offset()

