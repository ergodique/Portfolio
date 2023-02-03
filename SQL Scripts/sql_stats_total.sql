declare
dbname VARCHAR2(20);
max_int_time date;

begin
INSERT INTO ISBDBA.SQL_STATS
SELECT  
         tot_stat.begin_interval_time  
         ,u.username
         , tot_stat.module
         ,count(tot_stat.sql_id) sql_count
         ,SUM (tot_stat.buffer_gets_delta) buffer_gets
         ,SUM (tot_stat.disk_reads_delta) disk_reads
          ,SUM (tot_stat.disk_reads_delta+tot_stat.buffer_gets_delta) reads
         ,SUM (tot_stat.APWAIT_DELTA/1000) APP_WAIT
         ,round(SUM (tot_stat.APWAIT_DELTA/1000)/SUM (tot_stat.executions_DELTA),2) APP_WAIT_PEX
         ,SUM (tot_stat.CCWAIT_DELTA/1000) CC_WAIT
         ,round(SUM (tot_stat.CCWAIT_DELTA/1000)/SUM (tot_stat.executions_DELTA),2) CC_WAIT_PEX
         ,SUM (tot_stat.CLWAIT_DELTA/1000) CL_WAIT
         ,round(SUM (tot_stat.CLWAIT_DELTA/1000)/SUM (tot_stat.executions_DELTA),2) CL_WAIT_PEX
         ,SUM (tot_stat.CPU_TIME_DELTA/1000) CPU_TIME
         ,round(SUM (tot_stat.CPU_TIME_DELTA/1000)/SUM (tot_stat.executions_DELTA),2) CPU_TIME_PEX
         ,SUM (tot_stat.DIRECT_WRITES_DELTA) DIRECT_WRITES
         ,SUM (tot_stat.elapsed_time_DELTA/1000) elapsed_time
         ,round(SUM (tot_stat.elapsed_time_DELTA/1000)/SUM (tot_stat.executions_DELTA),2) elapsed_time_PEX
         ,SUM (tot_stat.executions_DELTA) executions
         ,SUM (tot_stat.fetches_DELTA) fetches
         ,SUM (tot_stat.IOWAIT_DELTA/1000) IO_WAIT
         ,round(SUM (tot_stat.IOWAIT_DELTA/1000)/SUM (tot_stat.executions_DELTA),2) IO_WAIT_PEX
         ,SUM (tot_stat.LOADS_DELTA) LOADS
         ,SUM (tot_stat.parse_calls_DELTA) parse_calls
         ,SUM (tot_stat.PLSEXEC_TIME_DELTA/1000) PLSEXEC_TIME
         ,round(SUM (tot_stat.PLSEXEC_TIME_DELTA/1000)/SUM (tot_stat.executions_DELTA),2) PLSEXEC_TIME_PEX
         ,SUM (tot_stat.ROWS_PROCESSED_DELTA) ROWS_PROCESSED
         ,ROUND(AVG (tot_stat.SHARABLE_MEM),2) SHARABLE_MEM
         ,SUM (tot_stat.SORTS_DELTA) SORTS
,tot_stat.sql_id SQL_ID
, tot_stat.plan_hash_value PLAN_HASH_VALUE
FROM (SELECT stat.*,trunc(snap.begin_interval_time) begin_interval_time FROM ( dba_hist_snapshot) snap,
                                 ( dba_hist_sqlstat) stat
                           WHERE snap.begin_interval_time BETWEEN (select trunc(max(BEGIN_INTERVAL_TIME)+1) from ISBDBA.SQL_STATS) AND   trunc (SYSDATE)
                             AND snap.instance_number = stat.instance_number
                             AND snap.snap_id = stat.snap_id) tot_stat , dba_users u
   WHERE u.user_id = tot_stat.parsing_schema_id
        AND tot_stat.executions_delta>0 
     AND u.username in (select username from dba_users where created >  (select created from v$database))
GROUP BY tot_stat.begin_interval_time ,u.username,tot_stat.module,tot_stat.sql_id,tot_stat.plan_hash_value
order by 1,2,3;

commit;

select name into dbname from v$database;
select max(begin_interval_time) into max_int_time from isbdba.sql_stats_total@LINK_TO_EMREP where database_name = dbname;



INSERT INTO ISBDBA.SQL_STATS_TOTAL@LINK_TO_EMREP
select dbname,sq.* from isbdba.sql_stats sq where  sq.BEGIN_INTERVAL_TIME > max_int_time;

commit;

end;