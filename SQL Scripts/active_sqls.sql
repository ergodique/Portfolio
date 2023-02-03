/* SQL details of Active sessions*/
SELECT vs.inst_id,u.NAME username, vs.sid, vs.SERIAL#,vs.BLOCKING_SESSION,vs.MODULE, vs.sql_id
,round(((s.disk_reads+s.buffer_gets)/s.executions),2) read_per_exec 
, round((s.ELAPSED_TIME /s.executions/1000000),2) elapsed_per_Exec_SN 
, round((s.CPU_TIME/s.executions/1000000),2) cpu_per_Exec_SN
, round((s.APPLICATION_WAIT_TIME /s.executions/1000000),2) app_wait_per_Exec_SN
, round((s.CLUSTER_WAIT_TIME  /s.executions/1000000),2) cluster_wait_per_Exec_SN
, round((s.CONCURRENCY_WAIT_TIME   /s.executions/1000000),2) conc_wait_per_Exec_SN
, round((s.USER_IO_WAIT_TIME  /s.executions/1000000),2) user_IO_wait_per_Exec_SN      
,s.sql_text--,  vs.*
  FROM gv$sqlarea s, SYS.USER$ u, gv$session vs --dba_hist_active_sess_history vs 
 WHERE s.parsing_user_id = u.USER# AND vs.status = 'ACTIVE'  
AND s.sql_id = vs.sql_id
and s.EXECUTIONS>0
order by elapsed_per_Exec_SN desc,read_per_exec desc

/* SQL's of Active sessions*/
SELECT vs.inst_id,u.NAME username, vs.sql_id  
,s.sql_text--,  vs.*
  FROM gv$sqlarea s, SYS.USER$ u, gv$session vs --dba_hist_active_sess_history vs 
 WHERE s.parsing_user_id = u.USER# AND vs.status = 'ACTIVE'  
AND s.sql_id = vs.sql_id


SELECT sql_fulltext FROM v$sql
WHERE sql_id='bvhtaa9cdm3df'


/* sessions with parallel slaves*/ 
select * from gv$session where sid in( select distinct qcsid from gv$px_session)

/* details of parallel slaves of a session*/ 
select inst_id,sid,serial#,username,status,PROGRAM,MODULE,SQL_ID,SQL_HASH_VALUE,EVENT,WAIT_CLASS, WAIT_TIME  from gv$session s 
where (inst_id,sid) in (select inst_id,sid from gv$px_session where  sid =250 or qcsid =250)

select * from gv$px_session --where inst_id=1 and qcsid=250