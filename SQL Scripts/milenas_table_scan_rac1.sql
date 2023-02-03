 SELECT * FROM v$sqlarea 
 WHERE sql_id='11pf8h0jdrayy'
 
/* Formatted on 2006/01/02 17:11 (Formatter Plus v4.8.5) */
SELECT   aid.sys_ins_date, irci.ret_code, irci.dscr, COUNT (*) AS number_
    FROM card.auth_iss_declined aid, card.int_ret_codes_info irci
   WHERE irci.ret_code = aid.int_resp_code
     AND irci.module_id = :"SYS_B_0"
     AND aid.ins_code = :"SYS_B_1"
     AND aid.sys_ins_date = :"SYS_B_2"
GROUP BY aid.sys_ins_date, irci.ret_code, irci.dscr
ORDER BY aid.sys_ins_date ASC

 SELECT * FROM v$sqlarea 
 WHERE sql_id='26nwvzqtmz6dk'
 
/* Formatted on 2006/01/02 17:13 (Formatter Plus v4.8.5) */
SELECT   card_no, rrn, stan, SOURCE, dest, sys_date, sys_entry_date, sys_time,
         sys_entry_time, sys_msec, sys_entry_msec, no_touch_data
    FROM SWITCH.host_conn_trnx_log
   WHERE SOURCE = :"SYS_B_0"
     AND dest = :"SYS_B_1"
     AND (sys_entry_date BETWEEN :"SYS_B_2" AND :"SYS_B_3")
     AND (sys_entry_time BETWEEN :"SYS_B_4" AND :"SYS_B_5")
ORDER BY sys_entry_date, sys_entry_time, sys_entry_msec

 SELECT * FROM v$sqlarea 
 WHERE sql_id='dtfhfyj8b9vh2'
 

/* enq: TM - contention  12097782 wait_time */ 
/* Formatted on 2006/01/02 17:49 (Formatter Plus v4.8.5) */
INSERT INTO hsm.hsm_log
            (ins_code, trnx_date, trnx_time, msg_type, int_code,
             req_source, hsm_no, msg_body, ret_msg_body, prog_resp_time,
             hsm_resp_time, ret_code, int_ret_code, sys_entry_date,
             sys_entry_time, sys_entry_msec, trnx_msec, sys_ins_date,
             sys_ins_time, sys_ins_msec
            )
     VALUES (:ins_code, :trnx_date, :trnx_time, :msg_type, :int_code,
             :req_source, :hsm_no, :msg_body, :ret_msg_body, :prog_resp_time,
             :hsm_resp_time, :ret_code, :int_ret_code, :sys_entry_date,
             :sys_entry_time, :sys_entry_msec, :trnx_msec, :sys_ins_date,
             :sys_ins_time, :sys_ins_msec
            )
			
			
 SELECT * FROM v$sqlarea 
 WHERE sql_id='7hnt6mp4hkn38'
 
/* TOAD.exe */
SELECT ROWID, islem_tarihi, merkez_isyerino, isyerino, mmd_id_name,
       kart_iab_musno, mmd_id_city, calisma_durumu, cinsiyet, medeni_hal,
       ogrenim_durumu, islem_tutari, ciro, hes_gec_net_tutar,
       kart_eklenen_top_puan, kart_kullanilan_top_puan, islem_turu, adet, yil,
       donem, ay, hafta, gun_adi, ay_adi, hafta_gun, yil_gun, ay_hafta,
       bolge_kodu, bolge_adi, kart_number, kart_kime_ait, kart_turu,
       kart_firmasi, kart_tipi, meslek_id, meslek_kodu, yas_grubu, harcama_id,
       harcama_araligi, limit_id, limit_araligi, mmd_id_city_code,
       yas_grubu_id
  FROM owbtarget.uye_dbkkislm_kkimp tbl
  
 

owbruntime.WB_RT_AUDIT

/* Formatted on 2006/01/04 11:41 (Formatter Plus v4.8.5) */
SELECT   sys_ins_date, COUNT (*) AS number_
    FROM card.auth_iss_approved
   WHERE ins_code = :"SYS_B_0" AND sys_ins_date = :"SYS_B_1"
GROUP BY sys_ins_date
ORDER BY sys_ins_date ASC

/* Formatted on 2006/01/04 11:44 (Formatter Plus v4.8.5) */
SELECT   sys_ins_date, COUNT (*) AS number_
    FROM SWITCH.trnx_log
   WHERE auth_resp = :"SYS_B_0" AND sys_ins_date = :"SYS_B_1"
GROUP BY sys_ins_date
ORDER BY sys_ins_date ASC

SELECT * FROM dba_role_privs
WHERE GRANTED_ROLE ='VS_FSUSERS'

DELETE FROM isbdba.session_rules WHERE username IN (SELECT grantee FROM dba_role_privs WHERE GRANTED_ROLE ='VS_FSUSERS')

DROP USER AG47185;

SELECT 'DROP USER '||GRANTEE||' CASCADE;' FROM dba_role_privs
WHERE GRANTED_ROLE ='VS_FSUSERS'