select USERNAME,LOGON_TIME,LAST_CALL_ET,STATUS from v$session v where username='ITCAM';

select s.sid || ', ' || s.serial# sid_serial, p.spid,
s.username || '/' || s.osuser username, s.status,
to_char(s.logon_time, 'DD-MON-YY HH24:MI:SS') logon_time,
trunc(s.last_call_et/60) idle_min,
w.event || ' / ' || w.p1 || ' / ' || w.p2 || ' / ' || w.p3 waiting_event,
p.program
from v$process p, v$session s, v$session_wait w
where s.paddr=p.addr --and s.sid=&Oracle_SID
and w.sid = s.sid
and s.username in ('ITCAM')
order by last_Call_et desc;
