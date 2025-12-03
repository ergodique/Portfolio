"""
Test script to debug Schwab API responses
"""
import json
from schwab_client import SchwabClient
from config import APP_KEY, APP_SECRET, CALLBACK_URL, TOKENS_FILE
from pathlib import Path

def test_single_symbol(symbol="AAPL"):
    """Test API response for a single symbol"""
    print(f"\n{'='*60}")
    print(f"Testing symbol: {symbol}")
    print('='*60)
    
    client = SchwabClient(
        app_key=APP_KEY,
        app_secret=APP_SECRET,
        callback_url=CALLBACK_URL,
        tokens_file=str(Path(__file__).resolve().parent / TOKENS_FILE),
        verbose=False
    )
    
    # Test option chain
    print("\n1. Getting option chain...")
    chain = client.get_option_chain(
        symbol=symbol,
        contract_type="CALL",
        strike_count=20,
        include_underlying_quote=True
    )
    
    if not chain:
        print("   ❌ No response from API")
        return
    
    print(f"   ✓ Response received. Keys: {list(chain.keys())}")
    
    # Check status
    if 'status' in chain:
        print(f"   Status: {chain.get('status')}")
    
    # Check for errors
    if 'error' in chain or 'errors' in chain:
        print(f"   ❌ Error in response: {chain.get('error') or chain.get('errors')}")
        return
    
    # Check underlying
    underlying = chain.get('underlying', {})
    if underlying:
        print(f"\n2. Underlying data:")
        print(f"   Symbol: {underlying.get('symbol')}")
        print(f"   Last: {underlying.get('last')}")
        print(f"   Mark: {underlying.get('mark')}")
    else:
        print("\n2. ❌ No underlying data")
    
    # Check call map
    call_map = chain.get('callExpDateMap', {})
    print(f"\n3. Call expiration map:")
    print(f"   Number of expiry dates: {len(call_map)}")
    
    if call_map:
        expiries = sorted(call_map.keys())[:5]
        print(f"   First 5 expiries: {expiries}")
        
        # Check first expiry
        if expiries:
            first_exp = expiries[0]
            strikes = call_map.get(first_exp, {})
            print(f"\n4. First expiry ({first_exp}):")
            print(f"   Number of strikes: {len(strikes)}")
            
            if strikes:
                strike_keys = sorted([float(k) for k in strikes.keys()])[:3]
                print(f"   First 3 strikes: {strike_keys}")
                
                # Check first strike data
                first_strike = str(strike_keys[0])
                for key in strikes.keys():
                    if abs(float(key) - strike_keys[0]) < 0.01:
                        first_strike = key
                        break
                
                option_data = strikes.get(first_strike, [])
                if option_data:
                    opt = option_data[0] if isinstance(option_data, list) else option_data
                    print(f"\n5. Sample option data at strike {first_strike}:")
                    print(f"   Bid: {opt.get('bid')}")
                    print(f"   Ask: {opt.get('ask')}")
                    print(f"   Last: {opt.get('last')}")
                    print(f"   Mark: {opt.get('mark')}")
                    print(f"   Volatility: {opt.get('volatility')}")
                    print(f"   Open Interest: {opt.get('openInterest')}")
                    print(f"   Volume: {opt.get('totalVolume')}")
    else:
        print("   ❌ No call expiration map!")
        print("\n   Full response (first 2000 chars):")
        print(f"   {json.dumps(chain, indent=2)[:2000]}")

def test_multiple_symbols():
    """Test multiple symbols"""
    # Include some that showed "No options" in the scan
    symbols = ["AAPL", "HD", "IBM", "SPY", "MSFT", "HAS", "HBAN", "HON", "HOOD", "HUM"]
    
    print("\n" + "="*60)
    print("TESTING MULTIPLE SYMBOLS")
    print("="*60)
    
    client = SchwabClient(
        app_key=APP_KEY,
        app_secret=APP_SECRET,
        callback_url=CALLBACK_URL,
        tokens_file=str(Path(__file__).resolve().parent / TOKENS_FILE),
        verbose=False
    )
    
    for symbol in symbols:
        print(f"\n{symbol}: ", end="")
        try:
            chain = client.get_option_chain(symbol=symbol, contract_type="CALL", strike_count=5)
            if chain:
                call_map = chain.get('callExpDateMap', {})
                if call_map:
                    print(f"✓ {len(call_map)} expiries found")
                else:
                    print(f"❌ No callExpDateMap. Keys: {list(chain.keys())}")
                    if 'error' in chain:
                        print(f"   Error: {chain.get('error')}")
            else:
                print("❌ No response")
        except Exception as e:
            print(f"❌ Error: {e}")

if __name__ == "__main__":
    # Test single symbol first
    test_single_symbol("AAPL")
    
    # Then test multiple
    test_multiple_symbols()

