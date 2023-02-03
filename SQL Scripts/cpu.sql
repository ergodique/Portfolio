--En fazla I/O yapan SQL bulundu.SQL_ID kolonundaki bilgi alýndý. 
------------------------EN FAZLA Disk okumasý yapan SQL! 
SELECT ((disk_reads+buffer_gets)/executions) readperexec , v.* 
FROM v$sqlarea v 
WHERE executions > 10 
ORDER BY 
((disk_reads+buffer_gets)/executions) DESC 
--APPLICATION_WAIT_TIME desc, 
--CONCURRENCY_WAIT_TIME desc, 
--CLUSTER_WAIT_TIME desc, 
--USER_IO_WAIT_TIME desc 

--en fazla read yapanlar..
select inst_id,PARSING_SCHEMA_NAME, MODULE,SERVICE, sql_id,executions,buffer_gets,disk_reads,round((buffer_gets/(disk_reads+buffer_gets)*100),2) buffer_hit_ratio,ROWS_PROCESSED, FETCHES,  sql_fulltext from gv$sql
where round((buffer_gets/(disk_reads+buffer_gets)*100),2) < 90
and disk_reads+buffer_gets > 0 
and PARSING_SCHEMA_NAME in (select username from dba_users where created > (select created from v$database))
and executions>300;


--EN FAZLA CPU kullanan SQL bulundu. 
--EN FAZLA CPU KULLANAN SQL HANGÝSÝ 
SELECT cpu_time/executions,sql_id,v.* FROM v$sqlarea v 
WHERE  executions > 10
AND sql_TEXT NOT LIKE 'DECLARE%'
ORDER BY v.cpu_time/executions  DESC 

-- BU SQLÝN ÞU ANKÝ EXECUTÝON PLANI NEDÝR. 
SELECT * FROM v$sql_plan WHERE sql_id='dbd86q61c3vjr' 

--BU SQLÝN GEÇMÝÞTEKÝ EXECUTÝON PLANLARI NASILMIÞ? 
SELECT a.TIMESTAMP,a.* FROM dba_hist_sql_plan a WHERE sql_id='dw87h4n45tpdb' 
--AND plan_hash_value='3447926188'
ORDER BY a.TIMESTAMP 

SELECT FIRST_LOAD_TIME,PLAN_HASH_VALUE  FROM v$sqlarea WHERE sql_id='gkud7c8zz33x1'

SELECT * FROM v$session
WHERE status='ACTIVE'
AND TYPE != 'BACKGROUND'

ALTER SYSTEM FLUSH SHARED_POOL;
  


SELECT * FROM DICTIONARY 
WHERE table_name LIKE UPPER('%bind%')

SELECT * FROM v$sql_bind_capture
WHERE sql_id='b24vymy3bxgtd'

SELECT SYSDATE FROM dual


SELECT b.begin_interval_time,END_INTERVAL_TIME,elapsed_time_total,ROUND(elapsed_time_total/executions_total,0),CPU_TIME_TOTAL,CPU_TIME_DELTA, a.* FROM dba_hist_sqlstat a , dba_hist_snapshot b
WHERE a.snap_id=b.snap_id
AND BEGIN_INTERVAL_TIME > SYSDATE - 200/24
AND sql_id IN ('gkud7c8zz33x1','b24vymy3bxgtd','dyu4vnz358ggj') 
ORDER BY 1 ASC
