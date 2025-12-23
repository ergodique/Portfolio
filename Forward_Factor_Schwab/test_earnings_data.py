
import json
from pathlib import Path
from schwab_client import SchwabClient
from config import APP_KEY, APP_SECRET, CALLBACK_URL, TOKENS_FILE

def check_fundamentals(symbol="AAPL"):
    print(f"\n{'='*40}")
    print(f"Checking fundamentals for {symbol}...")
    print(f"{'='*40}")
    
    client = SchwabClient(
        app_key=APP_KEY,
        app_secret=APP_SECRET,
        callback_url=CALLBACK_URL,
        tokens_file=str(Path(__file__).resolve().parent / TOKENS_FILE),
        verbose=False
    )
    
    # 1. Test quotes endpoint with fundamental field
    print("\n1. Testing quotes endpoint (fields=fundamental)...")
    url = f"https://api.schwabapi.com/marketdata/v1/{symbol}/quotes"
    params = {'fields': 'fundamental'}
    
    try:
        response = client._make_request('GET', url, params=params)
        if response and response.ok:
            data = response.json()
            symbol_data = data.get(symbol, {})
            fundamental = symbol_data.get('fundamental', {})
            if fundamental:
                print(f"✓ Found {len(fundamental)} fundamental fields.")
                # Print all fields that contain 'earn' or 'date'
                for k, v in sorted(fundamental.items()):
                    if 'earn' in k.lower() or 'date' in k.lower():
                        print(f"  [MATCH] {k}: {v}")
                
                # Also print the first 10 fields just to see what they look like
                print("\n  Sample of other fields:")
                for k in list(fundamental.keys())[:10]:
                    print(f"  {k}: {fundamental[k]}")
            else:
                print("❌ No fundamental data in response.")
        else:
            print(f"❌ Error: {response.status_code if response else 'No response'}")
    except Exception as e:
        print(f"❌ Exception: {e}")

    # 3. Test Option Chain underlying data
    print("\n3. Testing option chain underlying data...")
    try:
        chain = client.get_option_chain(symbol=symbol, strike_count=1)
        if chain:
            underlying = chain.get('underlying', {})
            if underlying:
                print(f"✓ Underlying data found in chain ({len(underlying)} fields).")
                for k, v in sorted(underlying.items()):
                    if 'earn' in k.lower() or 'date' in k.lower():
                        print(f"  [MATCH] {k}: {v}")
            else:
                print("❌ No underlying data object in chain.")
        else:
            print("❌ No chain response.")
    except Exception as e:
        print(f"❌ Exception in chain: {e}")

if __name__ == "__main__":
    # Test a mix of stocks
    for sym in ["AAPL", "NVDA", "MSFT", "TSLA"]:
        check_fundamentals(sym)
