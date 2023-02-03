select count(*) from v$process

select * from V$session a,v$process b where   b.addr=a.paddr 

select spid from v$process where addr not in (select paddr from v$session) order by 1

select p.*  from v$process p where p.addr not in (select s.paddr from v$sessIon s) and p.program not in ('PSEUDO','oracle@kaadkora01 (S000)','oracle@kaadkora01 (D000)') order by 1;

select 'kill -9 '||spid  from v$process p where p.addr not in (select s.paddr from v$sessIon s) and p.program not in ('PSEUDO','oracle@kaadkora01 (S000)','oracle@kaadkora01 (D000)') order by 1;

SELECT s.*,p.* FROM v$process p, v$session s WHERE spid = 23227
AND s.paddr=p.addr
