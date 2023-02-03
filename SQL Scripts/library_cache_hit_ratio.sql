SELECT namespace, gets, gethitratio * 100 gethitratio, pins,
       pinhitratio * 100 pinhitratio, reloads, invalidations
  FROM v$librarycache


/* DATA DICTIONARY HIT RATIO should be > 90%, else increase SHARED_POOL_SIZE */
SELECT 	SUM(GETS),
	SUM(GETMISSES),
	ROUND((1 - (SUM(GETMISSES) / SUM(GETS))) * 100,2)
FROM 	v$rowcache
   
   
/* SQL CACHE HIT RATIO */
SELECT 	SUM(PINS) Pins,
	SUM(RELOADS) Reloads,
	ROUND((SUM(PINS) - SUM(RELOADS)) / SUM(PINS) * 100,2) Hit_Ratio
FROM 	v$librarycache  

/* Library Cache Miss Ratio should be < 1%, else increase SHARED_POOL_SIZE*/
SELECT 	SUM(PINS) Executions,
	SUM(RELOADS) cache_misses,
	SUM(RELOADS) / SUM(PINS) miss_ratio
FROM 	v$librarycache 


/* BUFFER HIT RATIO Hit Ratio should be > 80%, else increase DB_BLOCK_BUFFERS */
SELECT 	SUM(DECODE(NAME, 'consistent gets',VALUE, 0)) "Consistent Gets",
	SUM(DECODE(NAME, 'db block gets',VALUE, 0)) "DB Block Gets",
	SUM(DECODE(NAME, 'physical reads',VALUE, 0)) "Physical Reads",
	ROUND((SUM(DECODE(NAME, 'consistent gets',VALUE, 0)) + 
	       SUM(DECODE(NAME, 'db block gets',VALUE, 0)) - 
	       SUM(DECODE(NAME, 'physical reads',VALUE, 0))) / 
	      (SUM(DECODE(NAME, 'consistent gets',VALUE, 0)) + 
	       SUM(DECODE(NAME, 'db block gets',VALUE, 0))) * 100,2) "Hit Ratio"
FROM   v$sysstat 
  
  SELECT * FROM dba_views WHERE view_name LIKE 'DBA%CACHE%'
  
SELECT * FROM   v$sgastat
WHERE NAME ='library cache'

  SELECT bytes
     FROM v$sgastat
    WHERE NAME = 'free memory'  AND POOL = 'shared pool';
  
  
  dba_hist_snapshot
  
SELECT sga.*,snap.* FROM  DBA_HIST_SGASTAT sga , dba_hist_snapshot snap
WHERE 1=1
AND sga.SNAP_ID = snap.snap_id 
AND sga.INSTANCE_NUMBER = snap.INSTANCE_NUMBER 
--AND NAME ='library cache'
AND NAME = 'free memory' AND POOL = 'shared pool'
AND sga.instance_number=2
ORDER BY snap.BEGIN_INTERVAL_TIME DESC


DBA_HIST_BUFFER_POOL_STAT