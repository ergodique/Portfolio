select vt.NAME,
round(days7.max_used,0) "T-7",
round(days6.max_used,0) "T-6",
round(days5.max_used,0) "T-5",
round(days4.max_used,0) "T-4",
round(days3.max_used,0) "T-3",
round(days2.max_used,0) "T-2",
round(days1.max_used,0) "T-1",
round(days0.max_used,0) "T-0",
(round(days6.max_used,0) - round(days7.max_used,0)) "6-7",
(round(days5.max_used,0) - round(days6.max_used,0)) "5-6",
(round(days4.max_used,0) - round(days5.max_used,0)) "4-5",
(round(days3.max_used,0) - round(days4.max_used,0)) "3-4",
(round(days2.max_used,0) - round(days3.max_used,0)) "2-3",
(round(days1.max_used,0) - round(days2.max_used,0)) "1-2",
(round(days0.max_used,0) - round(days1.max_used,0)) "0-1" 
from v$tablespace vt,
(select dh.tablespace_id, max(dh.tablespace_usedsize)/128 max_used 
from DBA_HIST_TBSPC_SPACE_USAGE dh 
where to_date(substr(dh.rtime,1,10),'MM/DD/RRRR') = trunc(sysdate)
group by dh.tablespace_id) days0,
(select dh.tablespace_id, max(dh.tablespace_usedsize)/128 max_used 
from DBA_HIST_TBSPC_SPACE_USAGE dh 
where to_date(substr(dh.rtime,1,10),'MM/DD/RRRR') = trunc(sysdate)-1
group by dh.tablespace_id) days1,
(select dh.tablespace_id, max(dh.tablespace_usedsize)/128 max_used 
from DBA_HIST_TBSPC_SPACE_USAGE dh 
where to_date(substr(dh.rtime,1,10),'MM/DD/RRRR') = trunc(sysdate)-2
group by dh.tablespace_id) days2,
(select dh.tablespace_id, max(dh.tablespace_usedsize)/128 max_used 
from DBA_HIST_TBSPC_SPACE_USAGE dh 
where to_date(substr(dh.rtime,1,10),'MM/DD/RRRR') = trunc(sysdate)-3
group by dh.tablespace_id) days3,
(select dh.tablespace_id, max(dh.tablespace_usedsize)/128 max_used 
from DBA_HIST_TBSPC_SPACE_USAGE dh 
where to_date(substr(dh.rtime,1,10),'MM/DD/RRRR') = trunc(sysdate)-4
group by dh.tablespace_id) days4,
(select dh.tablespace_id, max(dh.tablespace_usedsize)/128 max_used 
from DBA_HIST_TBSPC_SPACE_USAGE dh 
where to_date(substr(dh.rtime,1,10),'MM/DD/RRRR') = trunc(sysdate)-5
group by dh.tablespace_id) days5,
(select dh.tablespace_id, max(dh.tablespace_usedsize)/128 max_used 
from DBA_HIST_TBSPC_SPACE_USAGE dh 
where to_date(substr(dh.rtime,1,10),'MM/DD/RRRR') = trunc(sysdate)-6
group by dh.tablespace_id) days6,
(select dh.tablespace_id, max(dh.tablespace_usedsize)/128 max_used 
from DBA_HIST_TBSPC_SPACE_USAGE dh 
where to_date(substr(dh.rtime,1,10),'MM/DD/RRRR') = trunc(sysdate)-7
group by dh.tablespace_id) days7
where vt.ts# = days0.tablespace_id
and vt.ts# = days1.tablespace_id
and vt.ts# = days2.tablespace_id
and vt.ts# = days3.tablespace_id
and vt.ts# = days4.tablespace_id
and vt.ts# = days5.tablespace_id
and vt.ts# = days6.tablespace_id
and vt.ts# = days7.tablespace_id
and vt.name not like 'TEMP%'
and vt.name not like 'UNDO%'
--order by vt.name
order by 16 desc;


/* Formatted on 2007/05/18 14:26 (Formatter Plus v4.8.8) */
SELECT   NAME, SUM (kullanilan) - TRUNC (max_used) bosyer
    FROM (SELECT   vt.NAME, dh.tablespace_id,
                   MAX (dh.tablespace_usedsize) / 128 max_used, dt.file_name,
                   ROUND (dt.BYTES / 1024 / 1024, 2) kullanilan
              FROM dba_hist_tbspc_space_usage dh,
                   v$tablespace vt,
                   dba_data_files dt
             WHERE TO_DATE (SUBSTR (dh.rtime, 1, 10), 'MM/DD/RRRR') =
                                                               TRUNC (SYSDATE)
               AND dh.tablespace_id = vt.ts#
               AND vt.NAME = dt.tablespace_name
               AND vt.NAME LIKE '%DATA'
          GROUP BY vt.NAME,
                   dh.tablespace_id,
                   dt.file_name,
                   ROUND (dt.BYTES / 1024 / 1024, 2))
GROUP BY NAME, max_used
ORDER BY 2;