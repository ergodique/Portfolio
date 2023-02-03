---- GENEL DURUM 

select distinct inst_id,sql_id,PARSING_SCHEMA_NAME,module,FIRST_LOAD_TIME,executions,round(ELAPSED_TIME/executions,0) ET_per,round(CPU_TIME/executions,0) CPU_PER,
round(FETCHES/executions,0) fetch_per, round(DISK_READS/executions,0) disk_r_per
,round(ROWS_PROCESSED/executions,0) rows_proces_per,sql_text      from gv$sql
where  executions>0
--AND PARSING_SCHEMA_NAME='KKM_USER'
order by et_per desc
--order by executions desc 
--order by fetch_per desc 
--order by cpu_per desc

------------------------TOP SQL
--TOP_SQL
SELECT ((disk_reads+buffer_gets)/executions) readperexec , v.*  
FROM v$sqlarea v
WHERE executions > 10 
ORDER BY 
((disk_reads+buffer_gets)/executions) DESC
--APPLICATION_WAIT_TIME desc, 
--CONCURRENCY_WAIT_TIME desc, 
--CLUSTER_WAIT_TIME desc, 
--USER_IO_WAIT_TIME desc

SELECT cpu_time/executions,sql_id,v.*  
FROM v$sqlarea v WHERE executions > 10 ORDER BY 1 DESC

select distinct sql_id,plan_hash_value,timestamp  from dba_hist_sql_plan
where sql_id='cfb0s3xdsun4w'


SELECT CACHE#, TYPE, parameter FROM v$rowcache  WHERE CACHE# = 5 


SELECT * FROM v$sql_plan WHERE --hash_value=1168132591
hash_value IN (4150298547)
--(621277045)

SELECT * FROM v$sql WHERE 1=1
--AND hash_value=1168132591
AND hash_value IN (4150298547)
--AND OUTLINE_CATEGORY IS NOT NULL

SELECT * FROM v$sqlarea WHERE 1=1
AND hash_value=3873987237
--upper(sql_text) like upper('%M1.REQUEST%')


SELECT sql_text FROM v$sqltext_with_newlines WHERE --hash_value=1168132591
--hash_value=3873987237
hash_value=4150298547
ORDER BY piece



-- is su anda ne 
	SELECT --inst_id,
   SID,event,state,seconds_in_wait,wait_time,t.*
   FROM v$session_wait t WHERE 1=1
   AND wait_class <> 'Idle'  	
--   and sid in ( select sid from v$session where username='FUH')
--   and sid=2884
   
   AND event ='direct path read'
   
   
-- and status='KILLED'
--   and event like 'library cache%'
   --and inst_id=3
--and   sid=899
   

SELECT 'alter system kill session '''|| SID || ',' || serial#||''';'
,blocking_session,t.* 
FROM v$session t WHERE 1=1 
--and wait_class <> 'Idle'
-- and status='KILLED'
--   and event ='latch: library cache'
--and event='enq: TM - contention' 
--and seconds_in_wait > 500 and type='USER' and wait_class <> 'Idle'
AND wait_class <> 'Idle'
--and event='library cache pin'
--and event='library cache lock'
--and event='latch: In memory undo latch'
   --and inst_id=3
--and blocking_session is not null   
--       and   sid in (5144,4634)
--and upper(osuser) like '%ORACLE%'
--and host like '%sh%'


SELECT * FROM v$session WHERE blocking_session=4634

SELECT * FROM v$session_wait WHERE 1=1 
AND wait_class <> 'Idle'
--and event ! ='SQL*Net message from client'
--and event='SQL*Net more data from dblink'
--AND SID IN (SELECT SID FROM v$session WHERE USER='EUL')
ORDER BY event

-- OS process 
 SELECT s.SID,p.*
FROM v$session s, v$process p
WHERE s.paddr=p.addr
--and ( s.sid= or  s.sid in (select sid from v$px_session where qcsid=50) )
--AND p.spid=9277  -- unix process no
--AND SID = 9217 
--order by spid asc

--- calisan sorgular 
SELECT s.username,s.OSUSER,SID  ,s.serial#,sql_text,a.EXECUTIONS,a.DISK_READS,a.HASH_VALUE,a.VERSION_COUNT,s.osuser,s.machine
FROM v$session s ,v$sqlarea a
WHERE 1=1
AND SID NOT IN (SELECT SID FROM v$px_session WHERE SID<>qcsid)
AND s.sql_address=a.ADDRESS
--and s.sid in (6052)
--and s.username='FUH'
--and wait_class <> 'Idle'
--and event='enq: TX - row lock contention'



--- calisan sorgular templi, lonops
SELECT s.username,mytemp,s.OSUSER,SID  ,s.serial#,sql_text,a.EXECUTIONS,a.DISK_READS,a.HASH_VALUE,a.VERSION_COUNT,s.osuser,s.machine,
 l.sofar,l.totalwork,l.time_remaing,l.time_elapsed
FROM v$session s ,v$sqlarea a,
	(SELECT  SESSION_ADDR,SUM(blocks)  mytemp            
	FROM    V$TEMPSEG_USAGE b    
	GROUP BY SESSION_ADDR) b,
	(SELECT qcsid,SUM(sofar) sofar,SUM(totalwork) totalwork,MAX(time_remaining) time_remaing,MAX(elapsed_seconds) time_elapsed 
	FROM v$session_longops 
	WHERE  sofar <>totalwork
	GROUP BY qcsid ) l   
WHERE 1=1
AND SID NOT IN (SELECT SID FROM v$px_session WHERE SID<>qcsid)
AND s.saddr = b.session_addr(+)  
AND s.sql_address=a.ADDRESS
AND s.SID=l.qcsid(+)
--and s.sid in (6052)
--and s.username='FUH'
AND wait_class <> 'Idle'
--and event='enq: TX - row lock contention'


ORDER BY sql_text
AND event ='direct path read'
AND SID IN (50)
WHERE SID=217 OR SID IN
 (  
SELECT SID FROM v$px_session WHERE qcsid=217
)
ORDER BY event DESC





SELECT * FROM v$px_session WHERE 1=1 
--and qcsid=1189
 AND SID IN (SELECT SID FROM v$session WHERE osuser='bsalturk')


SELECT qcsid,SUM(sofar) sofar,SUM(totalwork) totalwork,MAX(time_remaining) time_remaing,MAX(elapsed_seconds) time_elapsed 
FROM v$session_longops 
WHERE  sofar <>totalwork
GROUP BY qcsid
 

--uzun isler
SELECT * FROM v$session_longops 
WHERE  1=1
--and sid=6052
-- and ( sid =217 or sid in ( select sid from v$px_session where qcsid=217 ) )
AND sofar <>totalwork
-- and sid in ( select sid from v$session where username='FUH')



-- parallelizm
SELECT DEGREE,table_name FROM dba_tables WHERE --table_name like 'CADM_%' and 
owner='DWH'

SELECT 'alter table dwh.'||table_name || ' parallel ;'  FROM dba_tables WHERE table_name LIKE 'CADM_%'
AND owner='DWH'

ALTER SESSION DISABLE PARALLEL QUERY  ;

ALTER SESSION FORCE PARALLEL QUERY PARALLEL 4;





SELECT * FROM 
 dba_free_space WHERE tablespace_name='TEMP'
 
 SELECT * FROM dba_temp_files
 
-- statistics 
 SELECT * FROM v$tempstat
 
 SELECT * FROM v$pgastat
 
 SELECT * FROM v$sesstat s, v$statname n WHERE SID=448 AND s.STATISTIC#=n.STATISTIC# AND NAME LIKE '%direc%'
 
SELECT * FROM   (SELECT obj#,statistic#,SUM(VALUE) FROM v$segstat GROUP BY obj#,statistic#) s, V$SEGSTAT_NAME  n WHERE s.STATISTIC#=n.STATISTIC# --and name like '%direc%'

 SELECT * FROM v$sga

 SELECT * FROM v$sess_io 
    
 SELECT * FROM v$resource_limit

 SELECT * FROM v$parameter WHERE NAME LIKE '%read%'
    

SELECT * FROM V$CACHE
    

--TEMP USAGE
SELECT   SID,b.TABLESPACE, b.segtype,b.segfile#, b.segblk#, b.EXTENTS,b.blocks, a.SID, a.serial#,            
a.username, a.osuser, a.status  
FROM     v$session a,V$TEMPSEG_USAGE b  
WHERE    a.saddr = b.session_addr  
--and ( SID=217 or sid in (select  sid from v$px_session where qcsid=217) )
--and sid=6052
--  and sid in ( select sid from v$session where username='FUH')
ORDER BY  b.blocks DESC,b.TABLESPACE, b.segfile#, b.segblk#; 



-- pga automatic olursa
SELECT * FROM  V$SQL_WORKAREA_ACTIVE 
WHERE 1=1
--sid in (select sid from v$px_session where qcsid=217)
--sid=4529
--AND SID IN ( SELECT SID FROM v$session WHERE username='FUH')
ORDER BY work_area_size DESC

SELECT * FROM  v$pga_target_advice



-- free space
SELECT SUM(bytes) FROM 
 dba_free_space
WHERE tablespace_name='TSSTAGE'

SELECT blocks FROM dba_tab_partitions WHERE table_name='TRTX_TAG' AND table_OWNER='DWH'


 -- Nekadar UNDO kullaniyor
 SELECT s.SID, s.serial#, s.username, s.program, 
  t.used_ublk, t.used_urec
 FROM v$session s, v$transaction t
 WHERE s.taddr = t.addr
 AND ( SID=229 OR SID IN ( SELECT SID FROM v$px_session WHERE qcsid=229) )
 ORDER BY 5 DESC, 6 DESC, 1, 2, 3, 4;

  SELECT SUM(t.used_urec) 
 FROM v$session s, v$transaction t
 WHERE s.taddr = t.addr
 AND ( SID=229 OR SID IN ( SELECT SID FROM v$px_session WHERE qcsid=229) )


 

SELECT 'GRANT EXECUTE ON ' || OBJECT_NAME || ' TO OWF_MGR;'  FROM dba_objects WHERE owner='SYS' AND object_type='PACKAGE' 
AND object_name LIKE 'UTL%'



ALTER SYSTEM DUMP DATAFILE 19217 BLOCK 192171

ALTER SYSTEM DUMP DATAFILE 1932 BLOCK 236217

SELECT * FROM kkpap_pruning 







---- OLDUR
	SELECT 'alter system kill session '''|| SID || ',' || serial#||''';' FROM gv$session WHERE 1=1 AND TYPE <> 'BACKGROUND'
   AND wait_class <> 'Idle'     
   AND event LIKE 'library cache pin%'
   
   ps -eaf | grep _s0 | awk '{print $2}' | xargs KILL -9
   
   SELECT * FROM V$INSTANCE
   
   DECLARE
   VINS NUMBER;
   vsql VARCHAR2(4000);
   BEGIN
   SELECT INSTANCE_NUMBER INTO VINS FROM V$INSTANCE; 
   FOR C1 IN (SELECT SID,SERIAL# FROM V$SESSION WHERE event LIKE 'library cache%') LOOP
   vsql:='alter system kill session '''|| C1.SID || ',' || C1.serial#||''';' ;
   	DBMS_OUTPUT.PUT_LINE(vsql);
   END LOOP;   
   END;
   /

   
   
   

   

---LOB   
SELECT SEGMENT_NAME,SUM(BYTES)
FROM dba_EXTENTS
WHERE segment_name IN ('SYS_IL0000049905C00004$$' ,'AD_PHOTOS','SYS_LOB0000049905C00004$$')
AND owner='IMAGES'
GROUP BY SEGMENT_NAME



SELECT SUM(bytes), s.segment_name, s.segment_type
  FROM dba_lobs l, dba_segments s
  WHERE s.segment_type = 'LOBSEGMENT'
   AND l.table_name = 'AD_PHOTOS'
   AND s.owner='IMAGES'
   AND s.segment_name = l.segment_name
   GROUP BY s.segment_name,s.segment_type;

   
   ALTER SYSTEM SET parallel_execution_message_size=121784 SCOPE=SPFILE

ALTER SYSTEM SET parallel_adaptive_multi_user=FALSE;

ALTER SYSTEM SET pga_aggregate_target=21700M --scope=spfile

SELECT * FROM v$sqlarea WHERE hash_value=4014742222

SELECT * FROM v$sql_plan WHERE hash_value=4014742222
