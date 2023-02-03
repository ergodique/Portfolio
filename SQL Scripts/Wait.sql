/*
    *  db file sequential read—A single-block read (i.e., index fetch by ROWID)
    * db file scattered read—A multiblock read (a full-table scan, OPQ, sorting)

	db file sequential read	Tune SQL to do less I/O. Make sure all objects are analyzed. Redistribute I/O across disks.
	buffer busy waits	Increase DB_CACHE_SIZE (DB_BLOCK_BUFFERS prior to 9i)/ Analyze contention from SYS.V$BH
	log buffer space	Increase LOG_BUFFER parameter or move log files to faster disks
*/

/* list of blocking sessions */
SELECT * FROM DBA_BLOCKERS

/* list of waiting session*/
SELECT * FROM DBA_WAITERS

/*  who is blocking sid=201 */
SELECT inst_id,sid,BLOCKING_SESSION_STATUS, BLOCKING_SESSION
FROM gv$session 
WHERE SID = 201

--OR 

SELECT * FROM DBA_WAITERS
WHERE waiting_session=201

/* Determine sessions that are Waiting  */
SELECT inst_id,SID, username, logon_time,event, blocking_session,
   seconds_in_wait, wait_time,p1,p1text,p2,p2text,p3,p3text
FROM gv$session WHERE state IN ('WAITING')
AND wait_class != 'Idle'
/* kullanýcý adýnda filreleme için aþaðýdaki satýrý açýn*/ 
--AND username='FRAUDSTAR'
/* sadece bekletilenleri görmek için aþaðýdaki satýrý açýn */
--AND blocking_session IS NOT NULL 

/* get session details of sid=386 */
SELECT * FROM gv$session  WHERE SID=456

SELECT * FROM gv$session_longops  WHERE SID=404
AND sofar<totalwork

/*get the wait sessions for events.*/
SELECT inst_id,wait_class, event, SID, state, wait_time, seconds_in_wait,p1,p1text,p2,p2text,p3,p3text
FROM gv$session_wait
WHERE wait_class !='Idle'
ORDER BY wait_class, event, SID


/* 404 nolu session kim tarafýndan bekletiliyor */ 
SELECT inst_id,SID, blocking_session, blocking_session_status block_status,
               username, event, seconds_in_wait siw
        FROM   gv$session
        WHERE  SID = 404;
		
SELECT inst_id,SID, state, event, seconds_in_wait siw,
               sql_address, sql_hash_value hash_value, p1, p2, p3
        FROM   gv$session
        WHERE  SID = 404;



/*how many waits this session is facing, time is centiseconds */
SELECT * FROM gv$session_wait_class 
WHERE SID = 404
--WHERE UPPER(wait_class) LIKE 'CONC%'

/* Which SQL is causing the lock for that determined session */
SELECT s.inst_id,SID, sql_text
FROM gv$session s, gv$sql q
WHERE SID IN (404)
AND (
   q.sql_id = s.sql_id OR
   q.sql_id = s.prev_sql_id);



/* One can easily view details of time spent by a session in various activities */
SELECT inst_id,SID,stat_name, VALUE
FROM gv$sess_time_model
--where value > 0 and stat_name !='DB time'
WHERE SID = 432;

/* system-wide statistics for wait classes*/
SELECT * FROM gv$system_wait_class
ORDER BY inst_id,time_waited DESC


/* Most problems do not occur in isolation; they leave behind tell-tale clues that can be identified by patterns. 
The pattern can be seen from a historical view of the wait classes as follows. */
SELECT c.WAIT_CLASS, m.wait_class#, m.wait_class_id, 
m.average_waiter_count "awc", m.dbtime_in_wait,
m.time_waited,  m.wait_count
FROM v$waitclassmetric m, v$system_wait_class c
WHERE c.WAIT_CLASS_ID(+)=m.WAIT_CLASS_ID

SELECT * FROM v$session_wait WHERE SID=618

/* a history of the session waits is maintained automatically for the last 10 events of active sessions*/
SELECT event, wait_time, wait_count
FROM v$session_wait_history
WHERE SID = 432


SELECT   SID, seq#, event, wait_time, p1, p2, p3 
    FROM     v$session_wait_history
    WHERE    SID = 327 
    ORDER BY seq#;


/* Active Session History (ASH)
 holds data for about 30 minutes before being overwritten with new data in a circular fashion.
 SAMPLE_TIME—the time stamp showing when the statistics were collected*/ 
SELECT sample_time, event, wait_time
FROM V$ACTIVE_SESSION_HISTORY
WHERE session_id = 187
--AND session_serial# = 5
AND wait_time>0
ORDER BY 1 DESC

/* To further aid the diagnosis identify the exact SQL statement executed by the session at that time, using the following query of the V$SQL view: */
/* The column APPLICATION_WAIT_TIME shows how long the sessions executing that SQL waited for the application wait class 
   If the user is late then use DBA_HIST_ACTIVE_SESS_HISTORY view which holds purged ASH data*/
SELECT sql_text, application_wait_time
FROM v$sql
WHERE sql_id IN (
  SELECT sql_id
  FROM v$active_session_history
  WHERE /*sample_time BETWEEN TO_DATE('20051206 17','YYYYMMDD HH24') AND TO_DATE('20051206 18','YYYYMMDD HH24')
  AND*/ session_id = 187
--  AND session_serial# = 5
);


SELECT h.sample_time, e.event, h.wait_time, h.time_waited, h.user_id
FROM DBA_HIST_ACTIVE_SESS_HISTORY h, v$session_event e
WHERE h.EVENT_ID=e.EVENT_ID 
AND session_id = 386
AND sample_time BETWEEN TO_DATE('20051206 17','YYYYMMDD HH24') AND TO_DATE('20051206 18','YYYYMMDD HH24')
ORDER BY event 

SELECT ht.sql_text, hs.apwait_total,hs.apwait_delta  
FROM DBA_HIST_SQLTEXT HT, DBA_HIST_SQLSTAT HS 
WHERE HS.sql_id = HT.sql_id 
--AND TO_CHAR(HT.SQL_TEXT) <> 'COMMIT'
AND ht.sql_id IN (
  SELECT sql_id
  FROM DBA_HIST_ACTIVE_SESS_HISTORY h
  WHERE sample_time BETWEEN TO_DATE('20051206 17','YYYYMMDD HH24') AND TO_DATE('20051206 18','YYYYMMDD HH24')
  AND session_id = 386
--  AND session_serial# = 5
);

SELECT ht.sql_id,ht.sql_text, hs.apwait_total,hs.apwait_delta , sh.PROGRAM, sh.MODULE, sh.ACTION ,sh.WAIT_TIME, sh.TIME_WAITED   
FROM DBA_HIST_SQLTEXT HT, DBA_HIST_SQLSTAT HS, DBA_HIST_ACTIVE_SESS_HISTORY sh
WHERE HS.sql_id = HT.sql_id 
--AND u.USER_ID = sh.USER_ID
--AND TO_CHAR(HT.SQL_TEXT) <> 'COMMIT'
AND (ht.sql_id,u.user_id) IN (
  SELECT sql_id,user_id
  FROM DBA_HIST_ACTIVE_SESS_HISTORY h
  WHERE session_id = 386
  AND sample_time BETWEEN TO_DATE('20051206 17','YYYYMMDD HH24') AND TO_DATE('20051206 18','YYYYMMDD HH24')
--  AND session_serial# = 5
) ;
   
/* shows the wait time periods and how many times sessions have waited for a specific time period.
Bucket columns is in miliseconds*/    
SELECT event,wait_time_milli bucket, wait_count ,(wait_count)*100/(SELECT SUM(wait_count) FROM v$event_histogram  WHERE event = 'log file sync') per_cent
 FROM v$event_histogram
  WHERE event = 'log file sync'
--GROUP BY event,wait_time_milli,wait_count
-- WHERE event = 'enq: TX - row lock contention';

	
/*To see potential host contention
all time metrics in centiseconds
IDLE_TICKS -> time for CPU Idle
BUSY_TICKS-> time for CPU busy etc*/
SELECT * FROM v$osstat;

/* datafile statistics*/ 
SELECT d.FILE_NAME, f.* FROM v$filestat f, DBA_DATA_FILES d
WHERE f.FILE# = d.FILE_ID
AND d.file_id IN (7218,7188)
ORDER BY maxiortm DESC
--ORDER BY avgiotim DESC 
--order by maxiowtm desc
