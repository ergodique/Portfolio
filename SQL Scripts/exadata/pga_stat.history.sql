
set line 200 pages 1000
select s.INSTANCE_NUMBER instid, s.snap_id,
       to_char(s.BEGIN_INTERVAL_TIME, 'dd-mm-yyyy hh24:mi:ss') begin_time,
       to_char(s.END_INTERVAL_TIME, 'dd-mm-yyyy hh24:mi:ss') end_time,
       p.name, p.value
  from dba_hist_pgastat p, dba_hist_snapshot s
 where p.snap_id = s.snap_id
   and p.instance_number = s.instance_number
   and s.begin_interval_time between sysdate - 1 and sysdate
  order by 1,2,5;
