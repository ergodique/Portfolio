  SELECT
   a.average_wait                                 Avg_Waits_forFull_Scan_Read,
   b.average_wait                                  Avg_Waits_for_Index_Read,
   a.total_waits /(a.total_waits + b.total_waits)  Perc_IO_Waits_for_Full_Scans,
   b.total_waits /(a.total_waits + b.total_waits)  Perc_IO_Waits_for_Index_Scans,
   (b.average_wait / a.average_wait)*100           Start_VAL_FOR_opt_IX_COST_adj
FROM
  v$system_event  a,
  v$system_event  b
WHERE
   a.event = 'db file scattered read'
AND
   b.event = 'db file sequential read'
   ;
   
