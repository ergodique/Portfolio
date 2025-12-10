import pandas as pd

df = pd.read_parquet('Data/trades_0x6031b6ee.parquet')
print(f'Total trades: {len(df)}')
print(f'Date range: {df["timestamp"].min()} to {df["timestamp"].max()}')
print(f'Unique markets: {df["condition_id"].nunique()}')
print(f'\nFirst 5 trades:')
print(df[['timestamp', 'side', 'market_question', 'outcome', 'amount', 'price']].head())
