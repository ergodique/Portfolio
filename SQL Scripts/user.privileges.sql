set echo off
set linesize 512
break on GRANTEE 
break on granted_role skip 1

select a.GRANTEE , a.GRANTED_ROLE , b.PRIVILEGE , c.ACCOUNT_STATUS
from sys.dba_role_privs a , sys.dba_sys_privs b , sys.dba_users c
where a.GRANTED_ROLE = b.GRANTEE and c.USERNAME = a.grantee and c.ACCOUNT_STATUS = 'OPEN' and b.privilege like 'RES%'; 

select a.USERNAME GRANTEE , 'DIRECTLY GRANTED TO' GRANTED_ROLE, b.PRIVILEGE , a.ACCOUNT_STATUS  
from sys.dba_users a , sys.dba_sys_privs b
where a.USERNAME = b.GRANTEE and a.ACCOUNT_STATUS = 'OPEN' and b.privilege like 'RES%';