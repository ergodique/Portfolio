select a.* from v$process p,v$session s,v$sqlarea a where p.ADDR=s.PADDR and s.SQL_ID = a.SQL_ID and  p.sPID = 6836336 ;

select * from v$sqlarea a where a.SQL_ID = '779s4601t4v6f' 