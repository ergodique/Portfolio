SELECT DISTINCT program
FROM v$session
WHERE username='KKM_USER'

SELECT * FROM dba_objects
WHERE object_type='VIEW'
AND object_name LIKE 'DBA_HIST%WAIT%'


SELECT * FROM DBA_HIST_SQLTEXT 
WHERE sql_id='g4up92brt4w1j'

SELECT * FROM v$sqlarea 
WHERE sql_id='923t0qj5ab1nq'

/* w3wp.exe */
SELECT   no_touch_data, trnx_type, f41, f11, f37, card_no, sys_date, sys_time,
         sys_msec, level_id
    FROM SWITCH.host_trnx_log
   WHERE level_id IN (:"SYS_B_0") AND sys_date = :"SYS_B_1"
ORDER BY sys_date DESC, sys_time DESC, sys_msec DESC

SELECT * FROM v$sqlarea
WHERE sql_id='cmvuznakm9swn'

/*w3wp.exe */
SELECT *
  FROM (SELECT   no_touch_data, trnx_type, f41, f11, f37, card_no, sys_date,
                 sys_time, sys_msec, level_id
            FROM SWITCH.host_trnx_log
           WHERE level_id IN (:"SYS_B_0") AND sys_date = :"SYS_B_1"
        ORDER BY sys_date DESC, sys_time DESC, sys_msec DESC)
 WHERE ROWNUM < :"SYS_B_2"

SELECT * FROM v$sqlarea
WHERE sql_id='24h0znrvgss4j'

/* w3wp.exe */
SELECT *
  FROM (SELECT   f2, f37, f11, SOURCE, dest, sys_ins_date, sys_entry_date,
                 sys_ins_time, sys_entry_time, sys_ins_msec, sys_entry_msec,
                 sys_date, sys_time, sys_msec
            FROM SWITCH.swc_log
           WHERE is_valid = :"SYS_B_0"
             AND sys_ins_date = :"SYS_B_1"
             AND SOURCE = :"SYS_B_2"
             AND dest = :"SYS_B_3"
        ORDER BY sys_ins_date DESC,
                 sys_ins_time DESC,
                 sys_ins_msec DESC,
                 f2 DESC,
                 f37 DESC)
 WHERE ROWNUM < :"SYS_B_4"

	   
	   
	    SELECT * FROM v$sqlarea 
 WHERE sql_id='3x6bjkhv5qncg' 
 
/* Formatted on 2006/01/02 17:22 (Formatter Plus v4.8.5) */
SELECT   sys_ins_date, COUNT (*) AS number_
    FROM card.auth_iss_approved
   WHERE ins_code = :"SYS_B_0" AND sys_ins_date = :"SYS_B_1"
GROUP BY sys_ins_date
ORDER BY sys_ins_date ASC

	    SELECT * FROM v$sqlarea 
 WHERE sql_id='bzywhvw4y06v6'
 
/* Formatted on 2006/01/02 17:31 (Formatter Plus v4.8.5) */
SELECT *
  FROM (SELECT   card_no, rrn, stan, SOURCE, dest, sys_date, sys_entry_date,
                 sys_time, sys_entry_time, sys_msec, sys_entry_msec,
                 no_touch_data
            FROM SWITCH.host_conn_trnx_log
           WHERE SOURCE = :"SYS_B_0" AND dest = :"SYS_B_1"
        ORDER BY sys_entry_date DESC, sys_entry_time DESC,
                 sys_entry_msec DESC)
 WHERE ROWNUM < :"SYS_B_2"

/* library cache pin yaþanmýþ 16:50-16:55*/ 
 
 SELECT * FROM v$sqlarea 
 WHERE sql_id='dtfhfyj8b9vh2' 
 
/* Formatted on 2006/01/02 18:02 (Formatter Plus v4.8.5) */
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
			
	/* library cache pin yaþanmýþ 16:50-16:55*/ 	
 SELECT * FROM v$sqlarea 
 WHERE sql_id='1sffw0xnwh67c'
 
INSERT INTO SWITCH.SWC_LOG ( sys_date,sys_time,msg_type,SOURCE,source_ins_code,dest,dest_ins_code,
ntw_id,trnx_code,trnx_sub_code,term_type,cvv2,int_resp_code,f1,f2,f3_proccode_tran_type,f3_proccode_type_of_acc,
f3_proccode_to_acc,f4,f6,f7_date,f7_time,f7_msec,f10,f11,f12,f13,f14,f15,f16,f18,f19,f20,f21,f22_pos_entry_mode,f22_pin_entry_mode,
f25,f26,f28,f32,f33,f35,f37,f38,f39,f41,f42,f43_addr,f43_city,f43_state,f43_country,f44,f45,f49,f50,f51,f54_add_amnts_acc_type,f54_add_amnts_amnt_type,
f54_add_amnts_curr_code,f54_add_amnts_sign,f54_add_amnts_amnt,f64,f66,f70,f74,f75,f76,f77,f78,f79,f80,f81,f83,f85,f86,f87,f88,f89,f91,f95,f96,f97,f99,f101,
sys_msec, mod_ui ,hst_msg_type ,hst_trnx_type ,hst_keep_data,sys_entry_date,sys_entry_time,sys_entry_msec,sys_ins_date,sys_ins_time,sys_ins_msec ) 
VALUES ( :sys_date,:sys_time,:msg_type,
:SOURCE,:source_ins_code,:dest,:dest_ins_code,:ntw_id,:trnx_code,:trnx_sub_code,:term_type,:cvv2,:int_resp_code,:f1,:f2,:f3_proccode_tran_type,:f3_proccode_type_of_acc
 
 SWITCH.SYS_C0077953
 

SELECT * FROM v$sqlarea 
WHERE sql_id='bzywhvw4y06v6'

/* Formatted on 2006/01/03 14:08 (Formatter Plus v4.8.5) */
SELECT *
  FROM (SELECT   card_no, rrn, stan, SOURCE, dest, sys_date, sys_entry_date,
                 sys_time, sys_entry_time, sys_msec, sys_entry_msec,
                 no_touch_data
            FROM SWITCH.host_conn_trnx_log
           WHERE SOURCE = :"SYS_B_0" AND dest = :"SYS_B_1"
        ORDER BY sys_entry_date DESC, sys_entry_time DESC,
                 sys_entry_msec DESC)
 WHERE ROWNUM < :"SYS_B_2"
 
 
/* Formatted on 2006/01/04 16:19 (Formatter Plus v4.8.5) */
SELECT   card_no, rrn, stan, SOURCE, dest, sys_date, sys_entry_date, sys_time,
         sys_entry_time, sys_msec, sys_entry_msec, no_touch_data
    FROM SWITCH.host_conn_trnx_log
   WHERE SOURCE = :"SYS_B_0"
     AND dest = :"SYS_B_1"
     AND (sys_entry_date BETWEEN :"SYS_B_2" AND :"SYS_B_3")
     AND (sys_entry_time BETWEEN :"SYS_B_4" AND :"SYS_B_5")
ORDER BY sys_entry_date, sys_entry_time, sys_entry_msec
 
CARD.AUTH_ISS_APPROVED

SWITCH.HOST_CONN_TRNX_LOG