import yfinance as yf
import pandas as pd
import numpy as np
from datetime import datetime, timedelta

def get_stock_data(tickers, period):
    """Download stock data for given tickers and period"""
    try:
        print(f"Downloading data for {len(tickers)} tickers: {tickers[:3]}...")
        data = yf.download(tickers, period=period, progress=False, auto_adjust=True)
        
        print(f"Downloaded data shape: {data.shape}")
        print(f"Data columns: {data.columns.tolist()}")
        
        # Check if data is empty
        if data.empty:
            print("Downloaded data is empty")
            return None
            
        # Handle single ticker case
        if len(tickers) == 1:
            if 'Adj Close' in data.columns:
                return data[['Adj Close']].rename(columns={'Adj Close': tickers[0]})
            elif 'Close' in data.columns:
                return data[['Close']].rename(columns={'Close': tickers[0]})
            else:
                print(f"No price data found in columns: {data.columns.tolist()}")
                return None
        
        # Handle multiple tickers case
        if isinstance(data.columns, pd.MultiIndex):
            # MultiIndex columns case - typical for multiple tickers
            if 'Adj Close' in data.columns.get_level_values(0):
                adj_close_data = data['Adj Close']
                return adj_close_data
            elif 'Close' in data.columns.get_level_values(0):
                close_data = data['Close']
                return close_data
            else:
                print(f"No suitable price columns found. Available: {data.columns.get_level_values(0).unique().tolist()}")
                return None
        else:
            # Single level columns
            if 'Adj Close' in data.columns:
                return data['Adj Close']
            elif 'Close' in data.columns:
                return data['Close']
            else:
                print(f"No price columns found. Available: {data.columns.tolist()}")
                return None
                
    except Exception as e:
        print(f"Error downloading data: {e}")
        import traceback
        traceback.print_exc()
        return None

def calculate_correlations(data, freq='D'):
    """Calculate correlations for given frequency"""
    if freq == 'W':
        # Resample to weekly data (Friday close)
        data_resampled = data.resample('W-FRI').last()
    elif freq == 'M':
        # Resample to monthly data (month end)
        data_resampled = data.resample('ME').last()
    else:
        # Daily data
        data_resampled = data
    
    # Calculate returns
    returns = data_resampled.pct_change().dropna()
    
    # Calculate correlation matrix
    correlation_matrix = returns.corr()
    
    return correlation_matrix

def main():
    # Define the list of stock tickers for Borsa Istanbul
    # Note: Using most liquid and commonly traded BIST stocks
    tickers = [
        "AEFES.IS", "AKBNK.IS", "AKSEN.IS", "ALARK.IS", "ARCLK.IS", "ASELS.IS", "BIMAS.IS",
        "BRSAN.IS", "CIMSA.IS", "DOHOL.IS", "EKGYO.IS", "ENKAI.IS", "ENJSA.IS", "EREGL.IS",
        "FROTO.IS", "GARAN.IS", "GUBRF.IS", "HALKB.IS", "HEKTS.IS", "ISCTR.IS", "KCHOL.IS",
        "KOZAA.IS", "KOZAL.IS", "KRDMD.IS", "MGROS.IS", "OYAKC.IS", "PETKM.IS", "PGSUS.IS",
        "SAHOL.IS", "SASA.IS", "SISE.IS", "SOKM.IS", "TAVHL.IS", "TCELL.IS", "THYAO.IS",
        "TKFEN.IS", "TOASO.IS", "TSKB.IS", "TTKOM.IS", "TUPRS.IS", "ULKER.IS", "VAKBN.IS",
        "VESTL.IS", "YKBNK.IS", "QNBTR.IS","XU100.IS","XU030.IS","XBANK.IS"
    ]
    
    print("Downloading stock data...")
    
    # Download data for the last 2 years to have enough data for monthly correlations
    data = get_stock_data(tickers, "2y")
    
    # Remove tickers that have no data
    if data is not None and not data.empty:
        data = data.dropna(axis=1, how='all')
        # Remove tickers with insufficient data (less than 100 observations)
        data = data.dropna(axis=1, thresh=100)
        
        if data.empty or len(data.columns) == 0:
            print("No valid stock data found. Trying with a smaller subset of well-known stocks...")
            # Try with a smaller set of most liquid stocks
            liquid_tickers = ["AKBNK.IS", "GARAN.IS", "ISCTR.IS", "HALKB.IS", "VAKBN.IS", 
                            "EREGL.IS", "ARCLK.IS", "THYAO.IS", "SAHOL.IS", "KCHOL.IS"]
            data = get_stock_data(liquid_tickers, "1y")
            if data is not None and not data.empty:
                data = data.dropna(axis=1, how='all')
                data = data.dropna(axis=1, thresh=50)
            
            # If still no data, try with even fewer stocks
            if data is None or data.empty or len(data.columns) == 0:
                print("Trying with top 5 most liquid stocks...")
                top_liquid = ["AKBNK.IS", "GARAN.IS", "ISCTR.IS", "HALKB.IS", "VAKBN.IS"]
                data = get_stock_data(top_liquid, "6mo")
                if data is not None and not data.empty:
                    data = data.dropna(axis=1, how='all')
                    data = data.dropna(axis=1, thresh=25)
    
    if data is None or data.empty or len(data.columns) == 0:
        print("Error: No stock data could be downloaded. Please check your internet connection and ticker symbols.")
        return
    
    print(f"Successfully downloaded data for {len(data.columns)} stocks")
    print("Available tickers:", list(data.columns))
    
    # Calculate correlations for different frequencies
    print("\n" + "="*80)
    print("DAILY CORRELATIONS")
    print("="*80)
    daily_corr = calculate_correlations(data, freq='D')
    print(daily_corr.round(3))
    
    print("\n" + "="*80)
    print("WEEKLY CORRELATIONS")
    print("="*80)
    weekly_corr = calculate_correlations(data, freq='W')
    print(weekly_corr.round(3))
    
    print("\n" + "="*80)
    print("MONTHLY CORRELATIONS")
    print("="*80)
    monthly_corr = calculate_correlations(data, freq='M')
    print(monthly_corr.round(3))
    
    # Save correlations to Excel file with different sheets
    try:
        # Try openpyxl first
        with pd.ExcelWriter('stock_correlations.xlsx', engine='openpyxl') as writer:
            daily_corr.to_excel(writer, sheet_name='Daily_Correlations')
            weekly_corr.to_excel(writer, sheet_name='Weekly_Correlations') 
            monthly_corr.to_excel(writer, sheet_name='Monthly_Correlations')
        print("Excel file saved successfully with openpyxl!")
    except ImportError:
        try:
            # Try xlsxwriter as fallback
            with pd.ExcelWriter('stock_correlations.xlsx', engine='xlsxwriter') as writer:
                daily_corr.to_excel(writer, sheet_name='Daily_Correlations')
                weekly_corr.to_excel(writer, sheet_name='Weekly_Correlations') 
                monthly_corr.to_excel(writer, sheet_name='Monthly_Correlations')
            print("Excel file saved successfully with xlsxwriter!")
        except ImportError:
            # Final fallback - save as CSV files
            print("Excel engines not available. Saving as CSV files...")
            daily_corr.to_csv('daily_correlations.csv')
            weekly_corr.to_csv('weekly_correlations.csv')
            monthly_corr.to_csv('monthly_correlations.csv')
            print("Correlation matrices saved as CSV files!")
    
    print("\n" + "="*80)
    print("SUMMARY STATISTICS")
    print("="*80)
    
    # Calculate average correlations (excluding diagonal)
    
    def avg_correlation(corr_matrix):
        # Get upper triangle of correlation matrix (excluding diagonal)
        mask = np.triu(np.ones_like(corr_matrix, dtype=bool), k=1)
        return corr_matrix.values[mask].mean()
    
    print(f"Average Daily Correlation: {avg_correlation(daily_corr):.3f}")
    print(f"Average Weekly Correlation: {avg_correlation(weekly_corr):.3f}")
    print(f"Average Monthly Correlation: {avg_correlation(monthly_corr):.3f}")
    
    # Find highest and lowest correlations for each frequency
    def find_extreme_correlations(corr_matrix, freq_name):
        # Get upper triangle excluding diagonal
        mask = np.triu(np.ones_like(corr_matrix, dtype=bool), k=1)
        corr_values = corr_matrix.where(mask)
        
        # Find max correlation
        max_corr = corr_values.max().max()
        max_idx = corr_values.stack().idxmax()
        
        # Find min correlation
        min_corr = corr_values.min().min()
        min_idx = corr_values.stack().idxmin()
        
        print(f"\n{freq_name} Correlations:")
        print(f"Highest: {max_corr:.3f} between {max_idx[0]} and {max_idx[1]}")
        print(f"Lowest: {min_corr:.3f} between {min_idx[0]} and {min_idx[1]}")
    
    find_extreme_correlations(daily_corr, "Daily")
    find_extreme_correlations(weekly_corr, "Weekly")
    find_extreme_correlations(monthly_corr, "Monthly")
    
    print(f"\nCorrelation matrices saved to Excel file 'stock_correlations.xlsx' with separate sheets for each time frequency")

if __name__ == "__main__":
    main()