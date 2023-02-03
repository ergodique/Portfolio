select segment_name,tablespace_name,bytes/1024/1024/1024 GB from dba_segments where tablespace_name like '%UNDO%' order by 3 desc;

SELECT  a.sid, a.username, b.used_urec, b.used_ublk FROM gv$session a, gv$transaction b
WHERE a.saddr = b.ses_addr
ORDER BY b.used_ublk DESC;


/* Formatted on 25.11.2011 23:24:53 (QP5 v5.139.911.3011) */
SELECT TO_CHAR (s.sid), TO_CHAR(s.serial#) ,NVL(s.username, 'None') orauser, s.program, r.name undoseg, t.used_ublk * TO_NUMBER(x.VALUE)/1024/1024
FROM sys.v_$rollname r, sys.v_$session s, sys.v_$transaction t, sys.v_$parameter x 
WHERE s.taddr = t.addr AND r.usn = t.xidusn(+) AND x.name = 'db_block_size'
and r.name like '%68763%'
order by 6 desc;

select * from gv$session s where S.SID = 1241

_SYSSMU134_3094840035$