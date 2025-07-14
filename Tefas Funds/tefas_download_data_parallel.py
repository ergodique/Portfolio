#!/usr/bin/env python3
"""
TEFAS Fon Verisi İndirme (Paralel)
===================================

Bu sürüm mevcut **tefas_download_data.py** mantığını korur ancak fon bazında
paralel indirme yaparak toplam süreyi önemli ölçüde kısaltır.

Paralelleştirme stratejisi
--------------------------
• ThreadPoolExecutor (I/O-ağırlıklı iş) kullanılır.
• Her iş parçası kendi `TefasDataDownloader` örneğini oluşturur → bağımsız
  `requests.Session`, TLS ayarları ve retry mantığı.
• Varsayılan eş-zamanlı iş sayısı: 6 (``--workers`` ile değiştirilebilir).
• TEFAS sunucusundaki olası limitlere uyum sağlamak için 4-8 arası mantıklı.

Kullanım örnekleri
------------------
Tam indirme (tüm fonlar, 6 iş parçacığı):
```
python tefas_download_data_parallel.py --full --workers 6 --months 1
```

Test modu (dört fon, 4 iş parçacığı):
```
python tefas_download_data_parallel.py --test --codes ABC,XYZ,DEF,GHI --months 3 --workers 4
```
"""
from __future__ import annotations

import sys
import logging
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Any

import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq

# Yerel orijinal downloader içe aktarılıyor
from tefas_download_data import TefasDataDownloader  # type: ignore

# ---------------------------------------------------------------------------
# LOGGING – her çalıştırmada ayrı dosya
# ---------------------------------------------------------------------------
log_dir = Path("log")
log_dir.mkdir(exist_ok=True)
log_file = log_dir / f"tefas_download_parallel_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler(log_file, encoding="utf-8"),
        logging.StreamHandler()
    ],
)
logger = logging.getLogger(__name__)
logger.info("CMD: %s", " ".join(sys.argv))

# ---------------------------------------------------------------------------
# Paralel indirme mantığı
# ---------------------------------------------------------------------------

def fetch_single_fund(
    fund: Dict[str, Any],
    years_back: int,
    months_back: int,
) -> List[Dict[str, Any]]:
    """Tek bir fonu indirir ve kayıt listesini döndürür.
    Hata olursa boş liste döner; log içeride yapılır."""
    code = fund["fon_kodu"]
    name = fund["fon_adi"]

    # Her thread bağımsız downloader kullanır
    dl = TefasDataDownloader(
        test_mode=True,  # Fon listesi verildiği için test_mode kullanıyoruz
        years_back=years_back,
        months_back=months_back,
        codes_list=[code],  # Sadece bu fon
        output_filename="",  # çıktıyı thread içinde yazmayacağız
    )

    try:
        history = dl.fetch_fund_history(code, name)
        if history:
            category = dl.get_fund_category(code, name)
            for rec in history:
                rec["fon_kodu"] = code
                rec["fon_kategorisi"] = category
        else:
            logger.warning("[FAIL] %s veri alınamadı", code)
        return history
    except Exception as exc:
        logger.error("[ERROR] %s: %s", code, exc)
        return []


def main() -> None:
    import argparse

    parser = argparse.ArgumentParser(description="TEFAS paralel fon verisi indirme")
    parser.add_argument("--test", action="store_true", help="Test modu (özel fon listesi gerekli)")
    parser.add_argument("--full", action="store_true", help="Tüm fonları indir")
    parser.add_argument("--years", type=int, default=0, help="Kaç yıl geriye gidilecek")
    parser.add_argument("--months", type=int, default=0, help="Kaç ay geriye gidilecek (örn: 1, 6)")
    parser.add_argument("--codes", type=str, default="", help="Virgülle ayrılmış fon kodları (test modu)")
    parser.add_argument("--outfile", type=str, default="", help="Özel çıktı dosyası adı/yolu (opsiyonel)")
    parser.add_argument("--workers", type=int, default=6, help="Eşzamanlı iş parçacığı sayısı (vars. 6)")

    args = parser.parse_args()

    if not (args.test or args.full):
        parser.error("--test veya --full seçeneklerinden birini belirtmelisiniz")

    if args.months > 0 and args.years > 0:
        parser.error("--years ve --months aynı anda kullanılamaz")

    months_back = args.months if args.months > 0 else 0
    years_back = args.years if (args.years > 0 and months_back == 0) else 0

    test_mode = args.test

    # Kod listesi
    codes_list: List[str] = []
    if test_mode:
        if not args.codes:
            parser.error("--test modunda --codes parametresi zorunludur")
        codes_list = [c.strip().upper() for c in args.codes.split(",") if c.strip()]

    # Koordinatör downloader (yalnızca fon listesini almak ve dosya yazmak için)
    coordinator = TefasDataDownloader(
        test_mode=test_mode,
        years_back=years_back,
        months_back=months_back,
        codes_list=codes_list,
        output_filename=args.outfile if args.outfile else None,
    )

    funds = coordinator.get_fund_list()
    logger.info("Toplam %d fon indirilmek üzere kuyruğa alındı", len(funds))

    import time

    def chunked(seq: List[Dict[str, Any]], n: int):
        """Basit chunk yardımcı fonksiyonu"""
        for i in range(0, len(seq), n):
            yield seq[i : i + n]

    all_records: List[Dict[str, Any]] = []
    successful_funds: List[str] = []
    failed_funds: List[str] = []

    total_batches = (len(funds) + args.workers - 1) // args.workers

    for batch_idx, batch in enumerate(chunked(funds, args.workers), 1):
        logger.info("[BATCH %d] %d fon işleniyor", batch_idx, len(batch))

        with ThreadPoolExecutor(max_workers=len(batch)) as executor:
            future_to_code = {
                executor.submit(fetch_single_fund, fund, years_back, months_back): fund["fon_kodu"]
                for fund in batch
            }

            for future in as_completed(future_to_code):
                code = future_to_code[future]
                try:
                    data = future.result()
                    if data:
                        all_records.extend(data)
                        successful_funds.append(code)
                        logger.info("[OK] %s (%d kayıt)", code, len(data))
                    else:
                        failed_funds.append(code)
                except Exception as exc:
                    logger.error("[EXCEPTION] %s: %s", code, exc)
                    failed_funds.append(code)

        percent = batch_idx / total_batches * 100
        logger.info("[BATCH %d/%d - %.1f%%] Tamamlandı. Başarılı fon: %d, Hatalı fon: %d, Toplam kayıt: %d", batch_idx, total_batches, percent, len(successful_funds), len(failed_funds), len(all_records))
        time.sleep(2)

    successful = len(successful_funds)
    if all_records:
        coordinator.save_data(all_records, successful, failed_funds)
    else:
        logger.error("[ERROR] Hiç veri alınamadı!")


if __name__ == "__main__":
    main() 