--select a.* from v$instance a
select a.owner, a.table_name, a.tablespace_name from dba_tables a where a.tablespace_name = 'SYSTEM' and a.owner ='SMODEL'  