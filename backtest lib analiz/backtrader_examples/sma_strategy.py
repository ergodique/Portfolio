"""
Backtrader SMA Crossover Strategy
================================

Bu modül Backtrader kütüphanesinin yeteneklerini test etmek için
geliştirilmiş kapsamlı bir SMA crossover stratejisi içerir.

Strateji Kuralları:
- Alım: Fiyat 20MA'yı yukarı keser VE 200MA üzerinde
- Satım: Fiyat 20MA'yı aşağı keser VE 200MA altında  
- Stop Loss: 2 ATR
- Take Profit: Stop Loss'un 1.5 katı
"""

import backtrader as bt
import backtrader.indicators as btind
from datetime import datetime
import pandas as pd
import os


class SMAStrategy(bt.Strategy):
    """
    SMA Crossover Strategy with ATR-based Risk Management
    
    Bu strateji 20 ve 200 periyotluk hareketli ortalamaları kullanarak
    trend takip sistemi uygular. Risk yönetimi için ATR indikatörü kullanılır.
    """
    
    # Strateji parametreleri
    params = (
        ('sma_fast', 10),           # Hızlı SMA periyodu (10MA)
        ('sma_medium', 50),         # Orta SMA periyodu (50MA)
        ('sma_slow', 200),          # Yavaş SMA periyodu (200MA - trend filtresi)
        ('atr_period', 14),         # ATR periyodu
        ('stop_atr_mult', 2.0),     # Stop loss ATR çarpanı (2 ATR)
        ('tp_mult', 3.0),           # Take profit çarpanı (3 ATR)
        ('printlog', False),        # Log yazdırma kapalı (dosyaya yazılacak)
        ('position_size', 0.95),    # Pozisyon büyüklüğü (sermayenin %95'i)
    )
    
    def __init__(self):
        """Strateji başlatma ve indikatör tanımlamaları."""
        
        # Veri referansları
        self.dataclose = self.datas[0].close
        self.datahigh = self.datas[0].high
        self.datalow = self.datas[0].low
        
        # Hareketli ortalamalar
        self.sma_fast = btind.SimpleMovingAverage(
            self.datas[0], period=self.params.sma_fast
        )
        self.sma_medium = btind.SimpleMovingAverage(
            self.datas[0], period=self.params.sma_medium
        )
        self.sma_slow = btind.SimpleMovingAverage(
            self.datas[0], period=self.params.sma_slow
        )
        
        # ATR indikatörü (risk yönetimi için)
        self.atr = btind.AverageTrueRange(
            self.datas[0], period=self.params.atr_period
        )
        
        # Crossover sinyalleri (10MA ve 50MA arası)
        self.crossover = btind.CrossOver(self.sma_fast, self.sma_medium)
        
        # Trade takip değişkenleri
        self.order = None
        self.buyprice = None
        self.buycomm = None
        self.stop_price = None
        self.target_price = None
        
        # Log için
        self.log_data = []
        
        # Log dosyası oluştur ve temizle
        self.log_file = 'backtest_log.txt'
        # Önceki log dosyasını temizle
        try:
            if os.path.exists(self.log_file):
                os.remove(self.log_file)
        except Exception as e:
            print(f"Log dosyası temizleme hatası: {e}")
        
    def log(self, txt, dt=None, doprint=False):
        """Log fonksiyonu - dosyaya yazar, ekrana basmaz."""
        dt = dt or self.datas[0].datetime.date(0)
        log_message = f'{dt.isoformat()}: {txt}'
        
        # Sadece önemli bilgileri ekrana yazdır (doprint=True olduğunda)
        if doprint:
            print(log_message)
            
        # Tüm logları dosyaya yaz
        try:
            with open(self.log_file, 'a', encoding='utf-8') as f:
                f.write(log_message + '\n')
        except Exception as e:
            print(f"Log yazma hatası: {e}")
            
        # Log verisini sakla
        self.log_data.append({
            'date': dt,
            'message': txt
        })
    
    def notify_order(self, order):
        """Emir durumu bildirimleri."""
        if order.status in [order.Submitted, order.Accepted]:
            return
        
        if order.status in [order.Completed]:
            if order.isbuy():
                self.log(f'ALIM GERÇEKLEŞTİ - Fiyat: {order.executed.price:.2f}, '
                        f'Maliyet: {order.executed.value:.2f}, '
                        f'Komisyon: {order.executed.comm:.2f}')
                self.buyprice = order.executed.price
                self.buycomm = order.executed.comm
                
                # Stop loss ve take profit hesapla
                atr_value = self.atr[0]
                self.stop_price = self.buyprice - (self.params.stop_atr_mult * atr_value)
                stop_distance = self.buyprice - self.stop_price
                self.target_price = self.buyprice + (stop_distance * self.params.tp_mult)
                
                self.log(f'Stop Loss: {self.stop_price:.2f}, Take Profit: {self.target_price:.2f}')
                
            else:  # Satış
                self.log(f'SATIM GERÇEKLEŞTİ - Fiyat: {order.executed.price:.2f}, '
                        f'Maliyet: {order.executed.value:.2f}, '
                        f'Komisyon: {order.executed.comm:.2f}')
                
        elif order.status in [order.Canceled, order.Margin, order.Rejected]:
            self.log('Emir İptal/Reddedildi')
        
        self.order = None
    
    def notify_trade(self, trade):
        """Trade bildirimleri."""
        if not trade.isclosed:
            return
        
        self.log(f'TRADE KAPANDI - Brüt P&L: {trade.pnl:.2f}, Net P&L: {trade.pnlcomm:.2f}')
    
    def next(self):
        """Her bar için çalışan ana strateji mantığı."""
        
        # Bekleyen emir varsa bekle
        if self.order:
            return
        
        # Mevcut pozisyon kontrolü
        if not self.position:
            # Pozisyon yok - alım sinyali ara
            
            # Alım koşulları:
            # 1. Fiyat 200MA üzerinde (uptrend filtresi)
            # 2. 10MA, 50MA'yı yukarı keser
            if (self.dataclose[0] > self.sma_slow[0] and  # Fiyat 200MA üzerinde
                self.crossover > 0):  # 10MA, 50MA'yı yukarı keser
                
                # Pozisyon büyüklüğü hesapla
                size = int((self.broker.getcash() * self.params.position_size) / self.dataclose[0])
                
                if size > 0:
                    self.log(f'ALIM SİNYALİ - Fiyat: {self.dataclose[0]:.2f}, '
                            f'10MA: {self.sma_fast[0]:.2f}, 50MA: {self.sma_medium[0]:.2f}, 200MA: {self.sma_slow[0]:.2f}')
                    
                    self.order = self.buy(size=size)
        
        else:
            # Pozisyon var - çıkış sinyalleri kontrol et
            
            current_price = self.dataclose[0]
            
            # Stop loss kontrolü
            if self.stop_price and current_price <= self.stop_price:
                self.log(f'STOP LOSS TETİKLENDİ - Fiyat: {current_price:.2f}, Stop: {self.stop_price:.2f}')
                self.order = self.sell()
                return
            
            # Take profit kontrolü
            if self.target_price and current_price >= self.target_price:
                self.log(f'TAKE PROFIT TETİKLENDİ - Fiyat: {current_price:.2f}, Target: {self.target_price:.2f}')
                self.order = self.sell()
                return
            
            # Trend değişimi sinyali (satım)
            # Fiyat 200MA altında VE 10MA, 50MA'yı aşağı keser
            if (self.dataclose[0] < self.sma_slow[0] and  # Fiyat 200MA altında
                self.crossover < 0):  # 10MA, 50MA'yı aşağı keser
                
                self.log(f'SATIM SİNYALİ - Fiyat: {self.dataclose[0]:.2f}, '
                        f'10MA: {self.sma_fast[0]:.2f}, 50MA: {self.sma_medium[0]:.2f}, 200MA: {self.sma_slow[0]:.2f}')
                
                self.order = self.sell()
    
    def stop(self):
        """Backtest bitiminde çalışan fonksiyon."""
        self.log('BACKTEST TAMAMLANDI', doprint=True)


class OptimizedSMAStrategy(SMAStrategy):
    """
    Optimizasyon için parametreli SMA stratejisi.
    
    Bu sınıf, farklı parametre kombinasyonlarını test etmek için
    temel SMA stratejisini genişletir.
    """
    
    params = (
        ('sma_fast', 10),
        ('sma_medium', 50),
        ('sma_slow', 200),
        ('atr_period', 14),
        ('stop_atr_mult', 2.0),     # Stop loss ATR çarpanı (2 ATR)
        ('tp_mult', 3.0),           # Take profit çarpanı (3 ATR)
        ('printlog', False),        # Optimizasyon sırasında log kapalı
        ('position_size', 0.95),
    )
    
    def stop(self):
        """Optimizasyon için sadece temel metrikleri döndür."""
        win_rate = (self.win_count / self.trade_count * 100) if self.trade_count > 0 else 0
        
        # Optimizasyon sonuçları için
        self.stats = {
            'total_trades': self.trade_count,
            'win_trades': self.win_count,
            'lose_trades': self.lose_count,
            'win_rate': win_rate,
            'total_pnl': self.total_pnl,
            'final_value': self.broker.getvalue(),
            'return_pct': ((self.broker.getvalue() / self.broker.startingcash) - 1) * 100
        }


# Yardımcı fonksiyonlar
def add_analyzers(cerebro):
    """Backtrader analizörlerini ekle."""
    
    # Temel analizörler
    cerebro.addanalyzer(bt.analyzers.TradeAnalyzer, _name="trades")
    cerebro.addanalyzer(bt.analyzers.SharpeRatio, _name="sharpe")
    cerebro.addanalyzer(bt.analyzers.DrawDown, _name="drawdown")
    cerebro.addanalyzer(bt.analyzers.Returns, _name="returns")
    cerebro.addanalyzer(bt.analyzers.SQN, _name="sqn")
    
    # Gelişmiş analizörler
    cerebro.addanalyzer(bt.analyzers.VWR, _name="vwr")  # Variability-Weighted Return
    cerebro.addanalyzer(bt.analyzers.Calmar, _name="calmar")  # Calmar Ratio
    cerebro.addanalyzer(bt.analyzers.TimeReturn, _name="timereturn")
    
    return cerebro


def print_analysis_results(results):
    """Analiz sonuçlarını yazdır."""
    
    strat = results[0]
    
    print("\n" + "="*60)
    print("DETAYLI ANALİZ SONUÇLARI")
    print("="*60)
    
    # Trade analizi
    trade_analysis = strat.analyzers.trades.get_analysis()
    print(f"\n📊 TRADE ANALİZİ:")
    print(f"   Toplam Trade: {trade_analysis.total.total if 'total' in trade_analysis else 0}")
    print(f"   Kazanan Trade: {trade_analysis.won.total if 'won' in trade_analysis else 0}")
    print(f"   Kaybeden Trade: {trade_analysis.lost.total if 'lost' in trade_analysis else 0}")
    
    if 'won' in trade_analysis and 'lost' in trade_analysis:
        win_rate = (trade_analysis.won.total / trade_analysis.total.total) * 100
        print(f"   Kazanma Oranı: {win_rate:.1f}%")
        
        if trade_analysis.won.total > 0:
            print(f"   Ortalama Kazanç: {trade_analysis.won.pnl.average:.2f}")
        if trade_analysis.lost.total > 0:
            print(f"   Ortalama Zarar: {trade_analysis.lost.pnl.average:.2f}")
    
    # Sharpe Ratio
    sharpe = strat.analyzers.sharpe.get_analysis()
    if 'sharperatio' in sharpe and sharpe['sharperatio'] is not None:
        print(f"\n📈 SHARPE RATIO: {sharpe['sharperatio']:.3f}")
    else:
        print(f"\n📈 SHARPE RATIO: Hesaplanamadı (yetersiz veri)")
    
    # Drawdown analizi
    drawdown = strat.analyzers.drawdown.get_analysis()
    print(f"\n📉 DRAWDOWN ANALİZİ:")
    print(f"   Maksimum Drawdown: {drawdown.max.drawdown:.2f}%")
    print(f"   En Uzun Drawdown: {drawdown.max.len} gün")
    
    # Returns
    returns = strat.analyzers.returns.get_analysis()
    if 'rtot' in returns:
        print(f"\n💰 GETİRİ ANALİZİ:")
        print(f"   Toplam Getiri: {returns['rtot']:.2f}%")
        print(f"   Ortalama Getiri: {returns['ravg']:.4f}%")
    
    # SQN (System Quality Number)
    sqn = strat.analyzers.sqn.get_analysis()
    if 'sqn' in sqn:
        print(f"\n🎯 SİSTEM KALİTE NUMARASI (SQN): {sqn['sqn']:.2f}")
        
        # SQN yorumlama
        sqn_value = sqn['sqn']
        if sqn_value >= 3.0:
            sqn_rating = "Mükemmel"
        elif sqn_value >= 2.5:
            sqn_rating = "Çok İyi"
        elif sqn_value >= 2.0:
            sqn_rating = "İyi"
        elif sqn_value >= 1.6:
            sqn_rating = "Ortalama"
        else:
            sqn_rating = "Zayıf"
        
        print(f"   SQN Değerlendirme: {sqn_rating}")
    
    print("="*60)


if __name__ == "__main__":
    print("SMA Strategy modülü - Backtrader test stratejisi")
    print("Bu modül main backtest script tarafından kullanılır.")