select 'TABLE' type, a.OWNER, a.TABLE_NAME, 'BASE' partition_name, a.LOGGING from dba_tables a where tablespace_name = 'TSMBRTP'
union  
select 'TABLE_PART' type,a.TABLE_OWNER, a.TABLE_NAME,a.PARTITION_NAME, a.LOGGING from dba_tab_partitions a where tablespace_name = 'TSMBRTP' 
union
select 'INDEX' type, a.OWNER, a.INDEX_NAME, 'BASE' partition_name, a.LOGGING from dba_indexes a where tablespace_name = 'TSMBRTP'
union  
select 'INDEX_PART' type, a.INDEX_OWNER, a.INDEX_NAME, a.PARTITION_NAME, a.LOGGING from dba_ind_partitions a, dba_indexes b where a.INDEX_OWNER=b.OWNER and a.INDEX_NAME=b.INDEX_NAME and a.tablespace_name = 'TSMBRTP' 