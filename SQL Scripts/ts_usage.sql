SELECT dhs.BEGIN_INTERVAL_TIME,a.* FROM  DBA_HIST_TBSPC_SPACE_USAGE a, dba_hist_snapshot dhs 
WHERE dhs.snap_id=a.snap_id  AND instance_number=1 
AND a.snap_id > 3614 
AND tablespace_id=24 
ORDER BY 1

