"""
Test Gamma API's endpoints for trade history
Also test pagination alternatives
"""

import requests
from datetime import datetime, timedelta

GAMMA_API_BASE = "https://gamma-api.polymarket.com"
DATA_API_BASE = "https://data-api.polymarket.com"
WALLET = "0x6031b6eed1c97e853c6e0f03ad3ce3529351f96d"


def test_gamma_api():
    """Test Gamma API capabilities"""
    
    print("=" * 70)
    print("TESTING GAMMA API ENDPOINTS")
    print("=" * 70)
    
    # Test 1: List all Gamma API endpoints
    print("\n1. Testing Gamma API endpoints...")
    
    endpoints = [
        "/events",
        "/markets", 
        "/trades",
        "/activity",
        "/positions",
        f"/users/{WALLET.lower()}",
        f"/users/{WALLET.lower()}/activity",
        f"/users/{WALLET.lower()}/trades",
        f"/users/{WALLET.lower()}/positions",
        "/user-activity",
        "/trade-history",
    ]
    
    for endpoint in endpoints:
        try:
            r = requests.get(f"{GAMMA_API_BASE}{endpoint}", params={"limit": 5}, timeout=5)
            if r.status_code == 200:
                data = r.json()
                if isinstance(data, list):
                    print(f"   {endpoint}: ✓ list with {len(data)} items")
                elif isinstance(data, dict):
                    print(f"   {endpoint}: ✓ dict with keys: {list(data.keys())[:5]}")
            else:
                print(f"   {endpoint}: {r.status_code}")
        except Exception as e:
            print(f"   {endpoint}: error")
    
    # Test 2: Explore events/markets structure
    print("\n2. Exploring events structure...")
    r = requests.get(f"{GAMMA_API_BASE}/events", params={"limit": 2, "active": "true"}, timeout=10)
    if r.status_code == 200:
        events = r.json()
        if events:
            event = events[0]
            print(f"   Sample event keys: {list(event.keys())[:10]}")
            print(f"   Event slug: {event.get('slug')}")
            
            # Check if event has markets
            markets = event.get("markets", [])
            if markets:
                print(f"   Markets in event: {len(markets)}")
                market = markets[0] if markets else None
                if market:
                    print(f"   Sample market keys: {list(market.keys())[:15]}")
    
    # Test 3: Check Data API with market filter + timestamps
    print("\n3. Testing Data API with market-specific queries...")
    
    # First get a market the user has traded
    r = requests.get(f"{DATA_API_BASE}/trades", params={
        "user": WALLET.lower(),
        "limit": 1,
    }, timeout=10)
    
    if r.status_code == 200:
        data = r.json()
        if data:
            condition_id = data[0].get("conditionId")
            market_slug = data[0].get("slug")
            print(f"   Found market: {market_slug}")
            print(f"   Condition ID: {condition_id}")
            
            # Try fetching trades for this specific market
            print(f"\n   3a. Fetching all trades for this market...")
            r2 = requests.get(f"{DATA_API_BASE}/trades", params={
                "market": condition_id,
                "limit": 500,
            }, timeout=30)
            
            if r2.status_code == 200:
                market_trades = r2.json()
                print(f"   Got {len(market_trades)} trades for this market")
                
                # Filter by user
                user_trades = [t for t in market_trades if t.get("proxyWallet", "").lower() == WALLET.lower()]
                print(f"   User's trades in this market: {len(user_trades)}")
    
    # Test 4: Try markets endpoint with trades
    print("\n4. Testing market-specific trade endpoints...")
    
    r = requests.get(f"{DATA_API_BASE}/trades", params={
        "user": WALLET.lower(),
        "limit": 5,
    }, timeout=10)
    
    if r.status_code == 200:
        trades = r.json()
        if trades:
            # Get unique markets
            unique_markets = set()
            for t in trades:
                condition_id = t.get("conditionId")
                if condition_id:
                    unique_markets.add(condition_id)
            
            print(f"   Found {len(unique_markets)} unique markets in first 5 trades")
    
    # Test 5: Check for incremental/cursor pagination
    print("\n5. Testing ID-based pagination...")
    
    r = requests.get(f"{DATA_API_BASE}/trades", params={
        "user": WALLET.lower(),
        "limit": 100,
        "offset": 0,
    }, timeout=10)
    
    if r.status_code == 200:
        data = r.json()
        if data:
            # Get the last item's timestamp and ID
            last_item = data[-1]
            last_ts = last_item.get("timestamp")
            last_id = last_item.get("id") or last_item.get("transactionHash")
            
            print(f"   Last timestamp: {last_ts}")
            print(f"   Last ID: {last_id}")
            
            # Try using timestamp as cursor
            print(f"\n   5a. Testing timestamp as cursor...")
            cursor_params = [
                {"cursor": last_ts},
                {"after_id": last_id},
                {"since_id": last_id},
                {"min_id": last_id},
                {"from_timestamp": last_ts},
            ]
            
            for params in cursor_params:
                key = list(params.keys())[0]
                full_params = {"user": WALLET.lower(), "limit": 10, **params}
                r2 = requests.get(f"{DATA_API_BASE}/trades", params=full_params, timeout=10)
                if r2.status_code == 200:
                    data2 = r2.json()
                    print(f"      {key}: got {len(data2)} trades")
    
    # Test 6: Calculate total trades via positions
    print("\n6. Checking positions endpoint...")
    r = requests.get(f"{DATA_API_BASE}/positions", params={
        "user": WALLET.lower(),
        "limit": 500,
    }, timeout=10)
    
    if r.status_code == 200:
        positions = r.json()
        print(f"   User has {len(positions)} positions")
        
        # Deep test positions offset
        print("\n   Testing positions offset limit...")
        for offset in [0, 500, 1000, 1500, 2000]:
            r2 = requests.get(f"{DATA_API_BASE}/positions", params={
                "user": WALLET.lower(),
                "limit": 100,
                "offset": offset,
            }, timeout=10)
            if r2.status_code == 200:
                data2 = r2.json()
                print(f"      offset={offset}: {len(data2)} positions")
                if len(data2) == 0:
                    break
    
    # Test 7: Market-by-market trade aggregation approach
    print("\n7. Testing market-by-market approach...")
    
    # Get user's positions (markets they've traded)
    r = requests.get(f"{DATA_API_BASE}/positions", params={
        "user": WALLET.lower(),
        "limit": 100,
    }, timeout=10)
    
    if r.status_code == 200:
        positions = r.json()
        print(f"   Found {len(positions)} positions")
        
        if positions:
            # For each market, get trades
            total_trades = 0
            for pos in positions[:5]:  # Test first 5 markets
                condition_id = pos.get("conditionId")
                if condition_id:
                    r2 = requests.get(f"{DATA_API_BASE}/trades", params={
                        "user": WALLET.lower(),
                        "market": condition_id,
                        "limit": 500,
                    }, timeout=10)
                    
                    if r2.status_code == 200:
                        trades = r2.json()
                        total_trades += len(trades)
                        print(f"      Market {condition_id[:10]}...: {len(trades)} trades")
            
            print(f"   Total trades from first 5 markets: {total_trades}")


if __name__ == "__main__":
    test_gamma_api()
