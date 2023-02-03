SELECT ROUND((s.SOFAR/s.totalwork)*100,2) progress,s.* FROM gv$session_longops s WHERE username='SYS'
AND opname LIKE 'RMAN%'
AND s.sofar<s.totalwork
order by 1 desc;

/* backup sessions*/
select inst_id,sid,username,status,machine,program,module,client_info,last_call_et,event,wait_class,wait_time,seconds_in_wait,state from gv$session where username='SYS'
and program like 'rman%';


/* backup sessions*/
select ROUND((s.SOFAR/s.totalwork)*100,2) progress,gv.module,s.time_remaining,s.elapsed_seconds,s.start_time,gv.inst_id,gv.sid,gv.username,gv.status,gv.machine,gv.program,gv.client_info,gv.last_call_et,gv.event,gv.wait_class,gv.wait_time,gv.seconds_in_wait,gv.state 
from gv$session gv,gv$session_longops s  where gv.sid = s.sid and gv.username='SYS' and s.opname like 'RMAN%' and s.sofar<s.totalwork
and gv.program like 'rman%';


INC*
SELECT COUNT (1)
  FROM gv$session
WHERE     (inst_id, sid) IN
              (SELECT DISTINCT ro.inst_id, ro.sid
                 FROM V$RMAN_BACKUP_JOB_DETAILS rs, gv$rman_output ro
                WHERE     rs.session_recid = ro.session_recid
                      AND rs.session_stamp = ro.session_stamp
                      AND rs.status LIKE 'RUNNING%'
                      AND rs.input_type = 'DB INCR')
       AND UPPER (program) LIKE 'RMAN%';

ARC*
SELECT COUNT (1)
  FROM gv$session
WHERE     (inst_id, sid) IN
              (SELECT DISTINCT ro.inst_id, ro.sid
                 FROM V$RMAN_BACKUP_JOB_DETAILS rs, gv$rman_output ro
                WHERE     rs.session_recid = ro.session_recid
                      AND rs.session_stamp = ro.session_stamp
                      AND rs.status LIKE 'RUNNING%'
                      AND rs.input_type = 'ARCHIVELOG')
       AND UPPER (program) LIKE 'RMAN%';

*DO*
SELECT COUNT (1)
  FROM gv$session
WHERE     (inst_id, sid) IN
              (SELECT DISTINCT ro.inst_id, ro.sid
                 FROM v$rman_status rs, gv$rman_output ro
                WHERE     rs.recid = ro.session_recid
                      AND rs.stamp = ro.session_stamp
                      AND rs.status LIKE 'RUNNING%'
                      AND UPPER (ro.output) LIKE '%OBSOLETE%')
       AND UPPER (program) LIKE 'RMAN%';

MERGE*

SELECT COUNT (1)
  FROM gv$session
WHERE     (inst_id, sid) IN
              (SELECT DISTINCT ro.inst_id, ro.sid
                 FROM V$rman_backup_job_details rs, gv$rman_output ro
                WHERE     rs.session_recid = ro.session_recid
                      AND rs.session_stamp = ro.session_stamp
                      AND rs.status LIKE 'RUNNING%'
                      AND (   UPPER (ro.output) LIKE '%MERGE%'
                           OR UPPER (ro.output) LIKE '%IMG_LVL0%'))
       AND UPPER (program) LIKE 'RMAN%';
BACKUPFRATOVTL

SELECT COUNT (1)
  FROM gv$session
WHERE     (inst_id, sid) IN
              (SELECT DISTINCT ro.inst_id, ro.sid
                 FROM V$rman_backup_job_details rs, gv$rman_output ro
                WHERE     rs.session_recid = ro.session_recid
                      AND rs.session_stamp = ro.session_stamp
                      AND rs.status LIKE 'RUNNING%'
                      AND (   UPPER (ro.output) LIKE '%BACKUPFRATOVTL%'
                           OR UPPER (ro.output) LIKE '%FRA_LVL0%'))
       AND UPPER (program) LIKE 'RMAN%';

