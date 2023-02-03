-- fast blocking_move
SELECT 'ALTER TABLE '||a.OWNER||'.'||a.TABLE_NAME||' MOVE TABLESPACE TSCREDITDB_NEW;' col1 
FROM dba_tables a 
WHERE a.owner='CREDITDB' AND a.tablespace_name = 'TSCREDITDB'
UNION  
SELECT 'ALTER TABLE '||a.TABLE_OWNER||'.'||a.TABLE_NAME||' MOVE PARTITION '||a.PARTITION_NAME||' TABLESPACE TSCREDITDB_NEW;' col1 
FROM dba_tab_partitions a 
WHERE a.table_owner='CREDITDB' AND a.tablespace_name = 'TSCREDITDB' 
UNION
SELECT 'ALTER TABLE '||a.TABLE_OWNER||'.'||a.TABLE_NAME||' MOVE SUBPARTITION '||a.SUBPARTITION_NAME||' TABLESPACE TSCREDITDB_NEW;' col1 
FROM dba_tab_SUBpartitions a 
WHERE a.table_owner='CREDITDB' AND a.tablespace_name = 'TSCREDITDB' 

UNION

SELECT 'ALTER INDEX '||a.OWNER||'.'||a.INDEX_NAME||' REBUILD TABLESPACE TSCREDITDB_NEW;' col1 
FROM dba_indexes a 
WHERE a.owner='CREDITDB' AND a.tablespace_name = 'TSCREDITDB' 
UNION  
SELECT 'ALTER INDEX '||a.INDEX_OWNER||'.'||a.INDEX_NAME||' REBUILD PARTITION '||a.PARTITION_NAME||'  TABLESPACE TSCREDITDB_NEW;' col1 
FROM dba_ind_partitions a, dba_indexes b 
WHERE b.table_owner='CREDITDB' 
AND a.INDEX_NAME=b.INDEX_NAME AND a.tablespace_name = 'TSCREDITDB' 
union
SELECT 'ALTER INDEX '||a.INDEX_OWNER||'.'||a.INDEX_NAME||' REBUILD SUBPARTITION '||a.SUBPARTITION_NAME||'  TABLESPACE TSCREDITDB_NEW;' col1 
FROM dba_ind_SUBpartitions a, dba_indexes b 
WHERE b.table_owner='CREDITDB' 
AND a.INDEX_NAME=b.INDEX_NAME AND a.tablespace_name = 'TSCREDITDB' 


--LOB
select 'alter table '||owner||'.'||table_name ||' move lob (' ||column_name||')' ||
' store as (tablespace TSCREDITDB_NEW);' from dba_lobs where segment_name in (select segment_name from dba_segments where tablespace_name='TSCREDITDB' and segment_type in ( 'LOBSEGMENT','LOBINDEX','LOB PARTITION'));



-- slow non-blocking online move 
SELECT 'ALTER TABLE '||a.OWNER||'.'||a.TABLE_NAME||' MOVE ONLINE TABLESPACE CREDITDB_NEW;' col1 
FROM dba_tables a 
WHERE a.owner='FRAUDSTAR' AND a.tablespace_name = 'CREDITDB'
UNION  
SELECT 'ALTER TABLE '||a.TABLE_OWNER||'.'||a.TABLE_NAME||' MOVE ONLINE PARTITION '||a.PARTITION_NAME||' TABLESPACE CREDITDB_NEW;' col1 
FROM dba_tab_partitions a 
WHERE a.table_owner='FRAUDSTAR' AND a.tablespace_name = 'CREDITDB' 
UNION
SELECT 'ALTER INDEX '||a.OWNER||'.'||a.INDEX_NAME||' REBUILD ONLINE TABLESPACE CREDITDB_NEW;' col1 
FROM dba_indexes a 
WHERE a.owner='FRAUDSTAR' AND a.tablespace_name = 'CREDITDB' 
UNION  
SELECT 'ALTER INDEX '||a.INDEX_OWNER||'.'||a.INDEX_NAME||' REBUILD ONLINE PARTITION '||a.PARTITION_NAME||'  TABLESPACE CREDITDB_NEW;' col1 
FROM dba_ind_partitions a, dba_indexes b 
WHERE b.table_owner='FRAUDSTAR' 
AND a.INDEX_NAME=b.INDEX_NAME AND a.tablespace_name = 'CREDITDB' 



SELECT a.owner, a.table_name, a.tablespace_name FROM dba_tables a WHERE a.tablespace_name = 'SYSTEM' AND a.owner ='SMODEL'  


select * from dba_segments where tablespace_name='FS_AUTH' 