--select a.* from v$instance a
--select a.owner, a.index_name, a.index_type, a.status, a.tablespace_name, a.table_owner, a.table_name from dba_indexes a, dba_tables b where a.table_name = b.table_name and b.tablespace_name = 'TSUYE00'
--select 'ALTER INDEX '||a.owner||'.'||a.index_name||' REBUILD TABLESPACE TSUYE00_INDEX;' from dba_indexes a, dba_tables b where a.table_name = b.table_name and b.tablespace_name = 'TSUYE00'
--select 'ALTER INDEX '||a.owner||'.'||a.index_name||' MONITORING USAGE;' from dba_indexes a, dba_tables b where a.table_name = b.table_name and b.tablespace_name = 'TSUYE00'  ;
SELECT index_name, TABLE_NAME, MONITORING, used, START_MONITORING, END_MONITORING FROM dba_OBJECT_USAGE where used = 'NO';