select 'ALTER TABLE '||a.OWNER||'.'||a.TABLE_NAME||' LOGGING;' 
from dba_tables a 
where a.tablespace_name = 'TSMBRTP' and a.LOGGING='NO'
union all  
select 'ALTER TABLE '||a.TABLE_OWNER||'.'||a.TABLE_NAME||' MODIFY PARTITION '||a.PARTITION_NAME||' LOGGING;' 
from dba_tab_partitions a 
where tablespace_name = 'TSMBRTP' and a.LOGGING='NO' 
union all  
select 'ALTER TABLE '||a.TABLE_OWNER||'.'||a.TABLE_NAME||' MODIFY SUBPARTITION '||a.SUBPARTITION_NAME||' LOGGING;' 
from dba_tab_subpartitions a 
where tablespace_name = 'TSMBRTP' and a.LOGGING='NO' 
union all
select 'ALTER INDEX '||a.OWNER||'.'||a.INDEX_NAME|| ' LOGGING;' 
from dba_indexes a 
where tablespace_name = 'TSMBRTP' and a.LOGGING='NO'
union all
select 'ALTER INDEX '||a.INDEX_OWNER||'.'||a.INDEX_NAME||' MODIFY PARTITION '||a.PARTITION_NAME||' LOGGING;' 
from dba_ind_partitions a, dba_indexes b 
where a.INDEX_OWNER=b.OWNER and a.INDEX_NAME=b.INDEX_NAME and a.tablespace_name = 'TSMBRTP' and a.LOGGING='NO'
union all
select 'ALTER INDEX '||a.INDEX_OWNER||'.'||a.INDEX_NAME||' MODIFY SUBPARTITION '||a.SUBPARTITION_NAME||' LOGGING;' 
from dba_ind_subpartitions a, dba_indexes b 
where a.INDEX_OWNER=b.OWNER and a.INDEX_NAME=b.INDEX_NAME and a.tablespace_name = 'TSMBRTP' and a.LOGGING='NO'  