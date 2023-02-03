select * from dba_tab_partitions where TABLE_OWNER = 'FRAUDSTAR'

select 'expdp system/ims2004 DIRECTORY=EXPORT_DIR DUMPFILE='||table_name||'_'||partition_name||'.dmp TABLES=Fraudstar.'||table_name||':'||partition_name||' LOGFILE='||table_name||'.'||partition_name||'.log' 
from dba_tab_partitions where TABLE_OWNER = 'FRAUDSTAR'
order by 1 
