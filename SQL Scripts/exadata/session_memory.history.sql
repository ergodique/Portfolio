
col plan_opr format a30
col plan_opt format a30
col program format a30
col module format a30
col action format a30
set line 275 pages 1000

select ash.INSTANCE_NUMBER instid, ash.SESSION_ID sid, to_char(ash.SAMPLE_TIME, 'dd-mm-yyyy hh24:mi:ss') sample_time,
       round(ash.PGA_ALLOCATED/(1024*1024),2) pga_alloc_mb, round(ash.TEMP_SPACE_ALLOCATED/(1024*1024),2) temp_alloc_mb,
       ash.SQL_ID, ash.SQL_PLAN_LINE_ID plan_line, ash.SQL_PLAN_OPERATION plan_opr, ash.SQL_PLAN_OPTIONS plan_opt,
       ash.QC_INSTANCE_ID qc_instid, ash.QC_SESSION_ID qc_sid,
       ash.program, ash.module, ash.action,
       substr(st.sql_text, 0, 200) "QUERY TEXT (First 200 chars)"
  from DBA_HIST_ACTIVE_SESS_HISTORY ash, dba_hist_sqltext st
 where ash.sql_id = st.sql_id (+)
   and ash.sample_time between sysdate - 1 and sysdate
   and ash.PGA_ALLOCATED > 100 * 1024 * 1024
  order by ash.INSTANCE_NUMBER, ash.sample_time, ash.PGA_ALLOCATED;
