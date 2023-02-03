
select TABLE_OWNER,TABLE_NAME,(INITIAL_EXTENT/1024/1024) from dba_tab_partitions where (INITIAL_EXTENT/1024/1024) > 5
order by 3 desc;

ALTER TABLE ARCHIVE.HOST_TRNX_ARCH MODIFY PARTITION HOSTTRNXPART_20080315 DEALLOCATE UNUSED KEEP 64K;

select 'alter table ARCHIVE.'||table_name||' MODIFY PARTITION '||partition_name||' DEALLOCATE UNUSED KEEP 64K;' 
from dba_tab_partitions where table_owner ='ARCHIVE' and (INITIAL_EXTENT/1024/1024) > 5



