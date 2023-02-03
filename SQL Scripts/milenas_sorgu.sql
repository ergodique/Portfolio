SELECT card_no, rrn, stan, SOURCE, dest, sys_date, sys_entry_date, sys_time,
sys_entry_time, sys_msec, sys_entry_msec, no_touch_data, sys_put_date,
sys_put_time, sys_put_msec, sys_ins_date, sys_ins_time, sys_ins_msec,
resp_code
FROM host.host_conn_trnx_log a
WHERE process_date = 20070320
AND (sys_ins_time BETWEEN 160000 AND 160100)
AND SOURCE = 'HO'
AND dest = 'SW';

alter index archive.IX_HOST_CONN_TRNX_TIME2 rebuild partition TRNXLOGPART_20070225;

ALTER SYSTEM FLUSH SHARED_POOL;


EXEC DBMS_STATS.DELETE_TABLE_STATS (
   ownname     => 'ARCHIVE', 
   tabname     => 'HOST_CONN_TRNX_LOG_ARCH', 
   no_invalidate   => FALSE,
   force    => TRUE)
   

SELECT /*+INDEX_ASC (swc_log IX_SWC_LOG_PART) */f2, f37, f11, SOURCE, dest, sys_ins_date, sys_ins_time, sys_ins_msec,
       mod_ui, msg_type, f3_proccode_tran_type, f3_proccode_type_of_acc,
       f3_proccode_to_acc, f32, hst_keep_data, f39, sec_rrn
  FROM SWITCH.swc_log
 WHERE process_date = :process_date
   AND (sys_ins_time BETWEEN 110000 AND 110100)
   AND (SOURCE = 'AA' AND dest = 'BB')
   

SELECT /*+INDEX_ASC (host_conn_trnx_log IX_HOST_CONN_TRNX_TIME)*/ card_no, rrn, stan, SOURCE, dest, sys_date, sys_entry_date, sys_time,
       sys_entry_time, sys_msec, sys_entry_msec, no_touch_data, sys_put_date,
       sys_put_time, sys_put_msec, sys_ins_date, sys_ins_time, sys_ins_msec,
       resp_code
  FROM HOST.host_conn_trnx_log
 WHERE process_date = :process_date 
   AND (sys_ins_time BETWEEN :start_time AND :end_time)
   AND (SOURCE = :SOURCE AND dest = :dest)

SELECT card_no, rrn, stan, SOURCE, dest, sys_date, sys_entry_date, sys_time,
       sys_entry_time, sys_msec, sys_entry_msec, no_touch_data, sys_put_date,
       sys_put_time, sys_put_msec, sys_ins_date, sys_ins_time, sys_ins_msec,
       resp_code
  FROM HOST.host_conn_trnx_log
 WHERE process_date = 20070320 
   AND (sys_ins_time BETWEEN 100100 AND 100200)
   AND (SOURCE = 'AA' AND dest = 'BB');