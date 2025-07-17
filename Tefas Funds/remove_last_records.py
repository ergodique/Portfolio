#!/usr/bin/env python3
"""
Her fon için son 2 kaydı silen script (repair mode testi için)
"""

import pandas as pd
import pyarrow.parquet as pq
import pyarrow as pa
import sys
from pathlib import Path

def remove_last_records(input_file, records_to_remove=2):
    """Her fon için son N kaydı sil"""
    
    # Dosya kontrolü
    input_path = Path(input_file)
    if not input_path.exists():
        print(f"HATA: {input_file} dosyası bulunamadı!")
        return False
    
    print(f"Dosya okunuyor: {input_file}")
    
    # Parquet dosyasını oku
    df = pd.read_parquet(input_file)
    print(f"Orijinal kayıt sayısı: {len(df):,}")
    print(f"Fon sayısı: {df['fon_kodu'].nunique()}")
    
    # Her fon için son N kaydı sil
    funds_processed = []
    total_removed = 0
    
    for fund_code in df['fon_kodu'].unique():
        # Bu fonun verilerini al
        fund_data = df[df['fon_kodu'] == fund_code].copy()
        original_count = len(fund_data)
        
        # Tarihe göre sırala (en son tarih en alta gelsin)
        fund_data = fund_data.sort_values('tarih')
        
        # Son N kaydı sil
        if len(fund_data) > records_to_remove:
            fund_data = fund_data.iloc[:-records_to_remove]  # Son N kaydı çıkar
            removed_count = records_to_remove
        else:
            # Eğer fonun total verisi N'den azsa, hepsini sil
            fund_data = fund_data.iloc[:0]  # Boş DataFrame
            removed_count = original_count
        
        # Ana dataframe'den bu fonun verilerini sil ve yeni veriyi ekle
        df = df[df['fon_kodu'] != fund_code]
        if len(fund_data) > 0:
            df = pd.concat([df, fund_data], ignore_index=True)
        
        funds_processed.append({
            'fon_kodu': fund_code,
            'orijinal': original_count,
            'silinen': removed_count,
            'kalan': len(fund_data)
        })
        total_removed += removed_count
    
    # Sonucu sırala
    df = df.sort_values(['fon_kodu', 'tarih']).reset_index(drop=True)
    
    print(f"\nİşlem tamamlandı:")
    print(f"Toplam silinen kayıt: {total_removed:,}")
    print(f"Kalan kayıt sayısı: {len(df):,}")
    
    # Backup dosyası oluştur
    backup_file = input_path.with_suffix('.backup.parquet')
    print(f"Backup oluşturuluyor: {backup_file}")
    
    # Orijinal dosyayı backup'la
    import shutil
    shutil.copy2(input_file, backup_file)
    
    # Güncellenmiş dosyayı yaz
    print(f"Güncellenmiş dosya yazılıyor: {input_file}")
    pq.write_table(
        pa.Table.from_pandas(df),
        input_file,
        compression="zstd"
    )
    
    # Özet rapor
    print(f"\nFon bazlı özet:")
    for fund in funds_processed[:10]:  # İlk 10 fonu göster
        print(f"  {fund['fon_kodu']}: {fund['orijinal']} → {fund['kalan']} ({fund['silinen']} silindi)")
    
    if len(funds_processed) > 10:
        print(f"  ... ve {len(funds_processed)-10} fon daha")
    
    print(f"\nBackup dosyası: {backup_file}")
    print(f"Güncellenmiş dosya: {input_file}")
    print("Repair mode testi için hazır!")
    
    return True

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Kullanım: python remove_last_records.py <parquet_dosyası>")
        print("Örnek: python remove_last_records.py data/tefas_full_2yrs.parquet")
        sys.exit(1)
    
    input_file = sys.argv[1]
    success = remove_last_records(input_file, records_to_remove=2)
    
    if success:
        print("\n✓ İşlem başarılı!")
    else:
        print("\n✗ İşlem başarısız!")
        sys.exit(1) 