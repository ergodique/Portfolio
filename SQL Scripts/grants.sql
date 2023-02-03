
select    a.grantee, a.OWNER, a.table_name,a.privilege  from dba_tab_privs a, dba_users b
where a.grantee=b.username and b.account_status ='OPEN' AND grantee like ('PRJ%') and a.privilege in ('INSERT','UPDATE','DELETE')
order by 1


select    distinct a.grantee, a.OWNER from dba_tab_privs a, dba_users b
where a.grantee=b.username and b.account_status ='OPEN' AND grantee like ('PRJ%') --and a.privilege in ('INSERT','UPDATE','DELETE')
order by 1




select distinct s.username, S.v_osuser,S.V_MACHINE from ISBDBA.SESSION_RULES_log  s , dba_users b where S.USERNAME = B.USERNAME and B.ACCOUNT_STATUS = 'OPEN'   and S.logon_time > sysdate-30 and S.USERNAME like 'PRJ%'
order by 1