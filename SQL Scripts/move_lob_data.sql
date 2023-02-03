ALTER TABLE coresrv.printing_transformer MOVE LOB(xslt) STORE AS (TABLESPACE TSCORESRVPRINT);

select 'alter table '||a.owner||'.'||a.table_name||' MOVE LOB('||b.column_name||') STORE AS (TABLESPACE TSCORESRVPRINT);' 
from dba_tables a , dba_tab_columns b where A.OWNER = b.owner and A.TABLE_NAME = b.table_name and A.OWNER = 'CORESRV' and a.table_name='PRINTING_RECOVERY'
and b.data_type like '%LOB%'


select * from dba_tab_columns where owner = 'CORESRV' and table_name = 'PRINTING_RECOVERY' and data_type like '%LOB%'

select 'alter table '||owner||'.'||table_name ||' move lob (' ||column_name||')' ||
'store as (tablespace DATA02);' from dba_lobs where segment_name in (select segment_name from dba_segments where tablespace_name='USERS' and owner='ARJU' and segment_type='LOBSEGMENT');


select 'alter table coresrv.'||table_name||' move tablespace  TSCORESRVPRINT ;' from dba_tables where table_name like 'PRINT%'