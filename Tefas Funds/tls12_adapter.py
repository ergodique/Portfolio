# tls12_adapter.py
import ssl
from requests.adapters import HTTPAdapter
from urllib3.poolmanager import PoolManager

class TLS12Adapter(HTTPAdapter):
    """Tüm https isteklerini zorla TLS 1.2 ile yapar."""
    def init_poolmanager(self, connections, maxsize, block=False, **kw):
        ctx = ssl.create_default_context()
        ctx.minimum_version = ssl.TLSVersion.TLSv1_2
        ctx.maximum_version = ssl.TLSVersion.TLSv1_2
        self.poolmanager = PoolManager(
            num_pools=connections, maxsize=maxsize,
            block=block, ssl_context=ctx, **kw
        )
