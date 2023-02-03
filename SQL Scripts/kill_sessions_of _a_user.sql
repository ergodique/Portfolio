SELECT    'execute isbdba.kill_session('
       || CHR (39)
       || SID
       || CHR (39)
       || ','
       || CHR (39)
       || serial#
       || CHR (39)
       || '); '
  FROM v$session
 WHERE username likre 'FRAUD%' AND status='INACTIVE'
 
 
 SELECT status,COUNT(*)  FROM v$session
 WHERE username = 'KKM_USER' --AND status='INACTIVE'
 GROUP BY status

   SELECT username,status,TO_CHAR(logon_time,'YYYYMMDD HH24:MI'),COUNT(*)  FROM v$session
 WHERE username LIKE 'FRAUD%'  --AND status='ACTIVE'
 GROUP BY username,status,TO_CHAR(logon_time,'YYYYMMDD HH24:MI')