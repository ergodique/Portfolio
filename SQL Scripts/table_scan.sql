--IO_COST degeri yuksek table scan yapan Kullanici ve Tablolara ait bilgiler 

select GRP_STAT.username,GRP_STAT.object_owner ,GRP_STAT.object_name
,sum(GRP_STAT.executions) executions
,sum(GRP_STAT.reads) reads
,sum(GRP_STAT.disk_reads) disk_reads
,sum(GRP_STAT.buffer_gets) buffer_gets
,'%'||round(avg(BUFFER_HIT),3) BUFFER_HIT
,round(sum(GRP_STAT.elapsed_time)/1000000,3) elapsed_time
,round(sum(GRP_STAT.CPU_TIME)/1000000,3) CPU_TIME
,round(sum(GRP_STAT.CL_WAIT)/1000000,3) CL_WAIT
,round(sum(GRP_STAT.IO_WAIT)/1000000,3) IO_WAIT
,round(sum(GRP_STAT.APP_WAIT)/1000000,3) APP_WAIT
 from 
(SELECT   u.username, table_scan.object_owner, table_scan.object_name,
         table_scan.sql_id, table_scan.plan_hash_value, table_scan.COST,
         table_scan.cpu_cost, table_scan.io_cost, table_scan.module
                 ,SUM (table_scan.executions_delta) executions
                 ,SUM (table_scan.fetches_delta) fetches
                 ,SUM (table_scan.disk_reads_delta+table_scan.buffer_gets_delta) reads
                 ,SUM (table_scan.disk_reads_delta) disk_reads
                 ,SUM (table_scan.buffer_gets_delta) buffer_gets
                 ,(table_scan.buffer_gets_delta/(table_scan.disk_reads_delta+table_scan.buffer_gets_delta))*100 BUFFER_HIT
                 ,SUM (table_scan.elapsed_time_delta) elapsed_time
                 ,SUM (table_scan.CPU_TIME_DELTA) CPU_TIME
                 ,SUM (table_scan.APWAIT_DELTA) APP_WAIT
                 ,SUM (table_scan.CLWAIT_DELTA) CL_WAIT
                 ,SUM (table_scan.IOWAIT_DELTA) IO_WAIT
                 ,SUM (table_scan.SORTS_DELTA) SORTS
    FROM (SELECT tot_stat.*, sqlplan.object_owner, sqlplan.object_name,
                 sqlplan.COST, sqlplan.cpu_cost, sqlplan.io_cost,sqlplan.TIME
            FROM (SELECT tot_stat.*
                    FROM (SELECT stat.*
                            FROM (SELECT * FROM dba_hist_snapshot) snap,
                                 (SELECT * FROM dba_hist_sqlstat) stat
                           WHERE snap.begin_interval_time BETWEEN TRUNC (SYSDATE - 1) AND TRUNC (SYSDATE)
                             AND snap.instance_number = stat.instance_number
                             AND snap.snap_id = stat.snap_id) tot_stat) tot_stat,
                 dba_hist_sql_plan sqlplan
           WHERE tot_stat.sql_id = sqlplan.sql_id
             AND tot_stat.plan_hash_value = sqlplan.plan_hash_value
             AND sqlplan.operation = 'TABLE ACCESS'
             AND sqlplan.options = 'FULL'
             AND sqlplan.io_cost > 100 ) table_scan,
         dba_users u
   WHERE u.user_id = table_scan.parsing_schema_id
   -- AND u.username not in ('SYS','SYSTEM','DBSNMP','SYSMAN','XDB')
   AND u.username in ('USRWEBSUBE')
   AND table_scan.disk_reads_delta>0 AND table_scan.buffer_gets_delta>0
GROUP BY u.username, table_scan.object_owner,table_scan.object_name,table_scan.sql_id,table_scan.plan_hash_value,
         table_scan.COST,table_scan.cpu_cost,table_scan.io_cost,table_scan.module
                 ,(table_scan.buffer_gets_delta/(table_scan.disk_reads_delta+table_scan.buffer_gets_delta))*100 
                 ) GRP_STAT
WHERE GRP_STAT.executions>0group by GRP_STAT.username,GRP_STAT.object_owner ,GRP_STAT.object_NAME
order by disk_reads desc;

--IO_COST degeri yuksek table scan yapan sql cumlelerine ait bilgiler 

SELECT GRP_STAT.username,GRP_STAT.object_owner, GRP_STAT.object_name,GRP_STAT.sql_id, GRP_STAT.plan_hash_value
, GRP_STAT.COST,GRP_STAT.cpu_cost, GRP_STAT.io_cost, GRP_STAT.module
,GRP_STAT.executions
,round(GRP_STAT.fetches/GRP_STAT.executions/1000000,2) fetch_p_ex
,round(GRP_STAT.reads/GRP_STAT.executions/1000000,2) reads_p_ex
,round(GRP_STAT.elapsed_time/GRP_STAT.executions/1000000,2) elapsed_time_p_ex
,round(GRP_STAT.CPU_TIME/GRP_STAT.executions/1000000,2) CPU_TIME_p_ex
,round(GRP_STAT.APP_WAIT/GRP_STAT.executions/1000000,2) APP_WAIT_p_ex
,round(GRP_STAT.CL_WAIT/GRP_STAT.executions/1000000,2) CL_WAIT_p_ex
,round(GRP_STAT.IO_WAIT/GRP_STAT.executions/1000000,2) IO_WAIT_p_ex
,round(GRP_STAT.SORTS/GRP_STAT.executions/1000000,2) SORTS_p_ex
, sqltext.sql_text 
from
(SELECT   u.username, table_scan.object_owner, table_scan.object_name,
         table_scan.sql_id, table_scan.plan_hash_value, table_scan.COST,
         table_scan.cpu_cost, table_scan.io_cost, table_scan.module
                 ,SUM (table_scan.executions_delta) executions
                 ,SUM (table_scan.fetches_delta) fetches
                 ,SUM (table_scan.disk_reads_delta+table_scan.buffer_gets_delta) reads
                 ,SUM (table_scan.elapsed_time_delta) elapsed_time
                 ,SUM (table_scan.CPU_TIME_DELTA) CPU_TIME
                 ,SUM (table_scan.APWAIT_DELTA) APP_WAIT
                 ,SUM (table_scan.CLWAIT_DELTA) CL_WAIT
                 ,SUM (table_scan.IOWAIT_DELTA) IO_WAIT
                 ,SUM (table_scan.SORTS_DELTA) SORTS
    FROM (SELECT tot_stat.*, sqlplan.object_owner, sqlplan.object_name,
                 sqlplan.COST, sqlplan.cpu_cost, sqlplan.io_cost,sqlplan.TIME
            FROM (SELECT tot_stat.*
                    FROM (SELECT stat.*
                            FROM (SELECT * FROM dba_hist_snapshot) snap,
                                 (SELECT * FROM dba_hist_sqlstat) stat
                           WHERE snap.begin_interval_time BETWEEN TRUNC (SYSDATE - 1) AND TRUNC (SYSDATE)
                             AND snap.instance_number = stat.instance_number
                             AND snap.snap_id = stat.snap_id) tot_stat) tot_stat,
                 dba_hist_sql_plan sqlplan
           WHERE tot_stat.sql_id = sqlplan.sql_id
             AND tot_stat.plan_hash_value = sqlplan.plan_hash_value
             AND sqlplan.operation = 'TABLE ACCESS'
             AND sqlplan.options = 'FULL'
             AND sqlplan.io_cost > 100 ) table_scan,
         dba_users u
   WHERE u.user_id = table_scan.parsing_schema_id
  -- AND u.username not in ('SYS','SYSTEM','DBSNMP','SYSMAN','XDB')
   AND u.username in ('USRWEBSUBE')
GROUP BY u.username, table_scan.object_owner,table_scan.object_name,table_scan.sql_id,table_scan.plan_hash_value,
         table_scan.COST,table_scan.cpu_cost,table_scan.io_cost,table_scan.module ) GRP_STAT, DBA_HIST_SQLTEXT sqltext
WHERE GRP_STAT.sql_id=sqltext.sql_id
and GRP_STAT.executions>0
order by elapsed_time_p_ex desc;