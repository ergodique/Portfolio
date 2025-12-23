import yfinance as yf
import pandas as pd
from datetime import datetime, date

def test_yfinance_earnings(symbols=["AAPL", "TSLA", "NVDA", "MSFT", "AMD"]):
    print("=" * 50)
    print(f"{'Symbol':<10} | {'Next Earnings (yfinance)':<25}")
    print("-" * 50)
    
    for symbol in symbols:
        try:
            ticker = yf.Ticker(symbol)
            
            # Method 1: calendar (Usually contains the confirmed upcoming date)
            calendar = ticker.calendar
            next_earn_val = "N/A"
            days_rem = "N/A"
            today = date.today()

            def find_future_date(dt_list):
                for dt in dt_list:
                    target_dt = dt.date() if hasattr(dt, 'date') else dt
                    if target_dt >= today:
                        return target_dt
                return None
            
            if calendar is not None and 'Earnings Date' in calendar:
                dates = calendar['Earnings Date']
                target_dt = find_future_date(dates if isinstance(dates, (list, tuple)) else [dates])
                if target_dt:
                    next_earn_val = target_dt.strftime('%d-%m-%y')
                    days_rem = (target_dt - today).days

            # Fallback to earnings_dates
            if next_earn_val == "N/A":
                try:
                    ed = ticker.earnings_dates
                    if ed is not None and not ed.empty:
                        future_mask = ed.index.tz_localize(None).date >= today
                        future_dates = ed.index[future_mask]
                        if not future_dates.empty:
                            target_dt = future_dates[0].date()
                            next_earn_val = target_dt.strftime('%d-%m-%y')
                            days_rem = (target_dt - today).days
                except:
                    pass

            print(f"{symbol:<10} | {next_earn_val}({days_rem})")
            
        except Exception as e:
            print(f"{symbol:<10} | Failed: {str(e)[:40]}")

if __name__ == "__main__":
    # Test a mix of known symbols
    test_yfinance_earnings()
    
    # Test some "passed" symbols from recent logs if possible
    # (Leaving this for manual run)
