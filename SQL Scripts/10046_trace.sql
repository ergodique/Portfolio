select spid from v$process p, v$session s where p.addr=s.paddr and s.sid=&sid;

select spid from v$process p, v$session s where p.addr=s.paddr and s.sid in (select sid from v$session where username in ('COMMON','USRKYP'));

select sid,serial# from v$session where username in ('SYSTEM')

select 'EXEC DBMS_SUPPORT.start_trace_in_session(sid=>'||sid||', serial=>'||serial#||', waits=>TRUE, binds=>TRUE);' 
from v$session where username in ('COMMON','USRKYP') 

select 'EXEC DBMS_SUPPORT.stop_trace_in_session(sid=>'||sid||', serial=>'||serial#||');' 
from v$session where username in ('COMMON','USRKYP') 

EXEC DBMS_SUPPORT.start_trace_in_session(sid=>616, serial=>55889, waits=>TRUE, binds=>TRUE)

EXEC DBMS_SUPPORT.stop_trace_in_session(sid=>616, serial=>55889)



        oradebug setospid 1679528;
        
        oradebug unlimit;
        
        oradebug tracefile_identifier='serdar';
        oradebug Event 10046 trace name  context forever,level 16;

        oradebug Event 10046 trace name context off;
        
        
        select a.username Name, 
    a.sid SID, 
    a.serial#, b.spid PID,
        SUBSTR(A.TERMINAL,1,9) TERM,
        SUBSTR(A.OSUSER,1,9) OSUSER,
    substr(a.program,1,10) Program,
        a.status Status,
        to_char(a.logon_time,'MM/DD/YYYY hh24:mi') Logon_time
from v$session a,
     v$process b
where a.paddr = b.addr
and a.serial# <> '1'
--and a.status = 'ACTIVE'
and a.username like upper('%SYSTEM%') -- if you want to filter by username
order by a.logon_time
