select * from dba_extents
where tablespace_name= 'SWITCH'
and segment_type in ('TABLE','TABLE PARTITION')
order by block_id desc


select * from dba_extents
where file_id = 36
order by block_id desc


select distinct 'ALTER TABLE '||owner||'.'||segment_name||' MOVE PARTITION '||PARTITION_NAME||'TABLESPACE SWITCH_NEW;',block_id from dba_extents
where tablespace_name= 'SWITCH'
and segment_type = 'TABLE PARTITION'
union all
select distinct 'ALTER TABLE '||owner||'.'||segment_name||' MOVE TABLESPACE SWITCH_NEW;' ,block_id from dba_extents
where tablespace_name= 'SWITCH'
and segment_type = 'TABLE'
order by block_id desc


select * from dba_indexes where tablespace_name = 'SWITCH'

select * from dba_ind_partitions where tablespace_name = 'SWITCH'

select owner, table_name,'' part_name  from dba_tables where tablespace_name = 'SWITCH'
union all
select table_owner,table_name,partition_name from dba_tab_partitions where tablespace_name = 'SWITCH'

