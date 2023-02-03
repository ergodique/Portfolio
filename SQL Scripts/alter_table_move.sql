SELECT    'ALTER TABLE '
       || table_name
       || ' MOVE PARTITION '
       || partition_name
       || ' TABLESPACE SWITCH_NEW;'
  FROM dba_tab_partitions
 WHERE tablespace_name = 'SWITCH'


select * from dba_ind_partitions where tablespace_name = 'SWITCH'

SELECT 'ALTER INDEX '||INDEX_OWNER||'.'||INDEX_NAME||' REBUILD PARTITION '||PARTITION_NAME||' TABLESPACE ARCHIVE;' FROM dba_ind_partitions where tablespace_name = 'SWITCH' AND INDEX_OWNER= 'ARCHIVE'

select 'ALTER TABLE '||TABLE_OWNER||'.'||TABLE_NAME||' MOVE PARTITION '||PARTITION_NAME||' TABLESPACE ARCHIVE;' 
from dba_tab_partitions 
where table_owner = 'ARCHIVE' and tablespace_name <> 'ARCHIVE' and num_rows = 0
ORDER BY 1 DESC
  
select 'ALTER INDEX '||INDEX_OWNER||'.'||INDEX_NAME||' REBUILD PARTITION '||PARTITION_NAME||' TABLESPACE ARCHIVE;' 
from dba_ind_partitions 
where index_owner = 'ARCHIVE' and tablespace_name <> 'ARCHIVE' and num_rows = 0
ORDER BY 1 DESC


select 'ALTER TABLE '||TABLE_OWNER||'.'||TABLE_NAME||' MOVE PARTITION '||PARTITION_NAME||';' 
from dba_tab_partitions 
where table_owner = 'HOST' and table_name = 'HOST_TRNX' and num_rows = 0 and (to_date(substr(partition_name,14,8),'YYYYMMDD')<trunc(sysdate))
ORDER BY 1 ;

select to_date(substr(partition_name,14,8),'YYYYMMDD') from dba_tab_partitions where table_owner = 'HOST' and table_name = 'HOST_TRNX';

select trunc(sysdate) from dual