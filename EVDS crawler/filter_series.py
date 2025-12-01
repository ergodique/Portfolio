"""
Excel dosyasindaki belirli seri kodlarini filtreleyip Sheet2'ye basar.
"""
from pathlib import Path

import pandas as pd

# Filtrelenecek seri kodlari
TARGET_CODES = [
    "TP.FG.J0",
    "TP.DK.USD.A.YTL",
    "TP.KTF18",
    "TP.BISTTLREF.ORAN",
    "TP.TG2.Y05",
    "TP.TG2.Y04",
    "TP.YISGUCU2.G8",
    "TP.KFE.TR",
    "TP.KM.G15",
    "TP.KM.G22",
    "TP.KM.G29",
    "TP.KM.G36",
    "TP.KM.G49",
    "TP.TG2.Y01",
    "TP.TG2.Y12",
    "TP.PYASENS.K9",
    "TP.PYASENS.K1",
    "TP.TUFE1YI.T1",
    "TP.KTF10",
    "TP.KTF101",
    "TP.KTF17",
    "TP.KTFTUK",
    "TP.KTFTUK01",
    "TP.EUR.MT06",
    "TP.USD.MT06",
    "TP.TRYTAS.MT06",
    "TP.EURTIC.MT06",
    "TP.USDTIC.MT06",
    "TP.EURTAS.MT06",
    "TP.USDTAS.MT06",
    "TP.TRYTIC.MT06",
    "TP.KAVRAMSAL.HAMM1.INDX",
    "TP.KAVRAMSAL.HAMM2.INDX",
    "TP.KAVRAMSAL.HAMM3.INDX",
    "TP.KAVRAMSAL.ARIM1.INDX",
    "TP.KAVRAMSAL.ARIM2.INDX",
    "TP.KAVRAMSAL.ARIM3.INDX",
    "TP.API.REP.ORT.G1",
    "TP.API.TREP.ORT.G1",
    "TP.PPIBSM",
    "TP.PPIGBTL",
    "TP.AOFOBAP",
    "TP.IHBAP",
    "TP.MK.F.BILESIK.TUM",
    "TP.MK.ISL.HC",
    "TP.MK.ISL.MK",
    "TP.RP03.MYR",
    "TP.RP02.MYT",
    "TP.RP04.MKT",
    "TP.BISTTLREF.DUSUK",
    "TP.BISTTLREF.YUKSEK",
    "TP.BISTTLREF.KAPANIS",
    "TP.AB.B4",
    "TP.AB.B3",
    "TP.AB.B6",
    "TP.UREN.K01.2021",
    "TP.TSANAYMT2021.Y1",
    "TP.GY1.N2",
    "TP.RP01.MYR",
    "TP.ENFBEK.TEA12ENF",
    "TP.ENFBEK.IYA12ENF",
    "TP.TRY.MT01",
    "TP.TRY.MT02",
    "TP.TRY.MT03",
    "TP.TRY.MT04",
    "TP.TRY.MT05",
    "TP.TRY.MT06",
    "TP.APIFON4",
    "TP.APIFON1.TOP",
]


def filter_series(xlsx_path: Path) -> None:
    """
    Excel dosyasini okur, hedef seri kodlarini filtreler ve Sheet2'ye yazar.
    """
    # Mevcut Excel dosyasini oku
    df = pd.read_excel(xlsx_path, sheet_name=0)
    
    print(f"Toplam satir sayisi: {len(df)}")
    print(f"Aranan kod sayisi: {len(TARGET_CODES)}")
    
    # SERIE_CODE sutununda hedef kodlari filtrele
    filtered_df = df[df["SERIE_CODE"].isin(TARGET_CODES)]
    
    print(f"Bulunan satir sayisi: {len(filtered_df)}")
    
    # Bulunamayan kodlari goster
    found_codes = set(filtered_df["SERIE_CODE"].tolist())
    missing_codes = set(TARGET_CODES) - found_codes
    if missing_codes:
        print(f"\nBulunamayan kodlar ({len(missing_codes)}):")
        for code in sorted(missing_codes):
            print(f"  - {code}")
    
    # Excel dosyasina Sheet2 olarak yaz
    with pd.ExcelWriter(xlsx_path, engine="openpyxl", mode="a", if_sheet_exists="replace") as writer:
        filtered_df.to_excel(writer, sheet_name="Sheet2", index=False)
    
    print(f"\nSonuc Sheet2'ye yazildi: {xlsx_path}")


if __name__ == "__main__":
    xlsx_file = Path("data/evds_series_metadata.xlsx")
    
    if not xlsx_file.exists():
        print(f"Hata: {xlsx_file} dosyasi bulunamadi.")
        print("Once main.py'i calistirarak veriyi cekin.")
    else:
        filter_series(xlsx_file)

