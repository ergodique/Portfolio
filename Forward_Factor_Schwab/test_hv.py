import sys

# Force UTF-8 for output
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

import json
from schwab_client import SchwabClient
from config import APP_KEY, APP_SECRET, CALLBACK_URL, TOKENS_FILE
from pathlib import Path
import urllib.parse

def test_hv(symbol="AAPL"):
    with open(f"test_hv_{symbol}.txt", "w", encoding="utf-8") as f:
        f.write(f"\n{'='*60}\n")
        f.write(f"Testing HV for symbol: {symbol}\n")
        f.write('='*60 + "\n")
        
        client = SchwabClient(
            app_key=APP_KEY,
            app_secret=APP_SECRET,
            callback_url=CALLBACK_URL,
            tokens_file=str(Path(__file__).resolve().parent / TOKENS_FILE),
            verbose=False
        )
        
        # Test quote with fundamental fields
        f.write("\n1. Getting quote with fundamental fields...\n")
        quote = client.get_quote(symbol, fields="quote,fundamental")
        
        if not quote:
            f.write("   ❌ No response from API\n")
            return
        
        f.write(f"   ✓ Response received.\n")
        
        # Check for HV in fundamental
        fundamental = quote.get('fundamental', {})
        if fundamental:
            f.write("\n2. All Fundamental data fields:\n")
            for key in sorted(fundamental.keys()):
                f.write(f"   {key}: {fundamental[key]}\n")
        else:
            f.write("\n2. No fundamental data found in quote.\n")

        # Check for HV in quote
        quote_data = quote.get('quote', {})
        if quote_data:
            f.write("\n3. All Quote data fields:\n")
            for key in sorted(quote_data.keys()):
                f.write(f"   {key}: {quote_data[key]}\n")
        
        # Also check price history to see if HV can be calculated
        f.write("\n4. Getting price history...\n")
        history = client.get_price_history(symbol, period_type="month", period=1)
        if history:
            candles = history.get('candles', [])
            f.write(f"   ✓ Received {len(candles)} candles.\n")
            if candles:
                f.write(f"   Sample candle: {candles[0]}\n")
        else:
            f.write("   ❌ No price history received.\n")

if __name__ == "__main__":
    test_hv("AAPL")
    test_hv("SPY")
