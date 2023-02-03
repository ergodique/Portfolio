select * from dba_ind_partitions where tablespace_name = 'HOST_TRNX_INDX' and index_owner = 'HOST' and partition_name like 'HOSTTRNXPART_200705%'
order by partition_name

select 'alter table host.host.trnx move partititon '||partition_name||' ;' 
from dba_tab_partitions 
where table_name = 'HOST_TRNX'
and partition_name like 'HOSTTRNXPART_200705%'


select 'alter index host.'||index_name||' rebuild partition '||partition_name||' online;' 
from  dba_ind_partitions 
where tablespace_name = 'HOST_TRNX_INDX' 
and index_owner = 'HOST' 
and partition_name like 'HOSTTRNXPART_2007%'
order by partition_name

