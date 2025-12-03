"""
Schwab API Client Wrapper for Forward Factor Scanner
Provides simplified interface for getting option chain and quote data.
"""

import sys
import json
import time
import base64
import requests
import threading
import webbrowser
import urllib.parse
from datetime import datetime
from pathlib import Path


class SchwabClient:
    """
    Simplified Schwab API client for option data.
    Handles authentication and provides methods for quotes and option chains.
    """
    
    def __init__(self, app_key, app_secret, callback_url="https://127.0.0.1", 
                 tokens_file="tokens.json", timeout=8, verbose=False):
        """
        Initialize the Schwab API client.
        
        :param app_key: Schwab Developer App Key (32 chars)
        :param app_secret: Schwab Developer App Secret (16 chars)
        :param callback_url: OAuth callback URL
        :param tokens_file: Path to store/load tokens
        :param timeout: Request timeout in seconds
        :param verbose: Print debug information
        """
        # Validate inputs
        if not app_key or app_key == "YOUR_APP_KEY_HERE":
            raise ValueError("Please set your APP_KEY in config.py")
        if not app_secret or app_secret == "YOUR_APP_SECRET_HERE":
            raise ValueError("Please set your APP_SECRET in config.py")
        # Key length validation removed - Schwab may have changed their format
            
        self._app_key = app_key
        self._app_secret = app_secret
        self._callback_url = callback_url
        self._tokens_file = Path(tokens_file)
        self.timeout = timeout
        self.verbose = verbose
        
        # Token storage
        self.access_token = None
        self.refresh_token = None
        self._access_token_issued = None
        self._refresh_token_issued = None
        self._access_token_timeout = 1800  # 30 minutes
        self._refresh_token_timeout = 7    # 7 days
        
        # API endpoints
        self._base_api_url = "https://api.schwabapi.com"
        self._auth_url = "https://api.schwabapi.com/v1/oauth/authorize"
        self._token_url = "https://api.schwabapi.com/v1/oauth/token"
        
        # Initialize tokens
        self._initialize_tokens()
        
        # Start auto-refresh thread
        self._start_token_refresh_thread()
    
    def _initialize_tokens(self):
        """Load existing tokens or get new ones."""
        if self._tokens_file.exists():
            try:
                with open(self._tokens_file, 'r') as f:
                    data = json.load(f)
                    self.access_token = data.get('access_token')
                    self.refresh_token = data.get('refresh_token')
                    self._access_token_issued = datetime.fromisoformat(data.get('access_token_issued', ''))
                    self._refresh_token_issued = datetime.fromisoformat(data.get('refresh_token_issued', ''))
                    
                    if self.verbose:
                        print(f"Loaded tokens from {self._tokens_file}")
                    
                    # Check if tokens need refresh
                    self._update_tokens_if_needed()
                    return
            except Exception as e:
                if self.verbose:
                    print(f"Could not load tokens: {e}")
        
        # No valid tokens, need to authenticate
        self._authenticate()
    
    def _authenticate(self):
        """Perform OAuth authentication flow."""
        max_attempts = 3
        
        for attempt in range(max_attempts):
            print("\n" + "="*60)
            print(f"SCHWAB AUTHENTICATION REQUIRED (Attempt {attempt + 1}/{max_attempts})")
            print("="*60)
            
            # Build authorization URL
            auth_params = {
                'client_id': self._app_key,
                'redirect_uri': self._callback_url,
                'response_type': 'code'
            }
            auth_url = f"{self._auth_url}?{urllib.parse.urlencode(auth_params)}"
            
            print(f"\n1. Opening browser for Schwab login...")
            print(f"   If browser doesn't open, go to:\n   {auth_url}\n")
            
            try:
                webbrowser.open(auth_url)
            except Exception:
                pass
            
            print("2. Log in to your Schwab account")
            print("3. After login, you'll be redirected to a page that may show an error")
            print("4. QUICKLY copy the ENTIRE URL from your browser's address bar")
            print("   (It should start with https://127.0.0.1 and contain 'code=')")
            print("\n   ⚠️  NOTE: The code expires in ~30 seconds! Be quick!\n")
            
            redirect_url = input("Paste the redirect URL here: ").strip()
            
            # Extract authorization code
            try:
                parsed = urllib.parse.urlparse(redirect_url)
                query_params = urllib.parse.parse_qs(parsed.query)
                auth_code = query_params.get('code', [None])[0]
                
                if not auth_code:
                    raise ValueError("No authorization code found in URL")
                
                # URL decode the auth code (important for %40 -> @ etc.)
                auth_code = urllib.parse.unquote(auth_code)
                    
            except Exception as e:
                print(f"\n❌ Error: Could not extract authorization code: {e}")
                if attempt < max_attempts - 1:
                    print("Let's try again...\n")
                    continue
                raise ValueError(f"Could not extract authorization code after {max_attempts} attempts")
            
            # Exchange code for tokens
            try:
                self._exchange_code_for_tokens(auth_code)
                print("\n✅ Authentication successful!")
                print("="*60 + "\n")
                return
            except Exception as e:
                error_msg = str(e).lower()
                if "expired" in error_msg or "invalid" in error_msg:
                    print(f"\n❌ Authorization code expired or invalid.")
                    if attempt < max_attempts - 1:
                        print("The code expires quickly. Let's try again - be faster this time!\n")
                        continue
                raise
        
        raise Exception("Authentication failed after maximum attempts")
    
    def _exchange_code_for_tokens(self, auth_code):
        """Exchange authorization code for access and refresh tokens."""
        # Prepare credentials
        credentials = base64.b64encode(
            f"{self._app_key}:{self._app_secret}".encode()
        ).decode()
        
        headers = {
            'Authorization': f'Basic {credentials}',
            'Content-Type': 'application/x-www-form-urlencoded'
        }
        
        data = {
            'grant_type': 'authorization_code',
            'code': auth_code,
            'redirect_uri': self._callback_url
        }
        
        response = requests.post(self._token_url, headers=headers, data=data, timeout=self.timeout)
        
        if not response.ok:
            raise Exception(f"Token exchange failed: {response.status_code} - {response.text}")
        
        token_data = response.json()
        self._save_tokens(token_data)
    
    def _save_tokens(self, token_data):
        """Save tokens to file and memory."""
        self.access_token = token_data.get('access_token')
        self.refresh_token = token_data.get('refresh_token')
        self._access_token_issued = datetime.now()
        self._refresh_token_issued = datetime.now()
        
        save_data = {
            'access_token': self.access_token,
            'refresh_token': self.refresh_token,
            'access_token_issued': self._access_token_issued.isoformat(),
            'refresh_token_issued': self._refresh_token_issued.isoformat()
        }
        
        with open(self._tokens_file, 'w') as f:
            json.dump(save_data, f, indent=2)
        
        if self.verbose:
            print(f"Tokens saved to {self._tokens_file}")
    
    def _update_tokens_if_needed(self):
        """Check and refresh tokens if needed."""
        now = datetime.now()
        
        # Check refresh token (expires in 7 days)
        if self._refresh_token_issued:
            days_since_refresh = (now - self._refresh_token_issued).days
            if days_since_refresh >= (self._refresh_token_timeout - 1):
                print("Refresh token expired. Please re-authenticate.")
                self._authenticate()
                return
        
        # Check access token (expires in 30 minutes)
        if self._access_token_issued:
            seconds_since_access = (now - self._access_token_issued).seconds
            if seconds_since_access > (self._access_token_timeout - 120):  # Refresh 2 min early
                self._refresh_access_token()
    
    def _refresh_access_token(self):
        """Refresh the access token using refresh token."""
        if self.verbose:
            print("Refreshing access token...")
        
        credentials = base64.b64encode(
            f"{self._app_key}:{self._app_secret}".encode()
        ).decode()
        
        headers = {
            'Authorization': f'Basic {credentials}',
            'Content-Type': 'application/x-www-form-urlencoded'
        }
        
        data = {
            'grant_type': 'refresh_token',
            'refresh_token': self.refresh_token
        }
        
        try:
            response = requests.post(self._token_url, headers=headers, data=data, timeout=self.timeout)
            
            if response.ok:
                token_data = response.json()
                self.access_token = token_data.get('access_token')
                self.refresh_token = token_data.get('refresh_token', self.refresh_token)
                self._access_token_issued = datetime.now()
                
                # Save updated tokens
                save_data = {
                    'access_token': self.access_token,
                    'refresh_token': self.refresh_token,
                    'access_token_issued': self._access_token_issued.isoformat(),
                    'refresh_token_issued': self._refresh_token_issued.isoformat()
                }
                with open(self._tokens_file, 'w') as f:
                    json.dump(save_data, f, indent=2)
                
                if self.verbose:
                    print("Access token refreshed successfully")
            else:
                print(f"Token refresh failed: {response.status_code}")
                self._authenticate()
        except Exception as e:
            print(f"Token refresh error: {e}")
    
    def _start_token_refresh_thread(self):
        """Start background thread to auto-refresh tokens."""
        def refresh_loop():
            while True:
                time.sleep(60)  # Check every minute
                try:
                    self._update_tokens_if_needed()
                except Exception as e:
                    if self.verbose:
                        print(f"Token refresh error: {e}")
        
        thread = threading.Thread(target=refresh_loop, daemon=True)
        thread.start()
    
    def _make_request(self, method, url, params=None, max_retries=3):
        """Make an authenticated API request with retry logic."""
        headers = {'Authorization': f'Bearer {self.access_token}'}
        
        for attempt in range(max_retries):
            try:
                if method == 'GET':
                    response = requests.get(url, headers=headers, params=params, timeout=self.timeout)
                else:
                    response = requests.post(url, headers=headers, json=params, timeout=self.timeout)
                
                if response.status_code == 401:
                    # Token expired, refresh and retry
                    self._refresh_access_token()
                    headers = {'Authorization': f'Bearer {self.access_token}'}
                    continue
                
                return response
                
            except requests.exceptions.Timeout:
                if attempt < max_retries - 1:
                    time.sleep(2 ** attempt)
                    continue
                raise
            except Exception as e:
                if attempt < max_retries - 1:
                    time.sleep(2 ** attempt)
                    continue
                raise
        
        return None
    
    # ========== Public API Methods ==========
    
    def get_quote(self, symbol):
        """
        Get real-time quote for a single symbol.
        
        :param symbol: Ticker symbol (e.g., "AAPL")
        :return: Quote data dict or None
        """
        url = f"{self._base_api_url}/marketdata/v1/{urllib.parse.quote(symbol)}/quotes"
        response = self._make_request('GET', url)
        
        if response and response.ok:
            data = response.json()
            return data.get(symbol, data)
        return None
    
    def get_quotes(self, symbols):
        """
        Get real-time quotes for multiple symbols.
        
        :param symbols: List of ticker symbols
        :return: Dict of quotes keyed by symbol
        """
        if isinstance(symbols, list):
            symbols = ','.join(symbols)
        
        url = f"{self._base_api_url}/marketdata/v1/quotes"
        params = {'symbols': symbols}
        response = self._make_request('GET', url, params)
        
        if response and response.ok:
            return response.json()
        return {}
    
    def get_option_chain(self, symbol, contract_type="CALL", strike_count=10, 
                         include_underlying_quote=True, from_date=None, to_date=None):
        """
        Get option chain for a symbol.
        
        :param symbol: Underlying ticker symbol
        :param contract_type: "CALL", "PUT", or "ALL"
        :param strike_count: Number of strikes around ATM
        :param include_underlying_quote: Include underlying stock quote
        :param from_date: Filter options expiring after this date (datetime or "YYYY-MM-DD")
        :param to_date: Filter options expiring before this date
        :return: Option chain data dict or None
        """
        url = f"{self._base_api_url}/marketdata/v1/chains"
        
        params = {
            'symbol': symbol,
            'contractType': contract_type,
            'strikeCount': strike_count,
            'includeUnderlyingQuote': include_underlying_quote
        }
        
        if from_date:
            if isinstance(from_date, datetime):
                from_date = from_date.strftime('%Y-%m-%d')
            params['fromDate'] = from_date
        
        if to_date:
            if isinstance(to_date, datetime):
                to_date = to_date.strftime('%Y-%m-%d')
            params['toDate'] = to_date
        
        response = self._make_request('GET', url, params)
        
        if response and response.ok:
            return response.json()
        
        # Debug: Log what actually came back
        if response is None:
            print(f"DEBUG {symbol}: Response is None (timeout/exception)")
        elif not response.ok:
            print(f"DEBUG {symbol}: HTTP {response.status_code} - {response.text[:200]}")
            
        return None
    
    def get_option_expiration_chain(self, symbol):
        """
        Get list of option expiration dates for a symbol.
        
        :param symbol: Ticker symbol
        :return: List of expiration dates or None
        """
        url = f"{self._base_api_url}/marketdata/v1/expirationchain"
        params = {'symbol': symbol}
        response = self._make_request('GET', url, params)
        
        if response and response.ok:
            return response.json()
        return None
    
    def get_price_history(self, symbol, period_type="month", period=1):
        """
        Get price history for a symbol.
        
        :param symbol: Ticker symbol
        :param period_type: "day", "month", "year", "ytd"
        :param period: Number of periods
        :return: Price history data or None
        """
        url = f"{self._base_api_url}/marketdata/v1/pricehistory"
        params = {
            'symbol': symbol,
            'periodType': period_type,
            'period': period
        }
        response = self._make_request('GET', url, params)
        
        if response and response.ok:
            return response.json()
        return None


# Test function
def test_connection():
    """Test the Schwab API connection."""
    try:
        from config import APP_KEY, APP_SECRET, CALLBACK_URL, TOKENS_FILE
    except ImportError:
        print("Error: Could not import config. Make sure config.py exists.")
        return False
    
    try:
        client = SchwabClient(
            app_key=APP_KEY,
            app_secret=APP_SECRET,
            callback_url=CALLBACK_URL,
            tokens_file=TOKENS_FILE,
            verbose=True
        )
        
        # Test quote
        print("\nTesting quote for AAPL...")
        quote = client.get_quote("AAPL")
        if quote:
            print(f"AAPL Quote: {json.dumps(quote, indent=2)[:500]}...")
        
        # Test option chain
        print("\nTesting option chain for AAPL...")
        chain = client.get_option_chain("AAPL", strike_count=5)
        if chain:
            print(f"Option chain received. Keys: {list(chain.keys())}")
        
        print("\nConnection test successful!")
        return True
        
    except Exception as e:
        print(f"Connection test failed: {e}")
        return False


if __name__ == "__main__":
    test_connection()

