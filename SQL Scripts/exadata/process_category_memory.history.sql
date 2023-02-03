
set line 200 pages 1000
select s.INSTANCE_NUMBER instid, s.snap_id,
       to_char(s.BEGIN_INTERVAL_TIME, 'dd-mm-yyyy hh24:mi:ss') begin_time,
       to_char(s.END_INTERVAL_TIME, 'dd-mm-yyyy hh24:mi:ss') end_time,
       pm.category, pm.NUM_PROCESSES,
       round(pm.ALLOCATED_TOTAL/(1024*1024),2) "ALLOC TOTAL(MB)",
       round(pm.USED_TOTAL/(1024*1024),2) "USED TOTAL(MB)",
       round(pm.ALLOCATED_AVG/(1024*1024),2) "ALLOC AVG(MB)",
       round(pm.ALLOCATED_STDDEV/(1024*1024),2) "ALLOC STDDEV(MB)",
       round(pm.ALLOCATED_MAX/(1024*1024),2) "ALLOC MAX(MB)",
       round(pm.MAX_ALLOCATED_MAX/(1024*1024),2) "MAX ALLOC MAX(MB)"
  from DBA_HIST_PROCESS_MEM_SUMMARY pm, dba_hist_snapshot s
 where pm.snap_id = s.snap_id
   and pm.instance_number = s.instance_number
   and pm.ALLOCATED_TOTAL > 1024 * 1024 * 1024
   and s.begin_interval_time between sysdate - 1 and sysdate
  order by 1,2,5;
