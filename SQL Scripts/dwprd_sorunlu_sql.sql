select /*+ USE_NL(a,b,c,d,k,l,m,n) */
a.musteri_no,
b.sube_kodu as klavuz_sbkd,
a.acik_kapali_kodu,
m.segment,
a.tc_kimlik_no,
a.adi_ilk,
a.adi_iki,
a.soyadi,
a.dogum_tarihi,
a.cinsiyet,
a.medeni_hal,
a.calisma_durumu,
a.meslek_kodu,
a.ogrenim_durumu,
c.ev_adres,
c.ev_il,
c.ev_ilce,
c.ev_semt,
to_number(substr(to_char(c.ev_telefon),1,3)) as evtelkod,
to_number(substr(to_char(c.ev_telefon),4,7)) as evtelno,
c.ev_posta_kodu,
c.is_adres,
c.is_il,
c.is_ilce,
c.is_semt,
c.is_posta_kodu,
to_number(substr(to_char(c.is_telefon),1,3)) as istelkod,
to_number(substr(to_char(c.is_telefon),4,7)) as istelno,
c.istel_dahili,
c.email_adres,
c.haberlesme_adresi,
c.ceptel_hat,
c.ceptel_no,
c.email_durum_kodu,
'-' as sms_perm,
'-' as call_perm,
'-' as spsss_perm,
cast(coalesce(k.DWH_COCUK_SAYISI,'0') as smallint) as cocuk_sayisi,
coalesce(d.toplam_blkl_privia_vasatisi,0) as avg_mat,
coalesce(l.toplam_bakiye,0) as toplam_bakiye,
coalesce(l.toplam_vasati,0) as toplam_vasati,
m.sube_kodu,
n.prov_ver_sube,
n.prov_ver_telno,
n.vkn,
n.durum_kodu,
n.nace_istigal,
n.yon_musteri_no
from
mdstage.MUS_BIREYSEL_MBRTP a
left outer join
mdstage.MVR_HESAP_MHSTD b
on a.musteri_no = b.musteri_no
left outer join
mdstage.MUS_HABERLESME_MHBTP c
on a.musteri_no = c.musteri_no
left outer join
mdstage.MUS_PRIVAVAS_MPVTP d
on a.musteri_no = d.musteri_no
left outer join
mdstage.MUS_DBMUSTRR_MUSTERIR_MMRTD k
on a.musteri_no = k.dwh_musteri_no
left outer join
mdstage.MUS_TOPBAKVAS_MTVTP l
on a.musteri_no = l.musteri_no
left outer join
mdstage.mus_segmentsahipsube_msstp m
on a.musteri_no=m.musteri_no
left outer join
mdstage.frm_firmalar_frmtp n
on a.FIRMA_SUBE_KODU = n.PROV_VER_SUBE and a.FIRMA_TELGRAF_NO = n.PROV_VER_TELNO
