select 'ALTER USER SMODEL QUOTA UNLIMITED ON '||tablespace_name||';' from dba_tables where owner ='SMODEL'
union  
select 'ALTER USER SMODEL QUOTA UNLIMITED ON '||tablespace_name||';' from dba_tab_partitions where table_owner ='SMODEL' 
union
select 'ALTER USER SMODEL QUOTA UNLIMITED ON '||tablespace_name||';' from dba_indexes where table_owner ='SMODEL'
union  
select 'ALTER USER SMODEL QUOTA UNLIMITED ON '||a.tablespace_name||';' from dba_ind_partitions a, dba_indexes b where a.INDEX_OWNER=b.OWNER and a.INDEX_NAME=b.INDEX_NAME and  b.table_owner ='SMODEL' 
 