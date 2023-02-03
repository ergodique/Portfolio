WITH W as(
 select rownum class#, class from v$waitstat)
select 
    sw.sid sw_sid, 
    CASE WHEN sw.state != 'WAITING' THEN 'WORKING'
        ELSE 'WAITING'
    END AS state, 
    CASE WHEN sw.state != 'WAITING' THEN 'On CPU / runqueue'
        ELSE sw.event
    END AS sw_event, 
    sw.seq#, 
    sw.seconds_in_wait sec_in_state, 
    sw.p1,
    sw.p2,
    sw.p3,
    CASE 
        WHEN sw.event like 'enq%' AND sw.state = 'WAITING' THEN 
            '0x'||trim(to_char(sw.p1, 'XXXXXXXXXXXXXXXX'))||': '||
            chr(bitand(sw.p1, -16777216)/16777215)||
            chr(bitand(sw.p1,16711680)/65535)||
            ' mode'||bitand(sw.p1, power(2,14)-1)
        WHEN (sw.event like 'buffer busy%' or sw.event like 'read by %') AND sw.state='WAITING' THEN
        (select w.class from  w where  w.class#(+)=sw.p3)|| (select '  obj='||object_name||' type='||object_type from dba_objects o where o.objecT_id(+)=s.ROW_WAIT_OBJ#)
        WHEN sw.event like 'latch%' AND sw.state = 'WAITING' THEN 
             '0x'||trim(to_char(sw.p1, 'XXXXXXXXXXXXXXXX'))||': '||(
                     select name||'[par' 
                         from v$latch_parent 
                         where addr = hextoraw(trim(to_char(sw.p1,rpad('0',length(rawtohex(addr)),'X'))))
                      union all
                      select name||'[c'||child#||']' 
                          from v$latch_children 
                         where addr = hextoraw(trim(to_char(sw.p1,rpad('0',length(rawtohex(addr)),'X'))))
             )
    ELSE NULL END AS sw_p1transl,s.sql_id
FROM 
    v$session_wait sw,v$session s
WHERE 
    sw.sid IN (select sid from v$session where status='ACTIVE' and type<>'BACKGROUND')
    and sw.sid=s.sid
ORDER BY
    state,
    sw_event,
    p1,
        sql_id,
    p2,    
    p3;



select s.username curr_user, s.machine, executions, 
round(decode(executions,0,0,(disk_reads/executions))) reads_per, 
round(decode(executions,0,0,(buffer_gets/executions))) buff_per, 
round(decode(executions,0,0,(rows_processed/executions))) rows_per,  
round(decode(executions,0,0,(elapsed_time/executions))) elapsed_per, 
first_load_time,sql_text
from v$sqlarea v, dba_users d, v$session s
where d.user_id = v.parsing_user_id
and s.sql_address=v.address and s.sql_hash_value=v.hash_value
--and s.sid=&session_id
order by decode(executions,0,0,(elapsed_time/executions)) desc;


select program,event,count(*) from v$session where state = 'WAITING'
group by program,event
order by 3 desc;

select username,event,count(*) from v$session where event not like '%SQL*Net message from client%'
group by username,event
order by 3 desc;

--LOCKS
select /*+ rule */ se.USERNAME, se.osuser, l.sid, l.type, 
l.id1, l.id2, lmode, request, block, do.OBJECT_NAME, do.owner 
from v$lock l, dba_objects do, v$session se 
where l.sid>5
and l.sid=se.sid and l.id1=do.object_id(+)
order by block desc, l.sid;


select l1.sid, ' IS BLOCKING ', l2.sid
   from v$lock l1, v$lock l2
    where l1.block =1 and l2.request > 0
    and l1.id1=l2.id1
   and l1.id2=l2.id2;
   
select s1.username || '@' || s1.machine
    || ' ( SID=' || s1.sid || ' )  is blocking '
    || s2.username || '@' || s2.machine || ' ( SID=' || s2.sid || ' ) ' AS blocking_status
    from v$lock l1, v$session s1, v$lock l2, v$session s2
    where s1.sid=l1.sid and s2.sid=l2.sid
    and l1.BLOCK=1 and l2.request > 0
    and l1.id1 = l2.id1
    and l2.id2 = l2.id2 ;

   
select * from dba_blockers;


select 
   sid,
   username,
   round(100 * total_user_io/total_io,2) tot_io_pct
from
(select 
     b.sid sid,
     nvl(b.username,p.name) username,
     sum(value) total_user_io
 from 
     sys.v_$statname c,  
     sys.v_$sesstat a,
     sys.v_$session b,
     sys.v_$bgprocess p
 where 
      a.statistic#=c.statistic# and 
      p.paddr (+) = b.paddr and
      b.sid=a.sid and 
      c.name in ('physical reads',
                 'physical writes',
                 'physical writes direct',
                 'physical reads direct',
                 'physical writes direct (lob)',
                 'physical reads direct (lob)') 
group by 
      b.sid, nvl(b.username,p.name)),
(select 
      sum(value) total_io 
 from 
      sys.v_$statname c, 
      sys.v_$sesstat a 
 where 
      a.statistic#=c.statistic# and 
      c.name in ('physical reads',
                 'physical writes', 
                 'physical writes direct',
                 'physical reads direct',
                 'physical writes direct (lob)',
                 'physical reads direct (lob)'))
order by 
      3 desc;
      
      
      
select p.spid "OS PID", b.name "Background Process", 
s.sid, s.username "User Name", s.osuser "OS User", 
s.machine "User Machine"
from v$process p, v$bgprocess b, v$session s
where s.sid=115 --put your SID here
and s.paddr=p.addr
and b.paddr(+) = p.addr ;




