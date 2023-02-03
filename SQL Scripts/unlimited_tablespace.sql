--select * from v$instance
--select a.grantee, b.USER_ID, b.ACCOUNT_STATUS, b.CREATED, b.LOCK_DATE, b.EXPIRY_DATE from dba_role_privs a, dba_users b where a.GRANTEE = b.USERNAME and granted_role like 'RESOU%'
select a.grantee, b.USER_ID, b.ACCOUNT_STATUS, a.PRIVILEGE, b.CREATED, b.LOCK_DATE, b.EXPIRY_DATE from dba_sys_privs a, dba_users b where a.GRANTEE = b.USERNAME and privilege like 'UNLIM%'
