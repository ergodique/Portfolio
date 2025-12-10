"""
Polymarket API Client
Fetches trade history, market data, and positions for a given wallet address.
Supports both sync and async (parallel) fetching for performance.
"""

import asyncio
import requests
from datetime import datetime, timedelta
from typing import Optional
import time

try:
    import aiohttp
    ASYNC_AVAILABLE = True
except ImportError:
    ASYNC_AVAILABLE = False


DATA_API_BASE = "https://data-api.polymarket.com"
GAMMA_API_BASE = "https://gamma-api.polymarket.com"


class PolymarketClient:
    """Client for interacting with Polymarket APIs"""
    
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({
            "Accept": "application/json",
            "User-Agent": "PolymarketAnalytics/1.0"
        })
        self._market_cache = {}
    
    def get_user_trades(
        self,
        wallet_address: str,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        limit: int = 500,
        parallel: int = 1,
        on_progress: callable = None,
        use_market_approach: bool = False
    ) -> list:
        """
        Fetch all trades for a wallet address within a date range.
        
        Args:
            wallet_address: Ethereum wallet address
            start_date: Start of date range (default: 1 month ago)
            end_date: End of date range (default: now)
            limit: Number of records per page
            parallel: Number of parallel requests (1 = sync, >1 = async)
            on_progress: Callback function(trades) called periodically with current data
            use_market_approach: If True, use market-by-market fetching to bypass offset limit
        
        Returns:
            List of trade records
        """
        if end_date is None:
            end_date = datetime.now()
        if start_date is None:
            start_date = end_date - timedelta(days=30)
        
        print(f"Fetching trades for {wallet_address[:10]}...")
        print(f"Date range: {start_date.date()} to {end_date.date()}")
        
        # Use market-by-market approach to bypass offset limit
        if use_market_approach:
            print("Using market-by-market approach to bypass offset limit...")
            return self._get_trades_by_market(wallet_address, start_date, end_date, on_progress)
        
        if parallel > 1 and ASYNC_AVAILABLE:
            print(f"Using parallel mode with {parallel} concurrent requests")
            return self._get_trades_parallel(wallet_address, start_date, end_date, limit, parallel, on_progress)
        else:
            if parallel > 1 and not ASYNC_AVAILABLE:
                print("Warning: aiohttp not installed, falling back to sync mode")
            return self._get_trades_sync(wallet_address, start_date, end_date, limit, on_progress)
    
    def _get_trades_by_market(
        self,
        wallet_address: str,
        start_date: datetime,
        end_date: datetime,
        on_progress: callable = None
    ) -> list:
        """
        HYBRID APPROACH: Combines standard offset-based fetching with market-by-market fetching.
        
        Strategy:
        1. First, use standard method to get the most recent trades (up to offset limit)
        2. Then, get all user positions to find all markets they've traded
        3. For each market, fetch additional trades that might be beyond the offset limit
        4. Merge and deduplicate all results
        
        This ensures we don't miss any trades while also getting trades beyond the offset limit.
        """
        all_trades = []
        seen_trades = set()
        
        # Step 1: First get trades using standard method (up to offset limit)
        print("Step 1: Fetching recent trades using standard method...")
        standard_trades = self._get_trades_sync(wallet_address, start_date, end_date, 500, None)
        
        # Add standard trades to result
        for trade in standard_trades:
            tx_hash = trade.get("transactionHash", "")
            condition_id = trade.get("conditionId", "")
            trade_time = self._parse_timestamp(trade.get("timestamp") or trade.get("created_at"))
            outcome = trade.get("outcome", "")
            size = trade.get("size", 0)
            price = trade.get("price", 0)
            
            trade_key = f"{tx_hash}_{condition_id}_{outcome}_{size}_{price}_{trade_time}"
            
            if trade_key not in seen_trades:
                seen_trades.add(trade_key)
                all_trades.append(trade)
        
        print(f"   Got {len(all_trades)} trades from standard method")
        
        if on_progress:
            on_progress(all_trades)
        
        # Step 2: Get all user positions to find all markets they've traded
        print("Step 2: Getting user positions to find all markets...")
        positions = self._get_all_user_positions(wallet_address)
        
        if not positions:
            print("No positions found. Returning standard method results only.")
            return all_trades
        
        # Get unique condition IDs from positions
        unique_markets = set()
        for pos in positions:
            condition_id = pos.get("conditionId")
            if condition_id:
                unique_markets.add(condition_id)
        
        print(f"   Found {len(unique_markets)} markets from positions")
        
        # ALSO get condition IDs from the trades we already fetched
        # This helps us discover closed/resolved markets that aren't in positions
        for trade in all_trades:
            condition_id = trade.get("conditionId")
            if condition_id and condition_id not in unique_markets:
                unique_markets.add(condition_id)
        
        print(f"   Total unique markets after including trades: {len(unique_markets)}")
        
        # Step 3: Fetch trades for each market (to get trades beyond offset limit)
        print("Step 3: Fetching additional trades from each market...")
        trades_added = 0
        for i, condition_id in enumerate(unique_markets, 1):
            market_trades = self._get_trades_for_market(
                wallet_address, condition_id, start_date, end_date
            )
            
            # Deduplicate - only add trades not already seen
            for trade in market_trades:
                tx_hash = trade.get("transactionHash", "")
                trade_time = self._parse_timestamp(trade.get("timestamp") or trade.get("created_at"))
                outcome = trade.get("outcome", "")
                size = trade.get("size", 0)
                price = trade.get("price", 0)
                
                trade_key = f"{tx_hash}_{condition_id}_{outcome}_{size}_{price}_{trade_time}"
                
                if trade_key not in seen_trades:
                    seen_trades.add(trade_key)
                    all_trades.append(trade)
                    trades_added += 1
            
            if i % 10 == 0 or i == len(unique_markets):
                print(f"   Processed {i}/{len(unique_markets)} markets, {trades_added} additional trades found")
            
            if on_progress:
                on_progress(all_trades)
        
        # Sort by timestamp (newest first)
        all_trades.sort(
            key=lambda x: self._parse_timestamp(x.get("timestamp") or x.get("created_at")) or datetime.min,
            reverse=True
        )
        
        print(f"Total unique trades fetched: {len(all_trades)} ({trades_added} from market-by-market)")
        return all_trades
    
    def _get_all_user_positions(self, wallet_address: str) -> list:
        """Get all user positions with pagination"""
        all_positions = []
        offset = 0
        limit = 500
        
        while True:
            url = f"{DATA_API_BASE}/positions"
            params = {
                "user": wallet_address.lower(),
                "limit": limit,
                "offset": offset,
            }
            
            try:
                response = self.session.get(url, params=params, timeout=30)
                response.raise_for_status()
                data = response.json()
            except requests.exceptions.RequestException as e:
                print(f"Error fetching positions: {e}")
                break
            
            if not data:
                break
            
            all_positions.extend(data)
            
            if len(data) < limit:
                break
            
            offset += limit
        
        return all_positions
    
    def _get_trades_for_market(
        self,
        wallet_address: str,
        condition_id: str,
        start_date: datetime,
        end_date: datetime
    ) -> list:
        """Fetch all trades for a specific market filtered by user and date range"""
        filtered_trades = []
        offset = 0
        limit = 500
        max_offset = 1000  # API limit still applies per market
        
        while offset <= max_offset:
            url = f"{DATA_API_BASE}/trades"
            params = {
                "user": wallet_address.lower(),
                "market": condition_id,
                "limit": limit,
                "offset": offset,
            }
            
            try:
                response = self.session.get(url, params=params, timeout=30)
                response.raise_for_status()
                data = response.json()
            except requests.exceptions.RequestException as e:
                print(f"Error fetching trades for market {condition_id[:10]}...: {e}")
                break
            
            if not data:
                break
            
            # Filter by date range
            for trade in data:
                trade_time = self._parse_timestamp(trade.get("timestamp") or trade.get("created_at"))
                if trade_time and start_date <= trade_time <= end_date:
                    filtered_trades.append(trade)
            
            if len(data) < limit:
                break
            
            offset += limit
        
        return filtered_trades
    
    def _get_trades_sync(
        self,
        wallet_address: str,
        start_date: datetime,
        end_date: datetime,
        limit: int = 500,
        on_progress: callable = None
    ) -> list:
        """
        Synchronous trade fetching.
        Note: API has offset limit of 1000, so we can only fetch ~1500-2000 most recent trades.
        API returns trades in reverse chronological order (newest first).
        """
        all_trades = []
        seen_trades = set()
        offset = 0
        max_offset = 1000
        empty_responses = 0
        consecutive_out_of_range = 0
        
        while True:
            url = f"{DATA_API_BASE}/trades"
            params = {
                "user": wallet_address.lower(),
                "limit": limit,
                "offset": offset,
            }
            
            try:
                response = self.session.get(url, params=params, timeout=30)
                response.raise_for_status()
                data = response.json()
            except requests.exceptions.RequestException as e:
                print(f"Error fetching trades: {e}")
                break
            
            if not data:
                empty_responses += 1
                if empty_responses >= 2:
                    break
                offset += limit
                continue
            
            empty_responses = 0
            filtered_trades = []
            in_range_count = 0
            before_start_count = 0
            after_end_count = 0
            new_trades_this_page = 0
            
            for trade in data:
                tx_hash = trade.get("transactionHash", "")
                trade_time = self._parse_timestamp(trade.get("timestamp") or trade.get("created_at"))
                
                if trade_time:
                    if start_date <= trade_time <= end_date:
                        condition_id = trade.get("conditionId", "")
                        outcome = trade.get("outcome", "")
                        size = trade.get("size", 0)
                        price = trade.get("price", 0)
                        
                        trade_key = f"{tx_hash}_{condition_id}_{outcome}_{size}_{price}_{trade_time}"
                        
                        if trade_key not in seen_trades:
                            filtered_trades.append(trade)
                            seen_trades.add(trade_key)
                            in_range_count += 1
                            new_trades_this_page += 1
                    elif trade_time < start_date:
                        before_start_count += 1
                    elif trade_time > end_date:
                        after_end_count += 1
                else:
                    condition_id = trade.get("conditionId", "")
                    outcome = trade.get("outcome", "")
                    size = trade.get("size", 0)
                    price = trade.get("price", 0)
                    trade_key = f"{tx_hash}_{condition_id}_{outcome}_{size}_{price}"
                    
                    if trade_key not in seen_trades:
                        filtered_trades.append(trade)
                        seen_trades.add(trade_key)
                        in_range_count += 1
                        new_trades_this_page += 1
            
            if in_range_count == 0 and before_start_count > len(data) * 0.8:
                consecutive_out_of_range += 1
                if consecutive_out_of_range >= 5:
                    print(f"Stopping: {consecutive_out_of_range} consecutive pages with mostly trades before start_date")
                    break
            else:
                consecutive_out_of_range = 0
            
            all_trades.extend(filtered_trades)
            
            if on_progress:
                on_progress(all_trades)
            
            if consecutive_out_of_range >= 3:
                break
            
            if offset >= max_offset:
                print(f"Reached API offset limit of {max_offset}. Cannot fetch more trades.")
                break
            
            if new_trades_this_page == 0 and offset >= 500:
                print(f"WARNING: No new trades at offset {offset}. API offset limit may be reached.")
                break
            
            offset += limit
            if offset % 1000 == 0:
                print(f"Fetched {len(all_trades)} unique trades so far (offset: {offset}, new this page: {new_trades_this_page})...")
        
        print(f"Total unique trades fetched: {len(all_trades)}")
        return all_trades
    
    def _get_trades_time_windows(
        self,
        wallet_address: str,
        start_date: datetime,
        end_date: datetime,
        limit: int = 500,
        on_progress: callable = None
    ) -> list:
        """
        Fetch trades by splitting date range into smaller time windows.
        This bypasses the 1000 offset limit by starting from offset=0 for each window.
        """
        from datetime import timedelta
        
        all_trades = []
        seen_trades = set()
        
        window_hours = 6
        current_start = start_date
        window_num = 0
        
        while current_start < end_date:
            window_end = min(current_start + timedelta(hours=window_hours), end_date)
            window_num += 1
            
            print(f"\nWindow {window_num}: {current_start.strftime('%Y-%m-%d %H:%M')} to {window_end.strftime('%Y-%m-%d %H:%M')}")
            
            window_trades = self._get_trades_for_window(
                wallet_address,
                current_start,
                window_end,
                limit,
                seen_trades
            )
            
            all_trades.extend(window_trades)
            
            if on_progress:
                on_progress(all_trades)
            
            current_start = window_end
        
        print(f"\nTotal unique trades fetched across all windows: {len(all_trades)}")
        return all_trades
    
    def _get_trades_for_window(
        self,
        wallet_address: str,
        window_start: datetime,
        window_end: datetime,
        limit: int,
        seen_trades: set
    ) -> list:
        """Fetch trades for a specific time window (max offset 1000)"""
        window_trades = []
        offset = 0
        max_offset = 1000
        empty_responses = 0
        
        while offset <= max_offset:
            url = f"{DATA_API_BASE}/trades"
            params = {
                "user": wallet_address.lower(),
                "limit": limit,
                "offset": offset,
            }
            
            try:
                response = self.session.get(url, params=params, timeout=30)
                response.raise_for_status()
                data = response.json()
            except requests.exceptions.RequestException as e:
                print(f"   Error fetching trades: {e}")
                break
            
            if not data:
                empty_responses += 1
                if empty_responses >= 2:
                    break
                offset += limit
                continue
            
            empty_responses = 0
            filtered_trades = []
            in_window_count = 0
            before_window_count = 0
            
            for trade in data:
                tx_hash = trade.get("transactionHash", "")
                trade_time = self._parse_timestamp(trade.get("timestamp") or trade.get("created_at"))
                
                if trade_time:
                    if window_start <= trade_time <= window_end:
                        condition_id = trade.get("conditionId", "")
                        outcome = trade.get("outcome", "")
                        size = trade.get("size", 0)
                        price = trade.get("price", 0)
                        
                        trade_key = f"{tx_hash}_{condition_id}_{outcome}_{size}_{price}_{trade_time}"
                        
                        if trade_key not in seen_trades:
                            filtered_trades.append(trade)
                            seen_trades.add(trade_key)
                            in_window_count += 1
                    elif trade_time < window_start:
                        before_window_count += 1
                        if before_window_count > len(data) * 0.8 and offset > 0:
                            break
                else:
                    condition_id = trade.get("conditionId", "")
                    outcome = trade.get("outcome", "")
                    size = trade.get("size", 0)
                    price = trade.get("price", 0)
                    trade_key = f"{tx_hash}_{condition_id}_{outcome}_{size}_{price}"
                    
                    if trade_key not in seen_trades:
                        filtered_trades.append(trade)
                        seen_trades.add(trade_key)
                        in_window_count += 1
            
            window_trades.extend(filtered_trades)
            
            if in_window_count == 0 and before_window_count > len(data) * 0.8:
                break
            
            offset += limit
            
            if offset > max_offset:
                break
        
        print(f"   Collected {len(window_trades)} trades from this window")
        return window_trades
    
    def _get_trades_parallel(
        self,
        wallet_address: str,
        start_date: datetime,
        end_date: datetime,
        limit: int = 500,
        max_concurrent: int = 10,
        on_progress: callable = None
    ) -> list:
        """Parallel async trade fetching"""
        return asyncio.run(
            self._async_fetch_all_trades(wallet_address, start_date, end_date, limit, max_concurrent, on_progress)
        )
    
    async def _async_fetch_all_trades(
        self,
        wallet_address: str,
        start_date: datetime,
        end_date: datetime,
        limit: int,
        max_concurrent: int,
        on_progress: callable = None
    ) -> list:
        """Async implementation of parallel fetching with batched pagination"""
        
        all_trades = []
        batch_size = max_concurrent * 2
        current_offset = 0
        reached_start = False
        consecutive_empty = 0
        
        connector = aiohttp.TCPConnector(limit=max_concurrent, force_close=True)
        timeout = aiohttp.ClientTimeout(total=60)
        
        async with aiohttp.ClientSession(connector=connector, timeout=timeout) as session:
            while not reached_start and consecutive_empty < 2:
                offsets = [current_offset + (i * limit) for i in range(batch_size)]
                
                tasks = [self._async_fetch_page(session, wallet_address, offset, limit) for offset in offsets]
                results = await asyncio.gather(*tasks, return_exceptions=True)
                
                batch_trades = []
                empty_count = 0
                
                for i, result in enumerate(results):
                    if isinstance(result, Exception):
                        continue
                    if not result:
                        empty_count += 1
                        continue
                    batch_trades.extend(result)
                
                if empty_count == batch_size:
                    consecutive_empty += 1
                else:
                    consecutive_empty = 0
                
                for trade in batch_trades:
                    trade_time = self._parse_timestamp(trade.get("timestamp") or trade.get("created_at"))
                    if trade_time:
                        if start_date <= trade_time <= end_date:
                            all_trades.append(trade)
                        elif trade_time < start_date:
                            reached_start = True
                
                if on_progress:
                    on_progress(all_trades)
                
                current_offset += batch_size * limit
                
                if len(all_trades) > 0 and len(all_trades) % 5000 < batch_size * limit:
                    print(f"Fetched {len(all_trades)} trades so far (offset: {current_offset})...")
        
        unique_trades = {trade.get("transactionHash", str(id(trade))): trade for trade in all_trades}
        result = list(unique_trades.values())
        
        print(f"Total trades fetched: {len(result)}")
        return result
    
    async def _async_fetch_page(self, session, wallet_address: str, offset: int, limit: int) -> list:
        """Fetch a single page of trades asynchronously"""
        url = f"{DATA_API_BASE}/trades"
        params = {
            "user": wallet_address.lower(),
            "limit": limit,
            "offset": offset,
        }
        
        try:
            async with session.get(url, params=params) as response:
                if response.status == 200:
                    return await response.json()
                else:
                    return []
        except Exception as e:
            print(f"Error fetching offset {offset}: {e}")
            return []
    
    def _estimate_total_trades(self, wallet_address: str) -> int:
        """Estimate total number of trades for a wallet"""
        url = f"{DATA_API_BASE}/trades"
        params = {
            "user": wallet_address.lower(),
            "limit": 1,
            "offset": 50000,
        }
        
        try:
            response = self.session.get(url, params=params, timeout=10)
            if response.status_code == 200:
                data = response.json()
                if data:
                    return 100000
                
            for estimate in [20000, 10000, 5000]:
                params["offset"] = estimate
                response = self.session.get(url, params=params, timeout=10)
                if response.status_code == 200 and response.json():
                    return estimate + 10000
            
            return 5000
        except Exception:
            return 20000
    
    def get_market_info(self, condition_id: str) -> dict:
        """
        Get market information by condition ID.
        
        Args:
            condition_id: Market condition ID
        
        Returns:
            Market information dict
        """
        if condition_id in self._market_cache:
            return self._market_cache[condition_id]
        
        url = f"{GAMMA_API_BASE}/markets"
        params = {"condition_id": condition_id}
        
        try:
            response = self.session.get(url, params=params, timeout=30)
            response.raise_for_status()
            data = response.json()
            
            if data and len(data) > 0:
                market = data[0]
                self._market_cache[condition_id] = market
                return market
        except requests.exceptions.RequestException as e:
            print(f"Error fetching market {condition_id}: {e}")
        
        return {}
    
    def get_market_by_slug(self, slug: str) -> dict:
        """
        Get market information by slug.
        
        Args:
            slug: Market URL slug
        
        Returns:
            Market information dict
        """
        url = f"{GAMMA_API_BASE}/markets/{slug}"
        
        try:
            response = self.session.get(url, timeout=30)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"Error fetching market by slug {slug}: {e}")
            return {}
    
    def get_user_positions(self, wallet_address: str) -> list:
        """
        Get current positions for a wallet.
        
        Args:
            wallet_address: Ethereum wallet address
        
        Returns:
            List of position records
        """
        url = f"{DATA_API_BASE}/positions"
        params = {"user": wallet_address.lower()}
        
        try:
            response = self.session.get(url, params=params, timeout=30)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"Error fetching positions: {e}")
            return []
    
    def get_user_pnl(self, wallet_address: str) -> dict:
        """
        Get PnL summary for a wallet.
        
        Args:
            wallet_address: Ethereum wallet address
        
        Returns:
            PnL summary dict
        """
        url = f"{DATA_API_BASE}/pnl"
        params = {"user": wallet_address.lower()}
        
        try:
            response = self.session.get(url, params=params, timeout=30)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"Error fetching PnL: {e}")
            return {}
    
    def get_events(self, limit: int = 100, active: bool = True) -> list:
        """
        Get list of events/markets.
        
        Args:
            limit: Number of events to fetch
            active: Only fetch active events
        
        Returns:
            List of events
        """
        url = f"{GAMMA_API_BASE}/events"
        params = {
            "limit": limit,
            "active": str(active).lower()
        }
        
        try:
            response = self.session.get(url, params=params, timeout=30)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"Error fetching events: {e}")
            return []
    
    def _parse_timestamp(self, ts) -> Optional[datetime]:
        """Parse various timestamp formats to datetime"""
        if ts is None:
            return None
        
        if isinstance(ts, (int, float)):
            if ts > 1e12:
                ts = ts / 1000
            return datetime.fromtimestamp(ts)
        
        if isinstance(ts, str):
            for fmt in [
                "%Y-%m-%dT%H:%M:%S.%fZ",
                "%Y-%m-%dT%H:%M:%SZ",
                "%Y-%m-%d %H:%M:%S",
                "%Y-%m-%dT%H:%M:%S"
            ]:
                try:
                    return datetime.strptime(ts, fmt)
                except ValueError:
                    continue
        
        return None


def test_client():
    """Test the Polymarket client with a sample wallet"""
    client = PolymarketClient()
    
    test_wallet = "0x6031b6eed1c97e853c6e0f03ad3ce3529351f96d"
    
    print("Testing sync fetch (7 days)...")
    start = time.time()
    trades = client.get_user_trades(
        test_wallet,
        start_date=datetime.now() - timedelta(days=7),
        parallel=1
    )
    sync_time = time.time() - start
    print(f"Sync: Found {len(trades)} trades in {sync_time:.2f}s")
    
    if ASYNC_AVAILABLE:
        print("\nTesting parallel fetch (7 days)...")
        start = time.time()
        trades = client.get_user_trades(
            test_wallet,
            start_date=datetime.now() - timedelta(days=7),
            parallel=10
        )
        async_time = time.time() - start
        print(f"Parallel: Found {len(trades)} trades in {async_time:.2f}s")
        print(f"Speedup: {sync_time/async_time:.1f}x")


if __name__ == "__main__":
    test_client()
