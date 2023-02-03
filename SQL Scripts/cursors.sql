select
  'session_cached_cursors'  parameter,
  lpad(value, 5)  value,
  decode(value, 0, '  n/a', to_char(100 * used / value, '990') || '%')  usage
from
  ( select
      max(s.value)  used
    from
      sys.v_$statname  n,
      sys.v_$sesstat  s
    where
      n.name = 'session cursor cache count' and
      s.statistic# = n.statistic#
  ),
  ( select
      value
    from
      sys.v_$parameter
    where
      name = 'session_cached_cursors'
  )
union all
select
  'open_cursors',
  lpad(value, 5),
  to_char(100 * used / value,  '990') || '%'
from
  ( select
      max(sum(s.value))  used
    from
      sys.v_$statname  n,
      sys.v_$sesstat  s
    where
      n.name in ('opened cursors current', 'session cursor cache count') and
      s.statistic# = n.statistic#
    group by
      s.sid
  ),
  ( select
      value
    from
      sys.v_$parameter
    where
      name = 'open_cursors'
  )
;

SELECT 
    ss.username||'('||se.sid||') ' user_process, SUM(DECODE(name,'recursive calls',value)) "Recursive Calls", 
    SUM(DECODE(name,'opened cursors cumulative',value)) "Opened Cursors", 
    SUM(DECODE(name,'opened cursors current',value)) "Current Cursors"
 FROM v$session ss, v$sesstat se, v$statname sn
 WHERE  se.statistic# = sn.statistic#
        AND (name like '%opened cursors current%'
                OR name like '%recursive calls%'
                OR name like '%opened cursors cumulative%')
        AND se.sid = ss.sid
        AND ss.username is not null
--and ss.USERNAME like 'USR%'
GROUP BY ss.username||'('||se.sid||') '
order by 4 desc;

select * from v$sesion s where 


select
  to_char(100 * sess / calls, '999999999990.00') || '%'  cursor_cache_hits,
  to_char(100 * (calls - sess - hard) / calls, '999990.00') || '%'  soft_parses,
  to_char(100 * hard / calls, '999990.00') || '%'  hard_parses
from
  ( select value calls from sys.v_$sysstat where name = 'parse count (total)' ),
  ( select value hard from sys.v_$sysstat where name = 'parse count (hard)' ),
  ( select value sess from sys.v_$sysstat where name = 'session cursor cache hits' )
;



select begin_interval_time,dhl.invalidations from dba_hist_librarycache dhl,dba_hist_snapshot dhs
     where namespace='SQL AREA'
     and dhl.snap_id=dhs.snap_id
     and dhl.instance_number=dhs.instance_number
     and dhl.instance_number=1
     order by dhl.snap_id desc;
     
select namespace,pins,pins-pinhits loads,reloads,invalidations,
100*(reloads-invalidations)/(pins-pinhits) "%RELOADS"
from v$librarycache
where pins > 0
order by namespace;

SELECT SUM(PINS) EXECS,
SUM(RELOADS)MISSES,
SUM(RELOADS)/SUM(PINS) HITRATIO
FROM V$LIBRARYCACHE ;

SELECT event, time_waited
FROM   v$system_event
order by 2 desc
--WHERE  event IN ('SQL*Net message from client', 'smon timer',
--'db file sequential read', 'log file parallel write');


SELECT parameter
     , sum(gets)
     , sum(getmisses)
     , 100*sum(gets - getmisses) / sum(gets)  pct_succ_gets
     , sum(modifications)                     updates
  FROM V$ROWCACHE
 WHERE gets > 0
 GROUP BY parameter;
 

SELECT SUM(VALUE) || ' BYTES' "TOTAL MEMORY FOR ALL SESSIONS"
    FROM V$SESSTAT, V$STATNAME
    WHERE NAME = 'session uga memory'
    AND V$SESSTAT.STATISTIC# = V$STATNAME.STATISTIC#;

SELECT SUM(VALUE) || ' BYTES' "TOTAL MAX MEM FOR ALL SESSIONS"
    FROM V$SESSTAT, V$STATNAME
    WHERE NAME = 'session uga memory max'
    AND V$SESSTAT.STATISTIC# = V$STATNAME.STATISTIC#;
    
    
    select sum(a.value) total_cur, avg(a.value) avg_cur, max(a.value) max_cur, 
s.username, s.machine
from v$sesstat a, v$statname b, v$session s 
where a.statistic# = b.statistic#  and s.sid=a.sid
and b.name = 'opened cursors current' 
group by s.username, s.machine
order by 1 desc;


select sql_id, sql_text, count(*) 
from v$open_cursor
group by sql_id, sql_text
order by count(*) desc;