SELECT a.grantee, a.granted_role,b.privilege
  FROM SYS.dba_role_privs a,SYS.dba_sys_privs b ,  SYS.dba_users c
 WHERE c.username = a.grantee and a.granted_role = b.grantee and c.account_status = 'OPEN' AND C.username not in ('STRMADMIN','DBSNMP', 'SYS','SYSMAN','SYSTEM')and b.privilege not in ('ALTER SESSION','CREATE SESSION')
union 
SELECT d.username grantee, 'DIRECTLY GRANTED TO' granted_role, e.PRIVILEGE
  FROM SYS.dba_users d, SYS.dba_sys_privs e
 WHERE d.username = e.grantee and d.account_status = 'OPEN' and d.username not in ('STRMADMIN','DBSNMP' ,'SYS','SYSMAN','SYSTEM') and e.privilege not in ('ALTER SESSION','CREATE SESSION')
union
SELECT a.grantee, a.granted_role,'DBA' PRIVILEGE
  FROM SYS.dba_role_privs a ,  SYS.dba_users c
 WHERE c.username = a.grantee and  c.account_status = 'OPEN' AND a.granted_role='DBA' and a.grantee not in ('SYS','SYSTEM','SYSMAN')
union
select a. grantee,a.OWNER||'.'|| a.table_name ,a.privilege from dba_tab_privs a, dba_users b
where a.grantee=b.username and b.account_status ='OPEN' AND grantee not in ('SYS','SYSTEM','SYSMAN','DBSNMP')and a.privilege not in ('SELECT','INSERT','UPDATE','DELETE','REFERENCES','EXECUTE')
union
select ROLE,OWNER||'.'||TABLE_NAME,PRIVILEGE from role_tab_privs WHERE OWNER NOT IN ('SYS','SYSMAN','XDB','OLAPSYS','WMSYS','OUTLN') AND PRIVILEGE NOT IN ('SELECT')
;

select 'revoke '||a.privilege||' on '||a.OWNER||'.'|| a.table_name||' from '||a.grantee||';' from dba_tab_privs a, dba_users b
where a.grantee=b.username and b.account_status ='OPEN' AND grantee not in ('SYS','SYSTEM','SYSMAN','DBSNMP')and a.privilege not in ('SELECT','INSERT','UPDATE','DELETE','REFERENCES','EXECUTE')
union
select 'revoke '||privilege||' on '||OWNER||'.'||TABLE_NAME||' from '||role||';' from role_tab_privs WHERE OWNER NOT IN ('SYS','SYSMAN','XDB','OLAPSYS','WMSYS','OUTLN') AND PRIVILEGE NOT IN ('SELECT')
;