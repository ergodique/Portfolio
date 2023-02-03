select 'alter table smodel.abm_aiovp move partition '||partition_name||' tablespace AIOVP1;'  from dba_tab_partitions where TABLE_NAME='ABM_AIOVP';

select 'alter index '||index_owner||'.'||index_name||' rebuild partition '||partition_name||' tablespace AIOVP1;'  from dba_ind_partitions where TABLESPACE_NAME like 'AIOVP%';