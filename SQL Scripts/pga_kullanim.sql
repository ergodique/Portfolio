select sum(pga_alloc_mem)/1048576,count(*) from v$process;

SELECT NVL(a.username,'(oracle)') AS username,
trunc(sum(b.value)/1024/1024) AS memory_MB
FROM gv$session a,
gv$sesstat b,
gv$statname c
WHERE a.sid = b.sid
AND a.inst_id = b.inst_id
AND b.statistic# = c.statistic#
AND b.inst_id = c.inst_id
AND c.name = 'session pga memory'
AND a.program IS NOT NULL
group by username
ORDER BY 2 DESC;

SELECT trunc(sum(b.value)/1024/1024) AS memory_MB
FROM gv$session a,
gv$sesstat b,
gv$statname c
WHERE a.sid = b.sid
AND a.inst_id = b.inst_id
AND b.statistic# = c.statistic#
AND b.inst_id = c.inst_id
AND c.name in ('session pga memory max','session uga memory max')
AND a.program IS NOT NULL;


select vses.username||':'||vsst.sid||','||vses.serial# username, vstt.name, max(vsst.value) value 
from v$sesstat vsst, v$statname vstt, v$session vses
where vstt.statistic# = vsst.statistic# and vsst.sid = vses.sid and vstt.name in 
('session pga memory','session pga memory max','session uga memory','session uga memory max', 
'session cursor cache count','session cursor cache hits','session stored procedure space',
'opened cursors current','opened cursors cumulative') and vses.username is not null
group by vses.username, vsst.sid, vses.serial#, vstt.name 
order by vses.username, vsst.sid, vses.serial#, vstt.name;

select vses.username, max(vsst.value)
from v$sesstat vsst, v$statname vstt, v$session vses
where vstt.statistic# = vsst.statistic# and vsst.sid = vses.sid 
and vstt.name in ('session pga memory max','session uga memory max') and vses.username is not null
group by vses.username
order by 2 desc;

SELECT a.inst_id,
NVL(a.username,'(oracle)') AS username,
a.module,
a.program,
Trunc(b.value/1024/1024) AS memory_MB
FROM gv$session a,
gv$sesstat b,
gv$statname c
WHERE a.sid = b.sid
AND a.inst_id = b.inst_id
AND b.statistic# = c.statistic#
AND b.inst_id = c.inst_id
AND c.name = 'session pga memory'
AND a.program IS NOT NULL
ORDER BY 5 DESC;



