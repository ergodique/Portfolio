select 'alter table '||owner||'.'||table_name||' compress;' from dba_tables where owner in ('DWH','DWHAUX','ETL','ODS','STG') and (compression = 'DISABLED' )

select owner,table_name,'','' from dba_tables where  owner in ('DWH','DWHAUX','ETL','ODS','STG') and (compression = 'DISABLED')
union
select table_owner,table_name,partition_name,'' from dba_tab_partitions where  table_owner in ('DWH','DWHAUX','ETL','ODS','STG') and (compression = 'DISABLED' )
union
select table_owner,table_name,partition_name,subpartition_name from dba_tab_subpartitions where  table_owner in ('DWH','DWHAUX','ETL','ODS','STG') and (compression = 'DISABLED' )