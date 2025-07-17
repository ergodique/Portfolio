#!/usr/bin/env python3
"""
TEFAS Fon Verisi İndirme Script'i (Merged - Seri & Paralel & Repair)
=====================================================================

Bu script TEFAS'ta bulunan tüm fonların geçmiş fiyat verilerini indirir
ve tek bir parquet dosyasında birleştirir. Seri, paralel ve repair modları destekler.

Seri mod: Fonları tek tek sırayla indirir
Paralel mod: Fonları batch'ler halinde paralel indirir (daha hızlı)
Repair mod: Mevcut dosyadaki eksik tarihleri tespit eder ve sadece eksikleri indirir

Kullanım:
    # Test modu
    python tefas_download_data_merged.py --test --codes ABC,XYZ --workers 1  # Seri
    python tefas_download_data_merged.py --test --codes ABC,XYZ --workers 4  # Paralel  
    
    # Tam veri indirme
    python tefas_download_data_merged.py --full --months 1 --workers 6       # Paralel full
    
    # Repair modu (eksik verileri tamamla)
    python tefas_download_data_merged.py --repair --input data/existing.parquet --workers 4
    python tefas_download_data_merged.py --repair --input data/existing.parquet --workers 1  # Seri repair
"""

import sys
import os
import time
import logging
import argparse
import certifi
from datetime import datetime, timedelta
from dateutil.relativedelta import relativedelta
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import List, Dict, Any, Optional, Tuple
import requests
import pandas as pd
import numpy as np
import random
import json
import urllib3

# SSL warning'lerini kapat
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# ---------------------------------------------------------------------------
# LOGGING SETUP – tek dosya, çoklama problemi yok
# ---------------------------------------------------------------------------
log_dir = Path("log")
log_dir.mkdir(exist_ok=True)
_log_file = log_dir / f"tefas_download_merged_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"

# Logging ayarları – hem dosya hem stdout
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(_log_file, encoding='utf-8'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Komut satırını logla
logger.info("CMD: %s", " ".join(sys.argv))

# Gerekli modülleri import et
import pyarrow as pa
import pyarrow.parquet as pq

from providers.tefas_provider import TefasProvider
from tls12_adapter import TLS12Adapter


class TefasDataDownloaderMerged:
    """TEFAS fon verilerini hem seri hem paralel olarak indiren birleşik sınıf"""
    
    def __init__(self, test_mode=True, years_back=0, months_back=0, codes_list=None, 
                 output_filename=None, workers=1, parallel_mode=None, repair_mode=False, 
                 input_file=None, start_date_str=None, end_date_str=None):
        """
        Args:
            test_mode (bool): True ise sadece belirtilen fon listesi, False ise tüm fonlar
            years_back (int): Kaç yıl geriye gidilecek (opsiyonel)
            months_back (int): Kaç ay geriye gidilecek (opsiyonel)
            codes_list (list[str]|None): Test modunda indirilecek fon kodları listesi
            output_filename (str|None): Parquet çıktısının dosya adı/yolu (varsayılan otomatik)
            workers (int): Paralel işleme için worker sayısı (1 = seri mod)
            parallel_mode (bool|None): Paralel mod zorlaması (None = workers'a göre otomatik)
            repair_mode (bool): True ise mevcut dosyadaki eksikleri tamamlama modu
            input_file (str|None): Repair modunda okunacak mevcut dosya yolu
            start_date_str (str|None): Başlangıç tarihi (YYYY-MM-DD formatında)
            end_date_str (str|None): Bitiş tarihi (YYYY-MM-DD formatında)
        """
        self.test_mode = test_mode
        self.years_back = years_back or 0
        self.months_back = months_back or 0
        self.start_date_str = start_date_str
        self.end_date_str = end_date_str
        self.workers = max(1, workers)  # En az 1 worker
        self.repair_mode = repair_mode
        self.input_file = Path(input_file) if input_file else None
        
        # Paralel mod belirleme
        if parallel_mode is not None:
            self.parallel_mode = parallel_mode
        else:
            self.parallel_mode = self.workers > 1
            
        # Test modu için kullanıcı tarafından verilen fon kodları
        if codes_list:
            self.codes_list = [c.strip().upper() for c in codes_list if c.strip()]
        else:
            self.codes_list = []
            
        self.provider: Optional[TefasProvider] = None
        try:
            self.provider = self._setup_provider()
        except Exception as e:
            logger.error(f"Provider başlatılamadı: {e}")
        
        self.chunk_size_days = 60  # Her istekte 60 günlük veri
        self.request_delay = 3  # İstekler arası bekleme süresi (saniye)
        
        # Dosya yolları
        self.output_dir = Path("data")
        self.output_dir.mkdir(exist_ok=True)

        # Çıktı dosyası
        if output_filename and str(output_filename).strip():
            filename_only = Path(str(output_filename).strip()).name
            self.output_file = self.output_dir / filename_only
        else:
            mode_suffix = "parallel" if self.parallel_mode else "serial"
            self.output_file = self.output_dir / f"tefas_{'test' if test_mode else 'all'}_{mode_suffix}.parquet"
            
        self.progress_file = self.output_dir / "download_progress.json"
        
    def _setup_provider(self):
        """Provider'ı kur veya yenile - daha agresif session management ile"""
        max_attempts = 3
        for attempt in range(max_attempts):
            try:
                provider = TefasProvider()
                
                # Session'ı yenile
                if hasattr(provider, 'session'):
                    provider.session.close()
                
                provider.session = requests.Session()
                provider.session.verify = False
                
                # User-Agent rotation for better stability
                user_agents = [
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
                    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
                    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
                ]
                
                provider.session.headers.update({
                    'User-Agent': random.choice(user_agents),
                    'Accept': 'application/json, text/javascript, */*; q=0.01',
                    'Accept-Language': 'tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7',
                    'Accept-Encoding': 'gzip, deflate, br',
                    'Connection': 'keep-alive',
                    'Cache-Control': 'no-cache',
                    'Pragma': 'no-cache'
                })
                
                # Test connection
                test_url = "https://www.tefas.gov.tr"
                response = provider.session.get(test_url, timeout=10)
                response.raise_for_status()
                
                logger.debug(f"Provider başarıyla kuruldu (deneme {attempt + 1})")
                return provider
                
            except Exception as e:
                logger.warning(f"Session başlatma deneme {attempt + 1}/{max_attempts}: {e}")
                if attempt < max_attempts - 1:
                    time.sleep(2 ** attempt)  # Exponential backoff
                else:
                    logger.error(f"Session başlatılamadı: {e}")
                    raise

    def get_fund_list(self):
        """Takasbank'tan fon listesini al"""
        logger.info("Fon listesi alınıyor...")
        
        if not self.provider:
            self.provider = self._setup_provider()
        
        if not self.provider:
            logger.error("Provider başlatılamadı, fon listesi alınamıyor")
            return []
        
        try:
            all_funds = self.provider._get_takasbank_fund_list()
            if not all_funds:
                logger.warning("Fon listesi boş geldi")
                return []
            
            logger.info(f"Toplam {len(all_funds)} fon bulundu")
            
            # Kod listesi belirtilmişse filtrele
            if self.codes_list:
                filtered_funds = [fund for fund in all_funds 
                                if fund.get('fon_kodu', '').upper() in [code.upper() for code in self.codes_list]]
                logger.info(f"Filtreden {len(filtered_funds)} fon geçti")
                return filtered_funds
            
            return all_funds
            
        except Exception as e:
            logger.error(f"Fon listesi alınamadı: {e}")
            return []

    def clear_session(self):
        """Session'ı temizle ve yenile"""
        logger.debug("Session temizleniyor...")
        if self.provider and hasattr(self.provider, 'session'):
            try:
                self.provider.session.close()
            except:
                pass
        self.provider = self._setup_provider()

    def fetch_fund_chunk(self, fund_code, start_date, end_date, retries=2):
        """Belirli bir tarih aralığında fon verisi al"""
        for attempt in range(retries + 1):
            try:
                time.sleep(self.request_delay)
                
                # Her denemede session'ı yenile
                if attempt > 0:
                    logger.debug(f"{fund_code}: Session yenileniyor...")
                    self.provider.session.get(self.provider.base_url, timeout=10)
                    time.sleep(1)
                
                result = self.provider.get_fund_performance(
                    fund_code, 
                    start_date.strftime("%Y-%m-%d"), 
                    end_date.strftime("%Y-%m-%d")
                )
                
                # Error message kontrolü
                if result.get("error_message"):
                    logger.warning(f"{fund_code}: API hatası: {result['error_message']}")
                    if "No historical data found" in result["error_message"]:
                        logger.warning(f"{fund_code}: {start_date} - {end_date} = veri yok")
                        return []
                    else:
                        raise Exception(result["error_message"])
                
                price_history = result.get("fiyat_geçmisi", [])
                if price_history:
                    logger.debug(f"[CHUNK OK] {fund_code}: {len(price_history)} kayıt ({start_date} - {end_date})")
                    return price_history
                else:
                    logger.warning(f"[CHUNK EMPTY] {fund_code}: Veri yok ({start_date} - {end_date})")
                    return []
                    
            except Exception as e:
                error_msg = str(e)
                
                # Connection Reset hatası için session'ı tamamen yenile
                if "ConnectionResetError" in error_msg or "Connection aborted" in error_msg:
                    logger.warning(f"{fund_code}: Bağlantı kesildi, session tamamen yenileniyor...")
                    self.provider = self._setup_provider()
                
                if attempt < retries:
                    wait_time = 3 + attempt
                    logger.warning(f"[RETRY {attempt+1}/{retries}] {fund_code}: {e}")
                    time.sleep(wait_time)
                else:
                    logger.error(f"[CHUNK FAIL] {fund_code}: {e}")
                    return []
        
        return []

    def get_fund_category(self, fund_code, fund_name):
        """Fon kategorisini API'den al, başarısız olursa adından tahmin et"""
        try:
            if not self.provider:
                self.provider = self._setup_provider()
            
            if not self.provider:
                logger.warning(f"{fund_code}: Provider yok, kategori tahmin edilecek")
                return self._guess_category_from_name(fund_name)
                
            # API'den kategori bilgisini al
            details = self.provider.get_fund_detail_alternative(fund_code)
            if details and 'fon_kategori' in details:
                category = details['fon_kategori']
                if category and category.strip():
                    return category.strip()
        except Exception as e:
            logger.error(f"Error getting fund detail (alternative) for {fund_code}: {e}")
        
        # API başarısız olursa isimden tahmin et
        guessed_category = self._guess_category_from_name(fund_name)
        logger.info(f"{fund_code}: Fon adından tahmin edilen kategori: {guessed_category}")
        return guessed_category

    def _normalize_turkish_text(self, text):
        """Türkçe karakter normalizasyonu"""
        if not text:
            return ""
        replacements = {
            'Ğ': 'G', 'ğ': 'g', 'Ü': 'U', 'ü': 'u', 'Ş': 'S', 'ş': 's',
            'İ': 'I', 'ı': 'i', 'Ö': 'O', 'ö': 'o', 'Ç': 'C', 'ç': 'c'
        }
        for tr, en in replacements.items():
            text = text.replace(tr, en)
        return text.upper()

    def _guess_category_from_name(self, fund_name):
        """Fon adından kategori tahmini - priorite sıralı kurallar"""
        if not fund_name:
            return "Bilinmeyen Şemsiye Fonu"
        
        name_normalized = self._normalize_turkish_text(fund_name)
        
        # ÖNCELIK SIRALI KURALLAR (Kullanıcı gereksinimleri)
        # 1. SERBEST geçiyorsa kesinlikle serbest (SERBEST + DEĞİŞKEN veya SERBEST + KATILIM olsa bile)
        if any(keyword in name_normalized for keyword in ["SERBEST", "FLEXIBLE"]):
            return "Serbest Şemsiye Fonu"
        
        # 2. DEĞİŞKEN geçiyorsa kesinlikle değişken (DEĞİŞKEN + KATILIM olsa bile)
        elif any(keyword in name_normalized for keyword in ["DEGISKEN", "VARIABLE"]):
            return "Değişken Şemsiye Fonu"
        
        # 3. KATILIM geçiyorsa kesinlikle katılım (KATILIM + HİSSE olsa bile)
        elif any(keyword in name_normalized for keyword in ["KATILIM", "PARTICIPATION", "SUKUK"]):
            return "Katılım Şemsiye Fonu"
        
        # DİĞER KATEGORI TANIMLARı (mevcut mantık)
        # 4. YABANCI + HİSSE kombinasyonu (hem YABANCI hem HİSSE geçmeli)
        elif all(keyword in name_normalized for keyword in ["YABANCI", "HISSE"]):
            return "Yabancı Hisse Senedi Şemsiye Fonu"
        elif any(keyword in name_normalized for keyword in ["HISSE", "EQUITY", "STOCK"]):
            return "Hisse Senedi Şemsiye Fonu"
        elif any(keyword in name_normalized for keyword in ["PARA PIYASASI", "MONEY MARKET"]):
            return "Para Piyasası Şemsiye Fonu"
        elif any(keyword in name_normalized for keyword in ["FON SEPETI", "FUND BASKET"]):
            return "Fon Sepeti Şemsiye Fonu"
        elif any(keyword in name_normalized for keyword in ["ALTIN", "GOLD", "GUMUSH", "SILVER", "KIYMETLI"]):
            return "Kıymetli Madenler Şemsiye Fonu"
        # YABANCI + BORCLANMA kombinasyonu veya EURO/EUROBOND
        elif (all(keyword in name_normalized for keyword in ["YABANCI", "BORCLANMA"]) or 
              any(keyword in name_normalized for keyword in ["EURO", "EUROBOND"])):
            return "Eurobond Şemsiye Fonu"
        elif any(keyword in name_normalized for keyword in ["BORCLANMA", "BOND", "TAHVIL"]):
            return "Borçlanma Araçları Şemsiye Fonu"

        else:
            return "Diğer Şemsiye Fonu"

    def fetch_fund_history(self, fund_code, fund_name):
        """Bir fonun tüm geçmiş verilerini al"""
        logger.debug(f"[FETCH] {fund_code} ({fund_name}) verisi alınıyor...")
        
        # Tarih aralığı hesapla
        # Debug: Tarih değerlerini kontrol et
        logger.info(f"[DEBUG] {fund_code}: start_date_str={self.start_date_str}, end_date_str={self.end_date_str}")
        
        # Önce spesifik tarih aralığını kontrol et
        if self.start_date_str and self.end_date_str:
            try:
                start_date = datetime.strptime(self.start_date_str, '%Y-%m-%d')
                end_date = datetime.strptime(self.end_date_str, '%Y-%m-%d')
                logger.info(f"[DEBUG] {fund_code}: spesifik tarih aralığı: {start_date.strftime('%Y-%m-%d')} → {end_date.strftime('%Y-%m-%d')}")
            except ValueError as e:
                logger.error(f"[ERROR] Geçersiz tarih formatı: {e}")
                logger.info(f"[ERROR] Tarih formatı YYYY-MM-DD olmalı (örn: 2025-01-01)")
                raise
        elif self.start_date_str:
            try:
                start_date = datetime.strptime(self.start_date_str, '%Y-%m-%d')
                end_date = datetime.now()
                logger.info(f"[DEBUG] {fund_code}: başlangıç tarihi belirtildi: {start_date.strftime('%Y-%m-%d')} → {end_date.strftime('%Y-%m-%d')}")
            except ValueError as e:
                logger.error(f"[ERROR] Geçersiz başlangıç tarihi formatı: {e}")
                raise
        elif self.end_date_str:
            try:
                end_date = datetime.strptime(self.end_date_str, '%Y-%m-%d')
                start_date = end_date - relativedelta(years=2)  # Varsayılan 2 yıl geriye
                logger.info(f"[DEBUG] {fund_code}: bitiş tarihi belirtildi: {start_date.strftime('%Y-%m-%d')} → {end_date.strftime('%Y-%m-%d')}")
            except ValueError as e:
                logger.error(f"[ERROR] Geçersiz bitiş tarihi formatı: {e}")
                raise
        else:
            # Mevcut months/years mantığı
            end_date = datetime.now()
            
            if self.months_back > 0:
                start_date = end_date - relativedelta(months=self.months_back)
                logger.info(f"[DEBUG] {fund_code}: months_back={self.months_back}, tarih aralığı: {start_date.strftime('%Y-%m-%d')} → {end_date.strftime('%Y-%m-%d')}")
            elif self.years_back > 0:
                start_date = end_date - relativedelta(years=self.years_back)
                logger.info(f"[DEBUG] {fund_code}: years_back={self.years_back}, tarih aralığı: {start_date.strftime('%Y-%m-%d')} → {end_date.strftime('%Y-%m-%d')}")
            else:
                start_date = end_date - relativedelta(years=2)  # Varsayılan 2 yıl
                logger.info(f"[DEBUG] {fund_code}: varsayılan 2 yıl, tarih aralığı: {start_date.strftime('%Y-%m-%d')} → {end_date.strftime('%Y-%m-%d')}")
        
        # Önce belirlenen tarih aralığını dene
        all_data = self._fetch_date_range(fund_code, start_date, end_date, retries=3, allow_gaps=True)
        
        # Eğer veri yoksa (yeni fon olabilir), geriye doğru arama yap
        if not all_data:
            logger.info(f"{fund_code}: Belirlenen tarih aralığında veri yok, geriye doğru aranıyor...")
            all_data = self._fetch_all_available_data(fund_code)
        
        if all_data:
            logger.info(f"[OK] {fund_code}: {len(all_data)} toplam kayıt alındı")
        else:
            logger.warning(f"[FAIL] {fund_code}: Hiç veri alınamadı")
            
        return all_data

    def _fetch_date_range(self, fund_code, start_date, end_date, retries=3, allow_gaps=False):
        """Belirli tarih aralığı için veriyi çek - uzun aralıkları parçalara böler"""
        
        if isinstance(start_date, str):
            start_date = datetime.strptime(start_date, '%Y-%m-%d').date()
        if isinstance(end_date, str):
            end_date = datetime.strptime(end_date, '%Y-%m-%d').date()
        
        # Tarih aralığını hesapla
        total_days = (end_date - start_date).days
        
        # Eğer 4 aydan (120 gün) uzunsa, parçalara böl
        if total_days > 120:
            logger.info(f"[CHUNK] {fund_code}: {total_days} günlük aralığı 3 aylık parçalara bölünüyor...")
            
            all_data = []
            chunk_size = 90  # 3 aylık parçalar
            current_start = datetime.combine(start_date, datetime.min.time())
            end_datetime = datetime.combine(end_date, datetime.min.time())
            
            chunk_count = 0
            while current_start < end_datetime:
                chunk_count += 1
                current_end = min(current_start + timedelta(days=chunk_size), end_datetime)
                
                logger.info(f"[CHUNK {chunk_count}] {fund_code}: {current_start.strftime('%Y-%m-%d')} → {current_end.strftime('%Y-%m-%d')}")
                
                # Bu chunk için veri al
                chunk_data = self._fetch_single_chunk(fund_code, current_start.date(), current_end.date(), retries)
                
                if chunk_data:
                    all_data.extend(chunk_data)
                    logger.info(f"[CHUNK {chunk_count}] {fund_code}: {len(chunk_data)} kayıt alındı")
                else:
                    logger.warning(f"[CHUNK {chunk_count}] {fund_code}: Veri alınamadı")
                
                # Chunk'lar arası delay
                time.sleep(1)
                current_start = current_end + timedelta(days=1)
            
            logger.info(f"[CHUNK TOTAL] {fund_code}: {len(all_data)} toplam kayıt ({chunk_count} parça)")
            return all_data
        
        else:
            # Kısa aralık - direkt al
            return self._fetch_single_chunk(fund_code, start_date, end_date, retries)
    
    def _fetch_single_chunk(self, fund_code, start_date, end_date, retries=3):
        """Tek bir chunk için veri al (orijinal mantık)"""
        for attempt in range(retries):
            try:
                # Rate limiting için delay ekle
                base_delay = 0.5 + (attempt * 0.3)  # Base delay + exponential backoff
                jitter = random.uniform(0.1, 0.3)   # Random jitter
                time.sleep(base_delay + jitter)
                
                # Provider'ı kontrol et ve gerekirse yenile
                if not self.provider:
                    self.provider = self._setup_provider()
                
                if not self.provider:
                    logger.error(f"{fund_code}: Provider başlatılamadı")
                    return []
                
                result = self.provider.get_fund_performance(
                    fund_code=fund_code,
                    start_date=start_date.strftime('%Y-%m-%d'),
                    end_date=end_date.strftime('%Y-%m-%d')
                )
                
                # Error message kontrolü
                if result.get("error_message"):
                    logger.debug(f"{fund_code}: API hatası: {result['error_message']}")
                    if "No historical data found" in result["error_message"]:
                        logger.debug(f"{fund_code}: {start_date} - {end_date} = veri yok")
                        return []
                    else:
                        raise Exception(result["error_message"])
                
                price_history = result.get("fiyat_geçmisi", [])
                if price_history:
                    logger.debug(f"[CHUNK OK] {fund_code}: {len(price_history)} kayıt ({start_date} - {end_date})")
                    return price_history
                else:
                    logger.debug(f"[CHUNK EMPTY] {fund_code}: Veri yok ({start_date} - {end_date})")
                    return []
                    
            except Exception as e:
                if attempt < retries - 1:
                    wait_time = 2 ** attempt  # Exponential backoff: 1, 2, 4 saniye
                    logger.debug(f"[RETRY {attempt+1}/{retries}] {fund_code}: {e}")
                    time.sleep(wait_time)
                else:
                    logger.error(f"[CHUNK FAIL] {fund_code}: {e}")
                    return []
        
        return []

    def _fetch_all_available_data(self, fund_code):
        """Fonun mevcut olan tüm verisini al (yeni fonlar için)"""
        # Geriye doğru küçük aralıklarla dene
        search_periods = [30, 90, 180, 365, 730]  # 1 ay, 3 ay, 6 ay, 1 yıl, 2 yıl
        
        for days in search_periods:
            end_date = datetime.now()
            start_date = end_date - timedelta(days=days)
            
            data = self._fetch_date_range(fund_code, start_date, end_date, retries=3, allow_gaps=True)
            
            if data:
                logger.info(f"{fund_code}: {days} günlük aralıkta {len(data)} kayıt bulundu")
                
                # En eski tarihi bul ve oradan başlayarak tüm veriyi al
                earliest_date = min(pd.to_datetime(record['tarih']) for record in data)
                
                # En eski tarihten bugüne kadar tüm veriyi al
                full_data = self._fetch_date_range(
                    fund_code, 
                    earliest_date - timedelta(days=30),  # Biraz daha erken başla
                    datetime.now(),
                    retries=3,
                    allow_gaps=True
                )
                
                return full_data
        
        return []

    def _fetch_single_fund_data(self, fund: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Tek bir fonu indir ve kayıt listesini döndür (paralel mod için)"""
        code = fund["fon_kodu"]
        name = fund["fon_adi"]

        # Her thread için yeni provider oluştur
        temp_downloader = TefasDataDownloaderMerged(
            test_mode=True,
            years_back=self.years_back,
            months_back=self.months_back,
            codes_list=[code],
            workers=1,  # Thread içinde seri mod
            parallel_mode=False
        )

        try:
            history = temp_downloader.fetch_fund_history(code, name)
            if history:
                category = temp_downloader.get_fund_category(code, name)
                for rec in history:
                    rec["fon_kodu"] = code
                    rec["fon_kategorisi"] = category
                logger.info(f"[OK] {code} ({len(history)} kayıt)")
            else:
                logger.warning(f"[FAIL] {code} veri alınamadı")
            return history or []
        except Exception as exc:
            logger.error(f"[ERROR] {code}: {exc}")
            return []

    def _chunked(self, seq: List[Dict[str, Any]], n: int):
        """Liste chunk'lara böl"""
        for i in range(0, len(seq), n):
            yield seq[i : i + n]

    def process_all_funds_parallel(self):
        """Fonları paralel olarak işle"""
        logger.info("[PARALEL MOD] Başlıyor...")
        
        try:
            funds = self.get_fund_list()
            if not funds:
                logger.error("Fon listesi alınamadı!")
                return
                
            logger.info(f"[START] {len(funds)} fon paralel indirme başlıyor...")
            logger.info(f"Hedef dosya: {self.output_file}")
            logger.info(f"Worker sayısı: {self.workers}")
            
            all_records: List[Dict[str, Any]] = []
            successful_funds: List[str] = []
            failed_funds: List[str] = []
            
            total_batches = (len(funds) + self.workers - 1) // self.workers

            for batch_idx, batch in enumerate(self._chunked(funds, self.workers), 1):
                logger.info(f"[BATCH {batch_idx}] {len(batch)} fon işleniyor")

                with ThreadPoolExecutor(max_workers=len(batch)) as executor:
                    future_to_code = {
                        executor.submit(self._fetch_single_fund_data, fund): fund["fon_kodu"]
                        for fund in batch
                    }

                    try:
                        for future in as_completed(future_to_code):
                            code = future_to_code[future]
                            try:
                                data = future.result()
                                if data:
                                    all_records.extend(data)
                                    successful_funds.append(code)
                                else:
                                    failed_funds.append(code)
                            except Exception as exc:
                                logger.error(f"[EXCEPTION] {code}: {exc}")
                                failed_funds.append(code)
                                
                    except KeyboardInterrupt:
                        logger.info(f"[STOP] Kullanıcı tarafından durduruldu - batch {batch_idx} işlemi sonlandırılıyor...")
                        
                        # Çalışan görevleri iptal et
                        for future in future_to_code:
                            if not future.done():
                                future.cancel()
                        
                        # Executor'ı graceful shutdown yap
                        executor.shutdown(wait=False)
                        
                        # Tamamlanan sonuçları kontrol et
                        for future in future_to_code:
                            if future.done() and not future.cancelled():
                                code = future_to_code[future]
                                try:
                                    data = future.result(timeout=0.1)
                                    if data:
                                        all_records.extend(data)
                                        successful_funds.append(code)
                                    else:
                                        failed_funds.append(code)
                                except Exception:
                                    failed_funds.append(code)
                        
                        logger.info(f"[STOP] O ana kadar {len(successful_funds)} fon tamamlandı")
                        # Batch loop'unu kır
                        break

                percent = batch_idx / total_batches * 100
                logger.info(f"[BATCH {batch_idx}/{total_batches} (%{percent:.1f})] Tamamlandı. Şu ana kadar başarı: {len(successful_funds)}, hata: {len(failed_funds)}")
                time.sleep(2)

            # Sonuçları işle ve kaydet
            if all_records:
                self.save_data(all_records, len(successful_funds), failed_funds)
            else:
                logger.error("[ERROR] Hiç veri alınamadı!")

        except Exception as e:
            logger.error(f"Paralel işlem hatası: {e}")
            raise

    def process_all_funds_serial(self):
        """Fonları seri olarak işle"""
        logger.info("[SERİ MOD] Başlıyor...")
        
        try:
            funds = self.get_fund_list()
            if not funds:
                logger.error("Fon listesi alınamadı!")
                return
                
            logger.info(f"[START] {len(funds)} fon seri indirme başlıyor...")
            logger.info(f"Hedef dosya: {self.output_file}")
            
            all_data = []
            successful_funds = 0
            failed_funds = []
            
            for i, fund in enumerate(funds, 1):
                # Her fon için yeni oturum aç
                self.provider = self._setup_provider()
                time.sleep(1)  # Oturuma nefes aldır

                fund_code = fund['fon_kodu']
                fund_name = fund['fon_adi']
                
                logger.info(f"[{i}/{len(funds)}] İşleniyor: {fund_code}")
                
                try:
                    fund_history = self.fetch_fund_history(fund_code, fund_name)
                    
                    if fund_history:
                        # Kategori bilgisini al
                        fund_category = self.get_fund_category(fund_code, fund_name)
                        if fund_category:
                            logger.debug(f"[CATEGORY] {fund_code}: {fund_category}")
                        
                        # Her kayda fon_kodu ve fon_kategorisi ekle
                        for record in fund_history:
                            record['fon_kodu'] = fund_code
                            record['fon_kategorisi'] = fund_category
                        
                        all_data.extend(fund_history)
                        successful_funds += 1
                        logger.info(f"[OK] {fund_code} başarılı")
                    else:
                        failed_funds.append(fund_code)
                        logger.warning(f"[FAIL] {fund_code} veri alınamadı")
                        
                except KeyboardInterrupt:
                    logger.info("[STOP] Kullanıcı tarafından durduruldu")
                    break
                except Exception as e:
                    failed_funds.append(fund_code)
                    logger.error(f"[ERROR] {fund_code} işlem hatası: {e}")
                
                # Her 5 fondan sonra durum raporu
                if i % 5 == 0:
                    logger.info(f"Durum: {successful_funds}/{i} başarılı, {len(all_data)} toplam kayıt")
            
            # Sonuçları işle ve kaydet
            if all_data:
                self.save_data(all_data, successful_funds, failed_funds)
            else:
                logger.error("[ERROR] Hiç veri alınamadı!")
                
        except Exception as e:
            logger.error(f"Seri işlem hatası: {e}")
            raise

    def analyze_missing_dates(self) -> Dict[str, Tuple[datetime, datetime]]:
        """Mevcut dosyadaki eksik tarihleri analiz eder"""
        if not self.input_file or not self.input_file.exists():
            raise FileNotFoundError(f"Repair modu için geçerli input dosyası gerekli: {self.input_file}")
        
        logger.info(f"[REPAIR] Mevcut veri analiz ediliyor: {self.input_file}")
        
        try:
            # Mevcut veriyi oku (input_file zaten kontrol edildi)
            df = pd.read_parquet(str(self.input_file))
            
            if df.empty:
                logger.warning("Mevcut dosya boş!")
                return {}
            
            # Tarih sütununu datetime'a çevir
            df['tarih'] = pd.to_datetime(df['tarih'])
            
            # Her fon için en son tarihi bul
            fund_last_dates = df.groupby('fon_kodu')['tarih'].max()
            
            # Bugünün tarihi
            today = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
            
            # Eksik aralıkları hesapla
            missing_ranges = {}
            for fund_code, last_date in fund_last_dates.items():
                # En son tarihten bugüne kadar olan süre
                next_date = last_date + timedelta(days=1)
                
                if next_date < today:
                    missing_ranges[fund_code] = (next_date, today)
                    days_missing = (today - next_date).days
                    logger.info(f"[MISSING] {fund_code}: {next_date.strftime('%Y-%m-%d')} - {today.strftime('%Y-%m-%d')} ({days_missing} gün)")
            
            completed_funds = len(fund_last_dates) - len(missing_ranges)
            total_funds = len(fund_last_dates)
            
            logger.info(f"[ANALYSIS] {len(missing_ranges)} tane fon eksik verili. {completed_funds}/{total_funds} tamamlanmış.")
            
            return missing_ranges
            
        except Exception as e:
            logger.error(f"Analiz hatası: {e}")
            raise

    def repair_missing_data(self):
        """Eksik verileri indir ve mevcut dosyaya ekle"""
        logger.info("[REPAIR MODE] Eksik veri tamamlama başlıyor...")
        
        try:
            # Eksik aralıkları analiz et
            missing_ranges = self.analyze_missing_dates()
            
            if not missing_ranges:
                logger.info("[REPAIR] Tüm fonlar güncel! Eksik veri yok.")
                return
            
            logger.info(f"[REPAIR] {len(missing_ranges)} fon için eksik veri indiriliyor...")
            
            # Gerçek fon listesini al (kategori bilgileri için)
            logger.info("[REPAIR] Fon listesi alınıyor...")
            try:
                if not self.provider:
                    self.provider = self._setup_provider()
                if self.provider:
                    full_funds_list = self.provider._get_takasbank_fund_list()
                else:
                    full_funds_list = []
            except Exception as e:
                logger.warning(f"[REPAIR] Fon listesi alınamadı: {e}, kodlar kullanılacak")
                full_funds_list = []
            
            # Fon kodlarını isme eşleştir
            fund_map = {}
            if full_funds_list:
                for fund in full_funds_list:
                    fund_map[fund.get('fon_kodu', '')] = fund.get('fon_adi', '')
                logger.info(f"[REPAIR] {len(fund_map)} fon eşleştirildi")
            
            # Eksik veriler için fonları hazırla
            funds_to_repair = []
            for fund_code in missing_ranges.keys():
                # Gerçek fon adını bul
                real_fund_name = fund_map.get(fund_code, f'Bilinmeyen Fon - {fund_code}')
                funds_to_repair.append({
                    'fon_kodu': fund_code,
                    'fon_adi': real_fund_name
                })
            
            # Her fon için sadece eksik aralığı indir
            all_new_data = []
            successful_repairs = 0
            failed_repairs = []
            
            def repair_single_fund(fund_info):
                """Tek bir fon için repair işlemi"""
                fund_code = fund_info['fon_kodu']
                start_date, end_date = missing_ranges[fund_code]
                
                try:
                    # Bu fon için yeni downloader
                    temp_downloader = TefasDataDownloaderMerged(
                        test_mode=True,
                        codes_list=[fund_code],
                        workers=1,
                        parallel_mode=False
                    )
                    
                    # Request'ler arası delay ekle (rate limiting için)
                    time.sleep(random.uniform(0.5, 1.5))
                    
                    # Sadece eksik aralığı indir
                    new_data = temp_downloader._fetch_date_range(fund_code, start_date, end_date, retries=3, allow_gaps=True)
                    
                    if new_data:
                        # Fon kodunu ve kategorisini ekle
                        category = temp_downloader.get_fund_category(fund_code, fund_info['fon_adi'])
                        for record in new_data:
                            record['fon_kodu'] = fund_code
                            record['fon_kategorisi'] = category
                        
                        logger.info(f"[REPAIR OK] {fund_code}: {len(new_data)} yeni kayıt")
                        return new_data
                    else:
                        logger.warning(f"[REPAIR EMPTY] {fund_code}: Yeni veri bulunamadı")
                        return []
                        
                except Exception as e:
                    logger.error(f"[REPAIR ERROR] {fund_code}: {e}")
                    return []

            # Seri veya paralel mod seçimi
            if self.workers == 1 or not self.parallel_mode:
                # Seri mod - daha güvenli
                logger.info(f"[REPAIR] Seri mod")
                for fund in funds_to_repair:
                    fund_code = fund['fon_kodu']
                    logger.info(f"[REPAIR] {fund_code}: {missing_ranges[fund_code][0]} - {missing_ranges[fund_code][1]}")
                    
                    try:
                        new_data = repair_single_fund(fund)
                        if new_data:
                            all_new_data.extend(new_data)
                            successful_repairs += 1
                        else:
                            failed_repairs.append(fund_code)
                            
                    except KeyboardInterrupt:
                        logger.info("[STOP] Kullanıcı tarafından durduruldu")
                        break
                    except Exception as e:
                        logger.error(f"[REPAIR FAIL] {fund_code}: {e}")
                        failed_repairs.append(fund_code)
            else:
                # Paralel mod
                logger.info(f"[REPAIR] Paralel mod - {self.workers} worker")
                with ThreadPoolExecutor(max_workers=self.workers) as executor:
                    future_to_code = {
                        executor.submit(repair_single_fund, fund): fund['fon_kodu']
                        for fund in funds_to_repair
                    }
                    
                    try:
                        for future in as_completed(future_to_code):
                            fund_code = future_to_code[future]
                            try:
                                new_data = future.result()
                                if new_data:
                                    all_new_data.extend(new_data)
                                    successful_repairs += 1
                                else:
                                    failed_repairs.append(fund_code)
                            except Exception as e:
                                logger.error(f"[REPAIR FAIL] {fund_code}: {e}")
                                failed_repairs.append(fund_code)
                                
                    except KeyboardInterrupt:
                        logger.info("[STOP] Kullanıcı tarafından durduruldu - paralel işlemler sonlandırılıyor...")
                        
                        # Çalışan görevleri iptal et
                        for future in future_to_code:
                            if not future.done():
                                future.cancel()
                        
                        # Executor'ı graceful shutdown yap
                        executor.shutdown(wait=False)
                        
                        # Tamamlanan sonuçları kontrol et
                        for future in future_to_code:
                            if future.done() and not future.cancelled():
                                fund_code = future_to_code[future]
                                try:
                                    new_data = future.result(timeout=0.1)
                                    if new_data:
                                        all_new_data.extend(new_data)
                                        successful_repairs += 1
                                    else:
                                        failed_repairs.append(fund_code)
                                except Exception as e:
                                    failed_repairs.append(fund_code)
                        
                        logger.info(f"[STOP] O ana kadar {successful_repairs} fon tamamlandı")
                        # KeyboardInterrupt'ı yeniden raise et ki ana loop'ta da yakalanabilsin
                        raise
            
            # Yeni verileri mevcut dosyaya ekle
            if all_new_data:
                self.merge_with_existing_data(all_new_data)
                logger.info(f"[REPAIR COMPLETE] {successful_repairs} fon başarıyla güncellendi")
                logger.info(f"[REPAIR STATS] {len(all_new_data)} yeni kayıt eklendi")
            else:
                logger.warning("[REPAIR] Hiç yeni veri indirilemedi!")
            
            if failed_repairs:
                logger.warning(f"[REPAIR FAILED] Başarısız fonlar: {', '.join(failed_repairs)}")
                
        except Exception as e:
            logger.error(f"Repair hatası: {e}")
            raise

    def merge_with_existing_data(self, new_data: List[Dict[str, Any]]):
        """Yeni verileri mevcut dosyaya ekle ve birleştir"""
        logger.info(f"[MERGE] {len(new_data)} yeni kayıt mevcut veriye ekleniyor...")
        
        try:
            # Mevcut veriyi oku (input_file repair modunda None olamaz)
            existing_df = pd.read_parquet(str(self.input_file))
            logger.info(f"[MERGE] Mevcut kayıt sayısı: {len(existing_df)}")
            
            # Yeni veriyi DataFrame'e çevir
            new_df = pd.DataFrame(new_data)
            
            # Tarih sütunlarını datetime'a çevir
            existing_df['tarih'] = pd.to_datetime(existing_df['tarih'])
            new_df['tarih'] = pd.to_datetime(new_df['tarih'])
            
            # Verileri birleştir
            combined_df = pd.concat([existing_df, new_df], ignore_index=True)
            
            # Duplikatları temizle ve sırala
            combined_df = combined_df.drop_duplicates(['fon_kodu', 'tarih']).sort_values(['fon_kodu', 'tarih']).reset_index(drop=True)
            
            # borsa_bulten_fiyat sütununu kaldır (eğer varsa)
            if 'borsa_bulten_fiyat' in combined_df.columns:
                combined_df = combined_df.drop(columns=['borsa_bulten_fiyat'])
            
            # Çıktı dosyasını belirle
            if self.repair_mode:
                # Repair modunda input dosyasının üzerine yaz
                output_file = self.input_file
            else:
                # Normal modda yeni dosya oluştur
                output_file = self.output_file
            
            # Parquet dosyasına yaz
            pq.write_table(
                pa.Table.from_pandas(combined_df),
                output_file,
                compression="zstd"
            )
            
            # İstatistikler
            added_records = len(combined_df) - len(existing_df)
            unique_funds = combined_df['fon_kodu'].nunique()
            date_range = f"{combined_df['tarih'].min().strftime('%Y-%m-%d')} - {combined_df['tarih'].max().strftime('%Y-%m-%d')}"
            
            logger.info("[MERGE SUCCESS] Veri birleştirme tamamlandı!")
            logger.info(f"[FILE] Dosya: {output_file}")
            logger.info(f"[STATS] Toplam kayıt: {len(combined_df):,} (+{added_records:,} yeni)")
            logger.info(f"[FUNDS] Fon sayısı: {unique_funds}")
            logger.info(f"[DATE] Tarih aralığı: {date_range}")
            
        except Exception as e:
            logger.error(f"Merge hatası: {e}")
            raise

    def process_all_funds(self):
        """Ana işlem metodu - mod seçimine göre paralel, seri veya repair"""
        if self.repair_mode:
            self.repair_missing_data()
        elif self.parallel_mode:
            self.process_all_funds_parallel()
        else:
            self.process_all_funds_serial()

    def save_data(self, all_data, successful_funds, failed_funds):
        """Veriyi parquet dosyasına kaydet"""
        logger.info(f"[SAVE] {len(all_data)} kayıt parquet dosyasına yazılıyor...")
        
        try:
            # DataFrame oluştur
            df = pd.DataFrame(all_data)
            
            # borsa_bulten_fiyat sütununu kaldır (eğer varsa)
            if 'borsa_bulten_fiyat' in df.columns:
                df = df.drop(columns=['borsa_bulten_fiyat'])
            
            # Tarih sütununu datetime'a çevir
            df['tarih'] = pd.to_datetime(df['tarih'])
            
            # Sırala ve duplikatları temizle
            df = df.sort_values(['fon_kodu', 'tarih']).drop_duplicates(['fon_kodu', 'tarih']).reset_index(drop=True)
            
            # Parquet dosyasına yaz
            pq.write_table(
                pa.Table.from_pandas(df),
                self.output_file,
                compression="zstd"
            )
            
            # Özet bilgi
            unique_funds = df['fon_kodu'].nunique()
            date_range = f"{df['tarih'].min().strftime('%Y-%m-%d')} - {df['tarih'].max().strftime('%Y-%m-%d')}"
            
            # Kategori başına fon sayısı
            category_counts = df.groupby('fon_kategorisi')['fon_kodu'].nunique().sort_values(ascending=False)  # type: ignore
            
            logger.info("[SUCCESS] İNDİRME TAMAMLANDI!")
            logger.info(f"[FILE] Dosya: {self.output_file}")
            logger.info(f"[STATS] Kayıt sayısı: {len(df):,}")
            logger.info(f"[FUNDS] Fon sayısı: {unique_funds}")
            logger.info(f"[DATE] Tarih aralığı: {date_range}")
            logger.info(f"[OK] Başarılı fonlar: {successful_funds}")
            logger.info(f"[FAIL] Başarısız fonlar: {len(failed_funds)}")
            
            # Kategori dağılımını göster
            if not category_counts.empty:
                logger.info("[CATEGORIES] Fon kategorileri:")
                for category, count in category_counts.head(10).items():
                    if category:
                        logger.info(f"  {category}: {count} fon")
            
            if failed_funds:
                logger.warning(f"Başarısız fonlar: {', '.join(failed_funds[:10])}{'...' if len(failed_funds) > 10 else ''}")
            
        except Exception as e:
            logger.error(f"Kaydetme hatası: {e}")
            raise


def main():
    """Ana fonksiyon"""
    parser = argparse.ArgumentParser(description="TEFAS fon verilerini indir (Seri & Paralel & Repair)")
    parser.add_argument("--test", action="store_true", help="Test modu (özel fon listesi gerekli)")
    parser.add_argument("--full", action="store_true", help="Tüm fonları indir")
    parser.add_argument("--repair", action="store_true", help="Repair modu (mevcut dosyadaki eksikleri tamamla)")
    parser.add_argument("--years", type=int, default=0, help="Kaç yıl geriye gidilecek")
    parser.add_argument("--months", type=int, default=0, help="Kaç ay geriye gidilecek (örn: 1, 6)")
    parser.add_argument("--start-date", type=str, default="", help="Başlangıç tarihi (YYYY-MM-DD formatında)")
    parser.add_argument("--end-date", type=str, default="", help="Bitiş tarihi (YYYY-MM-DD formatında)")
    parser.add_argument("--codes", type=str, default="", help="Virgülle ayrılmış fon kodları (sadece test modu)")
    parser.add_argument("--input", type=str, default="", help="Repair modu için input parquet dosyası")
    parser.add_argument("--outfile", type=str, default="", help="Özel çıktı dosyası adı/yolu (opsiyonel)")
    parser.add_argument("--workers", type=int, default=1, help="Eşzamanlı worker sayısı (1=seri, >1=paralel)")
    
    args = parser.parse_args()
    
    if not (args.test or args.full or args.repair):
        parser.error("--test, --full veya --repair seçeneklerinden birini belirtmelisiniz")
    
    # Repair modu kontrolü
    if args.repair and not args.input:
        parser.error("--repair modunda --input parametresi ile parquet dosyası belirtmelisiniz")
    
    # Parametre kontrolleri
    if args.months > 0 and args.years > 0:
        parser.error("--years ve --months aynı anda kullanılamaz")
    
    # Tarih aralığı ve months/years çakışma kontrolü
    has_date_range = bool(args.start_date or args.end_date)
    has_time_params = args.months > 0 or args.years > 0
    
    if has_date_range and has_time_params:
        parser.error("--start-date/--end-date ile --months/--years aynı anda kullanılamaz")

    months_back = args.months if args.months > 0 else 0
    years_back = args.years if (args.years > 0 and months_back == 0) else 0
    test_mode = args.test
    repair_mode = args.repair
    
    # Test modu için fon kodları
    codes_list = []
    if test_mode and not repair_mode:
        if not args.codes:
            parser.error("--test modunda --codes parametresi ile en az bir fon kodu belirtmelisiniz")
        codes_list = [c.strip().upper() for c in args.codes.split(',') if c.strip()]

    # Çalışma modu belirleme
    parallel_mode = args.workers > 1
    mode_text = f"Paralel ({args.workers} worker)" if parallel_mode else "Seri"
    
    logger.info("=" * 60)
    logger.info("TEFAS Fon Verisi İndirme Script'i (Merged)")
    logger.info("=" * 60)
    if repair_mode:
        logger.info(f"Mod: Repair - {mode_text}")
        logger.info(f"Input dosya: {args.input}")
    else:
        logger.info(f"Mod: {'Test' if test_mode else 'Tam'} - {mode_text}")
        # Tarih aralığı bilgisini göster
        if args.start_date and args.end_date:
            logger.info(f"Tarih aralığı: {args.start_date} → {args.end_date}")
        elif args.start_date:
            logger.info(f"Tarih aralığı: {args.start_date} → günümüz")
        elif args.end_date:
            logger.info(f"Tarih aralığı: 2 yıl geriye → {args.end_date}")
        elif months_back > 0:
            logger.info(f"Tarih aralığı: Son {months_back} ay")
        else:
            years_back_log = years_back if years_back > 0 else 2
            logger.info(f"Tarih aralığı: Son {years_back_log} yıl")
    logger.info("=" * 60)
    
    try:
        downloader = TefasDataDownloaderMerged(
            test_mode=test_mode,
            years_back=years_back,
            months_back=months_back,
            codes_list=codes_list,
            output_filename=args.outfile if args.outfile else None,
            workers=args.workers,
            repair_mode=repair_mode,
            input_file=args.input if repair_mode else None,
            start_date_str=args.start_date if args.start_date else None,
            end_date_str=args.end_date if args.end_date else None
        )
        downloader.process_all_funds()
        
    except KeyboardInterrupt:
        logger.info("[STOP] Kullanıcı tarafından durduruldu")
    except Exception as e:
        logger.error(f"[ERROR] Beklenmedik hata: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main() 