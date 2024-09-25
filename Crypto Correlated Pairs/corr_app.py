import ccxt
import pandas as pd
import time
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import os
from flask import Flask, render_template_string
import schedule
from datetime import datetime, timedelta, timezone
import threading

# Flask uygulaması
app = Flask(__name__)

# Zaman dilimleri ve karşılık gelen gün sayıları
timeframes = {
    '1 Aylık': 30,
    '3 Aylık': 90,
    '6 Aylık': 180,
    '1 Yıllık': 365
}

# Ortalama korelasyonları saklamak için sözlükler
usdt_avg_corr_dict = {key: None for key in timeframes.keys()}
btc_avg_corr_dict = {key: None for key in timeframes.keys()}

@app.route('/')
def index():
    html = '''
    <html>
    <head>
        <title>Korelasyon Matrisleri</title>
    </head>
    <body>
        {% for timeframe_name in timeframes %}
            <h1>USDT Pariteleri Korelasyon Matrisi - {{ timeframe_name }}</h1>
            {% if usdt_avg_corr[timeframe_name] is not none %}
                <img src="{{ url_for('static', filename='usdt_corr_' + timeframe_name + '.png') }}" alt="USDT Korelasyon Matrisi - {{ timeframe_name }}">
                <h2>Ortalama Korelasyon: {{ usdt_avg_corr[timeframe_name]|round(2) }}</h2>
            {% else %}
                <p>Veriler yükleniyor...</p>
            {% endif %}
            <h1>BTC Pariteleri Korelasyon Matrisi - {{ timeframe_name }}</h1>
            {% if btc_avg_corr[timeframe_name] is not none %}
                <img src="{{ url_for('static', filename='btc_corr_' + timeframe_name + '.png') }}" alt="BTC Korelasyon Matrisi - {{ timeframe_name }}">
                <h2>Ortalama Korelasyon: {{ btc_avg_corr[timeframe_name]|round(2) }}</h2>
            {% else %}
                <p>Veriler yükleniyor...</p>
            {% endif %}
            <hr>
        {% endfor %}
    </body>
    </html>
    '''
    return render_template_string(html, timeframes=timeframes.keys(), usdt_avg_corr=usdt_avg_corr_dict, btc_avg_corr=btc_avg_corr_dict)

def get_since_timestamp(days):
    since = datetime.now(timezone.utc) - timedelta(days=days)
    return int(since.timestamp() * 1000)

def fetch_ohlcv(exchange, symbol, timeframe, since, limit):
    all_ohlcv = []
    while True:
        time.sleep(exchange.rateLimit / 1000)
        ohlcv = exchange.fetch_ohlcv(symbol, timeframe=timeframe, since=since, limit=limit)
        if not ohlcv:
            break
        all_ohlcv.extend(ohlcv)
        since = ohlcv[-1][0] + 1
        if len(ohlcv) < limit:
            break
    if not all_ohlcv:
        return None
    df = pd.DataFrame(all_ohlcv, columns=['timestamp', 'open', 'high', 'low', 'close', 'volume'])
    df['datetime'] = pd.to_datetime(df['timestamp'], unit='ms')
    df.set_index('datetime', inplace=True)
    return df['close']

def fetch_prices(exchange, symbols, days):
    prices = {}
    since = get_since_timestamp(days)
    for symbol in symbols:
        try:
            close_prices = fetch_ohlcv(exchange, symbol, '1d', since, limit=1000)
            if close_prices is not None and len(close_prices) > 0:
                prices[symbol] = close_prices
        except Exception as e:
            print(f"{symbol} verileri alınamadı: {e}")
    if not prices:
        return pd.DataFrame()
    return pd.DataFrame(prices)

def calculate_correlations(prices_df):
    returns = prices_df.pct_change(fill_method=None).dropna()
    corr_matrix = returns.corr()
    avg_corr = corr_matrix.mean().mean()
    return corr_matrix, avg_corr

def plot_correlation_matrix(corr_matrix, title, avg_corr, filename):
    plt.figure(figsize=(12, 10))
    sns.heatmap(corr_matrix, cmap='coolwarm')
    plt.title(f"{title}\nOrtalama Korelasyon: {avg_corr:.2f}")
    plt.tight_layout()
    plt.savefig(f'static/{filename}')
    plt.close()

def job():
    global usdt_avg_corr_dict, btc_avg_corr_dict
    exchange = ccxt.binance({
        'enableRateLimit': True,
        'timeout': 10000,
    })
    try:
        markets = exchange.load_markets()
    except Exception as e:
        print(f"Piyasalar yüklenemedi: {e}")
        return
    symbols = list(markets.keys())

    usdt_pairs = [symbol for symbol in symbols if symbol.endswith('/USDT')]
    btc_pairs = [symbol for symbol in symbols if symbol.endswith('/BTC')]

    # Grafiklerin kaydedileceği 'static' klasörünü oluşturun
    if not os.path.exists('static'):
        os.makedirs('static')

    for timeframe_name, days in timeframes.items():
        print(f"{timeframe_name} verileri çekiliyor...")

        # USDT Pariteleri
        usdt_prices = fetch_prices(exchange, usdt_pairs, days)
        if usdt_prices.empty:
            print(f"{timeframe_name} için USDT pariteleri verileri alınamadı.")
        else:
            usdt_corr, usdt_avg_corr = calculate_correlations(usdt_prices)
            usdt_filename = f'usdt_corr_{timeframe_name}.png'
            plot_correlation_matrix(usdt_corr, f'USDT Pariteleri Korelasyon Matrisi ({timeframe_name})', usdt_avg_corr, usdt_filename)
            usdt_avg_corr_dict[timeframe_name] = usdt_avg_corr

        # BTC Pariteleri
        btc_prices = fetch_prices(exchange, btc_pairs, days)
        if btc_prices.empty:
            print(f"{timeframe_name} için BTC pariteleri verileri alınamadı.")
        else:
            btc_corr, btc_avg_corr = calculate_correlations(btc_prices)
            btc_filename = f'btc_corr_{timeframe_name}.png'
            plot_correlation_matrix(btc_corr, f'BTC Pariteleri Korelasyon Matrisi ({timeframe_name})', btc_avg_corr, btc_filename)
            btc_avg_corr_dict[timeframe_name] = btc_avg_corr

# Schedule ayarları
schedule.every().hour.at(":00").do(job)

if __name__ == '__main__':
    # Flask uygulamasını başlatın
    def run_flask():
        app.run(debug=False, port=5000)

    # Zamanlama döngüsünü başlatın
    def run_scheduler():
        while True:
            schedule.run_pending()
            time.sleep(1)

    # İlk çalıştırmada job() fonksiyonunu ayrı bir iş parçacığında çalıştırın
    def run_initial_job():
        job()

    # İş parçacıkları oluşturun
    flask_thread = threading.Thread(target=run_flask)
    scheduler_thread = threading.Thread(target=run_scheduler)
    job_thread = threading.Thread(target=run_initial_job)

    # İş parçacıklarını başlatın
    flask_thread.start()
    scheduler_thread.start()
    job_thread.start()
