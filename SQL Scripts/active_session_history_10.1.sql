
/* What resource is currently in high demand? */
SELECT inst_id,active_session_history.event,
	   active_session_history.P1,
	   active_session_history.P2,
	   active_session_history.P3,
       active_session_history.session_id,
       SUM(active_session_history.wait_time +
           active_session_history.time_waited) ttl_wait_time
  FROM gv$active_session_history active_session_history
 WHERE 1=1
--AND active_session_history.user_id=163
AND sample_time BETWEEN TO_DATE('20060317 15:03:31','YYYYMMDD HH24:MI:SS') AND TO_DATE('20060317 15:30:41','YYYYMMDD HH24:MI:SS') 
--AND active_session_history.sample_time BETWEEN SYSDATE - 90/1440 AND SYSDATE
GROUP BY active_session_history.inst_id,active_session_history.event,active_session_history.session_id
,active_session_history.P1
,active_session_history.P2
,active_session_history.P3
ORDER BY ttl_wait_time DESC ,inst_id ASC


 /* What user is waiting the most? */ 
   SELECT active_session_history.inst_id,active_session_history.session_ID,
          us.username,
          SUM(active_session_history.wait_time +
              active_session_history.time_waited) ttl_wait_time
     FROM gv$active_session_history /*isbdba.active_session_history */ active_session_history,
          dba_users us
    WHERE 1=1
--AND active_session_history.user_id=63
AND sample_time BETWEEN TO_DATE('20060317 15:03:31','YYYYMMDD HH24:MI:SS') AND TO_DATE('20060317 15:30:41','YYYYMMDD HH24:MI:SS')
--AND active_session_history.sample_time BETWEEN SYSDATE - 90/1440 AND SYSDATE
--active_session_history.sample_time BETWEEN SYSDATE - 60/2880 AND SYSDATE
      AND active_session_history.user_id = us.user_id
   GROUP BY active_session_history.inst_id,active_session_history.session_ID, us.username
  ORDER BY ttl_wait_time DESC ,inst_id ASC
  
DBA_HIST_ACTIVE_SESS_HISTORY

v$active_session_history

/* What SQL is currently using the most resources? */
SELECT active_session_history.inst_id,active_session_history.user_id,
        DBA_USERS.username,
		active_session_history.SESSION_ID,
        sqlarea.sql_text,
		active_session_history.event,
		active_session_history.sql_id,
/*		active_session_history.wait_time,
		 active_session_history.time_waited,*/
		SUM(active_session_history.wait_time +
            active_session_history.time_waited) ttl_wait_time
   FROM gv$active_session_history  /* DBA_HIST_ACTIVE_SESS_HISTORY*/ /* isbdba.active_session_history */ active_session_history,
        gv$sqlarea sqlarea
        ,DBA_USERS
  WHERE 1=1
-- AND active_session_history.user_id=153  /* OZLRAC */
--  AND active_session_history.user_id=63 /* KKM_USER MILENAS */
AND sample_time BETWEEN TO_DATE('20060315 07:03:31','YYYYMMDD HH24:MI:SS') AND TO_DATE('20060315 09:10:41','YYYYMMDD HH24:MI:SS') 
--AND active_session_history.sample_time BETWEEN SYSDATE - 90/1440 AND SYSDATE    
--  and active_session_history.sample_time BETWEEN SYSDATE - 60/2880 AND SYSDATE
    AND active_session_history.sql_id = sqlarea.sql_id
    AND active_session_history.user_id = DBA_USERS.user_id
 GROUP BY active_session_history.inst_id,active_session_history.user_id,sqlarea.sql_text, DBA_USERS.username, 
 active_session_history.SESSION_ID,
 active_session_history.event,active_session_history.sql_id
-- ,active_session_history.wait_time,active_session_history.time_waited
 ORDER BY ttl_wait_time DESC,inst_id ASC
 
 
/* What SQL_ID s are currently using the most resources? */
SELECT active_session_history.inst_id,active_session_history.user_id,
--        dba_users.username,
--        sqlarea.sql_text,
		active_session_history.event,
		active_session_history.sql_id,
/*		active_session_history.wait_time,
		 active_session_history.time_waited,*/
		SUM(active_session_history.wait_time +
            active_session_history.time_waited) ttl_wait_time
   FROM gv$active_session_history  /* DBA_HIST_ACTIVE_SESS_HISTORY*/ /* isbdba.active_session_history */ active_session_history
--        ,v$sqlarea sqlarea
--        ,dba_users
  WHERE 1=1
-- AND active_session_history.user_id=153  /* OZLRAC */
--  AND active_session_history.user_id=63 /* KKM_USER MILENAS */
AND sample_time BETWEEN TO_DATE('20060315 07:03:31','YYYYMMDD HH24:MI:SS') AND TO_DATE('20060315 09:10:41','YYYYMMDD HH24:MI:SS') 
--AND active_session_history.sample_time BETWEEN SYSDATE - 90/1440 AND SYSDATE    
--  and active_session_history.sample_time BETWEEN SYSDATE - 60/2880 AND SYSDATE
--    AND active_session_history.sql_id = sqlarea.sql_id
--    AND active_session_history.user_id = dba_users.user_id
 GROUP BY active_session_history.inst_id,active_session_history.user_id
 --,sqlarea.sql_text 
 --,dba_users.username
 , active_session_history.event,active_session_history.sql_id
-- ,active_session_history.wait_time,active_session_history.time_waited
 ORDER BY ttl_wait_time DESC, inst_id ASC
 
/*  What object is currently causing the highest resource waits? */ 
  SELECT active_session_history.inst_id,DBA_OBJECTS.owner,
  		DBA_OBJECTS.object_name,
        DBA_OBJECTS.object_type,
		active_session_history.sql_id,
		active_session_history.user_id,	
        active_session_history.event,
		active_session_history.session_id,		
		active_session_history.program,
--		active_session_history.wait_time, 		active_session_history.time_waited, 
        SUM(active_session_history.wait_time +
            active_session_history.time_waited) ttl_wait_time
   FROM gv$active_session_history /* DBA_HIST_ACTIVE_SESS_HISTORY*/  /*isbdba.active_session_history */ active_session_history,
        DBA_OBJECTS
  WHERE 1=1 
--   AND active_session_history.session_id=260
-- AND active_session_history.user_id=153  /* OZLRAC */
-- AND active_session_history.user_id=139  /* KKM_USER */
-- AND active_session_history.user_id=110  /* UYE */
-- AND active_session_history.user_id=124  /* OWBTARGET */
-- AND active_session_history.user_id=81  /* OWBRT_SYS */
-- AND active_session_history.user_id=79  /* OWBRUNTIME */
-- AND active_session_history.user_id=80  /* OWBRUNACC */
--  AND active_session_history.session_id IN (230,164)
--  and active_session_history.sample_time BETWEEN SYSDATE - 60/2880 AND SYSDATE
--  AND active_session_history.user_id=63 /* KKM_USER MILENAS */
AND sample_time BETWEEN TO_DATE('20060212180331','YYYYMMDDHH24MISS') AND TO_DATE('20060212180341','YYYYMMDDHH24MISS')
--AND active_session_history.sample_time BETWEEN SYSDATE - 90/1440 AND SYSDATE	  
    AND active_session_history.current_obj# = DBA_OBJECTS.object_id
 GROUP BY active_session_history.inst_id,DBA_OBJECTS.owner,DBA_OBJECTS.object_name, DBA_OBJECTS.object_type,active_session_history.sql_id, active_session_history.user_id,active_session_history.event
 ,active_session_history.session_id,active_session_history.program
-- ,active_session_history.wait_time,active_session_history.time_waited
 ORDER BY  ttl_wait_time DESC, inst_id ASC
-- ORDER BY  active_session_history.sql_id ASC,ttl_wait_time DESC



---------------------------------------------------------
DBA_USERS


SELECT * FROM v$px_session

SELECT * FROM v$archived_log
ORDER BY first_time DESC

SELECT SID,a.program, a.Machine, FAILED_OVER ,FAILOVER_METHOD,FAILOVER_TYPE   FROM v$session a
WHERE program IN ('hc_gw.exe')
AND SID IN (500,531,529)
--GROUP BY a.program, a.Machine, FAILED_OVER ,FAILOVER_METHOD,FAILOVER_TYPE
ORDER BY 2,1


SELECT * FROM v$sql WHERE sql_id='9pnwcwkz2w1c5'

SELECT * FROM DBA_DATA_FILES
WHERE file_id=12





------------------------------------------------------------
 ***DBA_HIST_ACTIVE_SESS_HISTORY***
------------------------------------------------------------

/* What resource is currently in high demand? */
SELECT 
	   active_session_history.P1,
	   active_session_history.P2,
	   active_session_history.P3,
       active_session_history.session_id,
       SUM(active_session_history.wait_time +
           active_session_history.time_waited) ttl_wait_time
  FROM DBA_HIST_ACTIVE_SESS_HISTORY active_session_history
 WHERE 1=1
--AND active_session_history.user_id=163
AND sample_time BETWEEN TO_DATE('20060315 07:03:31','YYYYMMDD HH24:MI:SS') AND TO_DATE('20060315 09:10:41','YYYYMMDD HH24:MI:SS') 
--AND active_session_history.sample_time BETWEEN SYSDATE - 90/1440 AND SYSDATE
GROUP BY active_session_history.session_id
,active_session_history.P1
,active_session_history.P2
,active_session_history.P3
ORDER BY ttl_wait_time DESC 


 /* What user is waiting the most? */ 
   SELECT sesion.SID,
          sesion.username,
          SUM(active_session_history.wait_time +
              active_session_history.time_waited) ttl_wait_time
     FROM  DBA_HIST_ACTIVE_SESS_HISTORY active_session_history,
          gv$session sesion
    WHERE 1=1
--AND active_session_history.user_id=63
AND sample_time BETWEEN TO_DATE('20060315 07:03:31','YYYYMMDD HH24:MI:SS') AND TO_DATE('20060315 09:10:41','YYYYMMDD HH24:MI:SS') 
--AND active_session_history.sample_time BETWEEN SYSDATE - 90/1440 AND SYSDATE
--active_session_history.sample_time BETWEEN SYSDATE - 60/2880 AND SYSDATE
      AND active_session_history.session_id = sesion.SID
   GROUP BY sesion.SID, sesion.username
  ORDER BY ttl_wait_time DESC 
  

/* What SQL is currently using the most resources? */
SELECT active_session_history.user_id,
        DBA_USERS.username,
		active_session_history.SESSION_ID,
        sqlarea.sql_text,
		active_session_history.sql_id,
/*		active_session_history.wait_time,
		 active_session_history.time_waited,*/
		SUM(active_session_history.wait_time +
            active_session_history.time_waited) ttl_wait_time
   FROM  DBA_HIST_ACTIVE_SESS_HISTORY active_session_history,
        DBA_HIST_SQLTEXT /*gv$sqlarea*/ sqlarea
        ,DBA_USERS
  WHERE 1=1
-- AND active_session_history.user_id=153  /* OZLRAC */
--  AND active_session_history.user_id=63 /* KKM_USER MILENAS */
AND sample_time BETWEEN TO_DATE('20060315 07:03:31','YYYYMMDD HH24:MI:SS') AND TO_DATE('20060315 09:10:41','YYYYMMDD HH24:MI:SS') 
--AND active_session_history.sample_time BETWEEN SYSDATE - 90/1440 AND SYSDATE    
--  and active_session_history.sample_time BETWEEN SYSDATE - 60/2880 AND SYSDATE
    AND active_session_history.sql_id = sqlarea.sql_id
    AND active_session_history.user_id = DBA_USERS.user_id
 GROUP BY active_session_history.user_id,sqlarea.sql_text, DBA_USERS.username, 
 active_session_history.SESSION_ID,
 active_session_history.sql_id
-- ,active_session_history.wait_time,active_session_history.time_waited
 ORDER BY ttl_wait_time DESC
 
 
/* What SQL_ID s are currently using the most resources? */
SELECT active_session_history.user_id,
--        dba_users.username,
--        sqlarea.sql_text,
		active_session_history.sql_id,
/*		active_session_history.wait_time,
		 active_session_history.time_waited,*/
		SUM(active_session_history.wait_time +
            active_session_history.time_waited) ttl_wait_time
   FROM  DBA_HIST_ACTIVE_SESS_HISTORY active_session_history
--        ,v$sqlarea sqlarea
--        ,dba_users
  WHERE 1=1
-- AND active_session_history.user_id=153  /* OZLRAC */
--  AND active_session_history.user_id=63 /* KKM_USER MILENAS */
AND sample_time BETWEEN TO_DATE('20060315 07:03:31','YYYYMMDD HH24:MI:SS') AND TO_DATE('20060315 09:10:41','YYYYMMDD HH24:MI:SS') 
--AND active_session_history.sample_time BETWEEN SYSDATE - 90/1440 AND SYSDATE    
--  and active_session_history.sample_time BETWEEN SYSDATE - 60/2880 AND SYSDATE
--    AND active_session_history.sql_id = sqlarea.sql_id
--    AND active_session_history.user_id = dba_users.user_id
 GROUP BY active_session_history.user_id
 --,sqlarea.sql_text 
 --,dba_users.username
,active_session_history.sql_id
-- ,active_session_history.wait_time,active_session_history.time_waited
 ORDER BY ttl_wait_time DESC
 
/*  What object is currently causing the highest resource waits? */ 
  SELECT DBA_OBJECTS.owner,
  		DBA_OBJECTS.object_name,
        DBA_OBJECTS.object_type,
		active_session_history.sql_id,
		active_session_history.user_id,	
		active_session_history.session_id,		
		active_session_history.program,
--		active_session_history.wait_time, 		active_session_history.time_waited, 
        SUM(active_session_history.wait_time +
            active_session_history.time_waited) ttl_wait_time
   FROM DBA_HIST_ACTIVE_SESS_HISTORY   active_session_history,
        DBA_OBJECTS
  WHERE 1=1 
--   AND active_session_history.session_id=260
-- AND active_session_history.user_id=153  /* OZLRAC */
-- AND active_session_history.user_id=139  /* KKM_USER */
-- AND active_session_history.user_id=110  /* UYE */
-- AND active_session_history.user_id=124  /* OWBTARGET */
-- AND active_session_history.user_id=81  /* OWBRT_SYS */
-- AND active_session_history.user_id=79  /* OWBRUNTIME */
-- AND active_session_history.user_id=80  /* OWBRUNACC */
--  AND active_session_history.session_id IN (230,164)
--  and active_session_history.sample_time BETWEEN SYSDATE - 60/2880 AND SYSDATE
--  AND active_session_history.user_id=63 /* KKM_USER MILENAS */
AND sample_time BETWEEN TO_DATE('20060315 07:03:31','YYYYMMDD HH24:MI:SS') AND TO_DATE('20060315 09:10:41','YYYYMMDD HH24:MI:SS') 
--AND active_session_history.sample_time BETWEEN SYSDATE - 90/1440 AND SYSDATE	  
    AND active_session_history.current_obj# = DBA_OBJECTS.object_id
 GROUP BY DBA_OBJECTS.owner,DBA_OBJECTS.object_name, DBA_OBJECTS.object_type,active_session_history.sql_id, active_session_history.user_id
 ,active_session_history.session_id,active_session_history.program
-- ,active_session_history.wait_time,active_session_history.time_waited
 ORDER BY  ttl_wait_time DESC
-- ORDER BY  active_session_history.sql_id ASC,ttl_wait_time DESC

DBA_HIST_SQLTEXT

SELECT * FROM DBA_OBJECTS WHERE object_name LIKE 'DBA_HIST_SQL%'

SELECT * FROM DBA_HIST_SQLSTAT where sql_id='c3k217ag3nctu'
