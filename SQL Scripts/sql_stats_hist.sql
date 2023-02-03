/* ALL STATS about all SQL that ran yesterday*/ 
SELECT snap.*,stat.* FROM
(SELECT * FROM DBA_HIST_SNAPSHOT) snap
,(SELECT * FROM DBA_HIST_SQLSTAT) stat
WHERE snap.BEGIN_INTERVAL_TIME BETWEEN TRUNC(SYSDATE-1) AND TRUNC(SYSDATE) 
AND snap.INSTANCE_NUMBER=stat.INSTANCE_NUMBER
AND snap.snap_id= stat.snap_id

/* ALL STATS about all SQL that ran yesterday with sqltext */ 
SELECT sqltext.sql_text, tot_stat.*  FROM (SELECT stat.* FROM
(SELECT * FROM DBA_HIST_SNAPSHOT) snap
,(SELECT * FROM DBA_HIST_SQLSTAT) stat
WHERE snap.BEGIN_INTERVAL_TIME BETWEEN TRUNC(SYSDATE-1) AND TRUNC(SYSDATE) 
AND snap.INSTANCE_NUMBER=stat.INSTANCE_NUMBER
AND snap.snap_id= stat.snap_id) tot_stat, DBA_HIST_SQLTEXT sqltext
WHERE tot_stat.sql_id=sqltext.sql_id

/* Dün çalýþan SQL'ler*/
SELECT GRP_STAT.username
,GRP_STAT.sql_id, GRP_STAT.plan_hash_value
,GRP_STAT.executions
,round(GRP_STAT.fetches/GRP_STAT.executions/1000000,2) fetch_p_ex
,round(GRP_STAT.reads/GRP_STAT.executions/1000000,2) reads_p_ex
,round(GRP_STAT.elapsed_time/1000000,2) elapsed_time_TOT
,round(GRP_STAT.CPU_TIME/1000000,2) CPU_TIME_TOT
,round(GRP_STAT.elapsed_time/GRP_STAT.executions/1000000,2) elapsed_time_p_ex
,round(GRP_STAT.CPU_TIME/GRP_STAT.executions/1000000,2) CPU_TIME_p_ex
,round(GRP_STAT.APP_WAIT/GRP_STAT.executions/1000000,2) APP_WAIT_p_ex
,round(GRP_STAT.CL_WAIT/GRP_STAT.executions/1000000,2) CL_WAIT_p_ex
,round(GRP_STAT.IO_WAIT/GRP_STAT.executions/1000000,2) IO_WAIT_p_ex
,round(GRP_STAT.SORTS/GRP_STAT.executions/1000000,2) SORTS_p_ex
, sqltext.sql_text 
from
(SELECT   u.username
		,tot_stat.sql_id, tot_stat.plan_hash_value
		 , tot_stat.module
		 ,SUM (tot_stat.executions_delta) executions
		 ,SUM (tot_stat.fetches_delta) fetches
 		 ,SUM (tot_stat.disk_reads_delta+tot_stat.buffer_gets_delta) reads
		 ,SUM (tot_stat.elapsed_time_delta) elapsed_time
		 ,SUM (tot_stat.CPU_TIME_DELTA) CPU_TIME
		 ,SUM (tot_stat.APWAIT_DELTA) APP_WAIT
		 ,SUM (tot_stat.CLWAIT_DELTA) CL_WAIT
		 ,SUM (tot_stat.IOWAIT_DELTA) IO_WAIT
		 ,SUM (tot_stat.SORTS_DELTA) SORTS
    FROM (SELECT stat.* FROM (SELECT * FROM dba_hist_snapshot) snap,
                                 (SELECT * FROM dba_hist_sqlstat) stat
                           WHERE snap.begin_interval_time BETWEEN TRUNC (SYSDATE - 1) AND TRUNC (SYSDATE)
                             AND snap.instance_number = stat.instance_number
                             AND snap.snap_id = stat.snap_id) tot_stat , dba_users u
   WHERE u.user_id = tot_stat.parsing_schema_id
--   AND u.username not in ('SYS','SYSTEM','DBSNMP','SYSMAN','XDB')
	 AND u.username in (select username from dba_users where created >  (select created from v$database))
GROUP BY u.username,tot_stat.sql_id,tot_stat.plan_hash_value,tot_stat.module) GRP_STAT, DBA_HIST_SQLTEXT sqltext
WHERE GRP_STAT.sql_id=sqltext.sql_id
and grp_stat.executions>0
order by  GRP_STAT.CPU_TIME desc ,elapsed_time_tot desc,elapsed_time_p_ex desc


/* Dün çalýþan belirli SQL'ler*/
SELECT GRP_STAT.username
,GRP_STAT.sql_id, GRP_STAT.plan_hash_value
,GRP_STAT.executions
,round(GRP_STAT.fetches/GRP_STAT.executions/1000000,2) fetch_p_ex
,round(GRP_STAT.reads/GRP_STAT.executions/1000000,2) reads_p_ex
,round(GRP_STAT.elapsed_time/1000000,2) elapsed_time_TOT
,round(GRP_STAT.elapsed_time/GRP_STAT.executions/1000000,2) elapsed_time_p_ex
,round(GRP_STAT.CPU_TIME/GRP_STAT.executions/1000000,2) CPU_TIME_p_ex
,round(GRP_STAT.APP_WAIT/GRP_STAT.executions/1000000,2) APP_WAIT_p_ex
,round(GRP_STAT.CL_WAIT/GRP_STAT.executions/1000000,2) CL_WAIT_p_ex
,round(GRP_STAT.IO_WAIT/GRP_STAT.executions/1000000,2) IO_WAIT_p_ex
,round(GRP_STAT.SORTS/GRP_STAT.executions/1000000,2) SORTS_p_ex
, sqltext.sql_text 
from
(SELECT   u.username
		,tot_stat.sql_id, tot_stat.plan_hash_value
		 , tot_stat.module
		 ,SUM (tot_stat.executions_delta) executions
		 ,SUM (tot_stat.fetches_delta) fetches
 		 ,SUM (tot_stat.disk_reads_delta+tot_stat.buffer_gets_delta) reads
		 ,SUM (tot_stat.elapsed_time_delta) elapsed_time
		 ,SUM (tot_stat.CPU_TIME_DELTA) CPU_TIME
		 ,SUM (tot_stat.APWAIT_DELTA) APP_WAIT
		 ,SUM (tot_stat.CLWAIT_DELTA) CL_WAIT
		 ,SUM (tot_stat.IOWAIT_DELTA) IO_WAIT
		 ,SUM (tot_stat.SORTS_DELTA) SORTS
    FROM (SELECT stat.* FROM (SELECT * FROM dba_hist_snapshot) snap,
                                 (SELECT * FROM dba_hist_sqlstat) stat
                           WHERE snap.begin_interval_time BETWEEN TRUNC (SYSDATE - 1) AND TRUNC (SYSDATE)
                             AND snap.instance_number = stat.instance_number
                             AND snap.snap_id = stat.snap_id
							 --AND stat.sql_id in ('gnuzzfds2cpzx','cd8sqym6n7ddd','dmv3bhw8k681q') 
                             ) tot_stat ,
         dba_users u
   WHERE u.user_id = tot_stat.parsing_schema_id
   AND u.username in (select username from dba_users where created >  (select created from v$database))
GROUP BY u.username,tot_stat.sql_id,tot_stat.plan_hash_value,tot_stat.module) GRP_STAT, DBA_HIST_SQLTEXT sqltext
WHERE GRP_STAT.sql_id=sqltext.sql_id
and grp_stat.executions>0
order by elapsed_time_p_ex desc, elapsed_time_tot desc


/* Dün çalýþan belirli kullanýcýya ait SQL'ler süreler Milisaniyedir Kullanýcý*/
SELECT GRP_STAT.username
,GRP_STAT.executions
,GRP_STAT.SQL_ID
,GRP_STAT.parse_calls
,round(GRP_STAT.fetches/GRP_STAT.executions,2) fetch_p_ex
,round(GRP_STAT.reads/GRP_STAT.executions,2) reads_p_ex
,round(GRP_STAT.parse_calls/GRP_STAT.executions,2) parse_calls_p_ex
,round(GRP_STAT.elapsed_time/:TIME_FACTOR,2) elapsed_time_TOT
,round(GRP_STAT.elapsed_time/GRP_STAT.executions/:TIME_FACTOR,2) elapsed_time_p_ex
,round(GRP_STAT.CPU_TIME/:TIME_FACTOR,2) CPU_TIME_TOT
,round(GRP_STAT.CPU_TIME/GRP_STAT.executions/:TIME_FACTOR,2) CPU_TIME_p_ex
,round(GRP_STAT.APP_WAIT/GRP_STAT.executions/:TIME_FACTOR,2) APP_WAIT_p_ex
,round(GRP_STAT.CL_WAIT/GRP_STAT.executions/:TIME_FACTOR,2) CL_WAIT_p_ex
,round(GRP_STAT.IO_WAIT/GRP_STAT.executions/:TIME_FACTOR,2) IO_WAIT_p_ex
,round(GRP_STAT.SORTS/GRP_STAT.executions,2) SORTS_p_ex
from
(SELECT   u.username
		,tot_stat.sql_id, tot_stat.plan_hash_value
		 ,SUM (tot_stat.executions_delta) executions
		 ,SUM (tot_stat.fetches_delta) fetches
 		 ,SUM (tot_stat.disk_reads_delta+tot_stat.buffer_gets_delta) reads
		 ,SUM (tot_stat.parse_calls_delta) parse_calls
		 ,SUM (tot_stat.elapsed_time_delta) elapsed_time
		 ,SUM (tot_stat.CPU_TIME_DELTA) CPU_TIME
		 ,SUM (tot_stat.APWAIT_DELTA) APP_WAIT
		 ,SUM (tot_stat.CLWAIT_DELTA) CL_WAIT
		 ,SUM (tot_stat.IOWAIT_DELTA) IO_WAIT
		 ,SUM (tot_stat.SORTS_DELTA) SORTS
    FROM (SELECT stat.* FROM dba_hist_snapshot snap,dba_hist_sqlstat stat
                           WHERE snap.begin_interval_time BETWEEN TRUNC (SYSDATE-1) AND trunc (SYSDATE)
                             AND snap.instance_number = stat.instance_number
                             AND snap.snap_id = stat.snap_id) tot_stat , dba_users u
   WHERE u.user_id = tot_stat.parsing_schema_id
--   AND u.username not in ('SYS','SYSTEM','DBSNMP','SYSMAN','XDB')
	 AND u.username in (select username from dba_users where created >  (select created from v$database))
GROUP BY u.username,tot_stat.sql_id,tot_stat.plan_hash_value) GRP_STAT
where grp_stat.executions>0
--and grp_stat.username='USRLKU'
and grp_stat.username in (select username from dba_users where created >  (select created from v$database))
order by elapsed_time_p_ex desc, elapsed_time_tot desc,GRP_STAT.CPU_TIME desc;

/* Dün çalýþan belirli kullanýcýya ait SQL'ler süreler Milisaniyedir Kullanýcý+Module*/
SELECT GRP_STAT.username
,GRP_STAT.module
,GRP_STAT.SQL_ID
,GRP_STAT.executions
,GRP_STAT.parse_calls
,round(GRP_STAT.fetches/GRP_STAT.executions,2) fetch_p_ex
,round(GRP_STAT.reads/GRP_STAT.executions,2) reads_p_ex
,round(GRP_STAT.parse_calls/GRP_STAT.executions,2) parse_calls_p_ex
,round(GRP_STAT.elapsed_time/:TIME_FACTOR,2) elapsed_time_TOT
,round(GRP_STAT.elapsed_time/GRP_STAT.executions/:TIME_FACTOR,2) elapsed_time_p_ex
,round(GRP_STAT.CPU_TIME/:TIME_FACTOR,2) CPU_TIME_TOT
,round(GRP_STAT.CPU_TIME/GRP_STAT.executions/:TIME_FACTOR,2) CPU_TIME_p_ex
,round(GRP_STAT.APP_WAIT/GRP_STAT.executions/:TIME_FACTOR,2) APP_WAIT_p_ex
,round(GRP_STAT.CL_WAIT/GRP_STAT.executions/:TIME_FACTOR,2) CL_WAIT_p_ex
,round(GRP_STAT.IO_WAIT/GRP_STAT.executions/:TIME_FACTOR,2) IO_WAIT_p_ex
,round(GRP_STAT.SORTS/GRP_STAT.executions,2) SORTS_p_ex
from
(SELECT   u.username
		,tot_stat.sql_id, tot_stat.plan_hash_value
		 , tot_stat.module
		 ,SUM (tot_stat.executions_delta) executions
		 ,SUM (tot_stat.fetches_delta) fetches
 		 ,SUM (tot_stat.disk_reads_delta+tot_stat.buffer_gets_delta) reads
		 ,SUM (tot_stat.parse_calls_delta) parse_calls
		 ,SUM (tot_stat.elapsed_time_delta) elapsed_time
		 ,SUM (tot_stat.CPU_TIME_DELTA) CPU_TIME
		 ,SUM (tot_stat.APWAIT_DELTA) APP_WAIT
		 ,SUM (tot_stat.CLWAIT_DELTA) CL_WAIT
		 ,SUM (tot_stat.IOWAIT_DELTA) IO_WAIT
		 ,SUM (tot_stat.SORTS_DELTA) SORTS
    FROM (SELECT stat.* FROM (SELECT * FROM dba_hist_snapshot) snap,
                                 (SELECT * FROM dba_hist_sqlstat) stat
                           WHERE snap.begin_interval_time BETWEEN TRUNC (SYSDATE-1) AND trunc (SYSDATE)
                             AND snap.instance_number = stat.instance_number
--                             AND stat.sql_id in ('gnuzzfds2cpzx','cd8sqym6n7ddd','dmv3bhw8k681q')
                             AND snap.snap_id = stat.snap_id) tot_stat , dba_users u
   WHERE u.user_id = tot_stat.parsing_schema_id
--   AND u.username not in ('SYS','SYSTEM','DBSNMP','SYSMAN','XDB')
	 AND u.username in (select username from dba_users where created >  (select created from v$database))
GROUP BY u.username,tot_stat.module,tot_stat.sql_id,tot_stat.plan_hash_value) GRP_STAT
where grp_stat.executions>0
and grp_stat.username='USRLKU'
and grp_stat.username in (select username from dba_users where created >  (select created from v$database))
order by elapsed_time_p_ex desc, elapsed_time_tot desc,GRP_STAT.CPU_TIME desc


/* Tarih+Kullanýcý+Module*/
SELECT GRP_STAT.begin_interval_time TARIH
,GRP_STAT.username
,GRP_STAT.module
,GRP_STAT.executions
,GRP_STAT.parse_calls
,round(GRP_STAT.fetches/GRP_STAT.executions,2) fetch_p_ex
,round(GRP_STAT.reads/GRP_STAT.executions,2) reads_p_ex
,round(GRP_STAT.parse_calls/GRP_STAT.executions,2) parse_calls_p_ex
,round(GRP_STAT.elapsed_time/:TIME_FACTOR,2) elapsed_time_TOT
,round(GRP_STAT.elapsed_time/GRP_STAT.executions/:TIME_FACTOR,2) elapsed_time_p_ex
,round(GRP_STAT.CPU_TIME/:TIME_FACTOR,2) CPU_TIME_TOT
,round(GRP_STAT.CPU_TIME/GRP_STAT.executions/:TIME_FACTOR,2) CPU_TIME_p_ex
,round(GRP_STAT.APP_WAIT/GRP_STAT.executions/:TIME_FACTOR,2) APP_WAIT_p_ex
,round(GRP_STAT.CL_WAIT/GRP_STAT.executions/:TIME_FACTOR,2) CL_WAIT_p_ex
,round(GRP_STAT.IO_WAIT/GRP_STAT.executions/:TIME_FACTOR,2) IO_WAIT_p_ex
,round(GRP_STAT.SORTS/GRP_STAT.executions,2) SORTS_p_ex
from
(SELECT  tot_stat.begin_interval_time , 
		 u.username
		,tot_stat.sql_id, tot_stat.plan_hash_value
		 , tot_stat.module
		 ,SUM (tot_stat.executions_delta) executions
		 ,SUM (tot_stat.fetches_delta) fetches
 		 ,SUM (tot_stat.disk_reads_delta+tot_stat.buffer_gets_delta) reads
		 ,SUM (tot_stat.parse_calls_delta) parse_calls
		 ,SUM (tot_stat.elapsed_time_delta) elapsed_time
		 ,SUM (tot_stat.CPU_TIME_DELTA) CPU_TIME
		 ,SUM (tot_stat.APWAIT_DELTA) APP_WAIT
		 ,SUM (tot_stat.CLWAIT_DELTA) CL_WAIT
		 ,SUM (tot_stat.IOWAIT_DELTA) IO_WAIT
		 ,SUM (tot_stat.SORTS_DELTA) SORTS
    FROM (SELECT stat.*,trunc(snap.begin_interval_time) begin_interval_time FROM ( dba_hist_snapshot) snap,
                                 ( dba_hist_sqlstat) stat
                           WHERE snap.begin_interval_time BETWEEN TRUNC (SYSDATE-1) AND  (SYSDATE)
                             AND snap.instance_number = stat.instance_number
  --                           AND stat.sql_id in ('gnuzzfds2cpzx','cd8sqym6n7ddd','dmv3bhw8k681q')
                             AND snap.snap_id = stat.snap_id) tot_stat , dba_users u
   WHERE u.user_id = tot_stat.parsing_schema_id
--   AND u.username not in ('SYS','SYSTEM','DBSNMP','SYSMAN','XDB')
	 AND u.username in (select username from dba_users where created >  (select created from v$database))
GROUP BY tot_stat.begin_interval_time ,u.username,tot_stat.module) GRP_STAT
where grp_stat.executions>0
--and grp_stat.username='FRAUDSTAR'
and grp_stat.username in (select username from dba_users where created >  (select created from v$database))
order by GRP_STAT.username,GRP_STAT.module,GRP_STAT.begin_interval_time,elapsed_time_p_ex desc, elapsed_time_tot desc,GRP_STAT.CPU_TIME desc
