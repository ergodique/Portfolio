stats$snapshot

SELECT s.snap_id /*into :begin_snap_id*/ FROM stats$snapshot s, v$instance i 
WHERE i.INSTANCE_NUMBER = s.INSTANCE_NUMBER 
AND snap_time = 
(SELECT MIN(snap_time) FROM stats$snapshot s, v$instance i WHERE 
i.INSTANCE_NUMBER = s.INSTANCE_NUMBER 
AND TO_CHAR(snap_time,'YYYYMMDD')=TO_CHAR(SYSDATE,'YYYYMMDD'))

SELECT snap_id /*into :begin_snap_id*/ FROM stats$snapshot WHERE snap_time = (SELECT MAX(snap_time) FROM stats$snapshot WHERE TO_CHAR(snap_time,'YYYYMMDD')=TO_CHAR(SYSDATE,'YYYYMMDD'))


SELECT * FROM stats$snapshot WHERE TO_CHAR(snap_time,'YYYYMMDD')=TO_CHAR(SYSDATE,'YYYYMMDD') ORDER BY snap_time ASC

SELECT MIN(snap_time) FROM stats$snapshot s, v$instance i WHERE 
i.INSTANCE_NUMBER = s.INSTANCE_NUMBER 
AND TO_CHAR(snap_time,'YYYYMMDD')=TO_CHAR(SYSDATE,'YYYYMMDD')