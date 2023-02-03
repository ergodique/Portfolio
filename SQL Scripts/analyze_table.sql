SELECT  'ANALYZE TABLE '||a.TABLE_OWNER||'.'||a.TABLE_NAME||' PARTITION('||a.PARTITION_NAME||') COMPUTE STATISTICS;' FROM dba_tab_partitions a
WHERE a.table_owner='IMS_LOG_USER' AND a.table_name='IMSLOG_INP'

SELECT  'ANALYZE TABLE '||a.OWNER||'.'||a.TABLE_NAME||'  COMPUTE STATISTICS;' FROM dba_tables a
WHERE a.owner='IMS_LOG_USER' AND a.table_name='IMSLOG_INP'


SELECT * FROM dba_indexes WHERE status NOT IN ('USABLE','N/A','VALID')

SELECT * FROM fraudstar.fraudstartime ORDER BY startdate DESC

SELECT TO_CHAR(startdate,'YYYYMMDD HH24'),AVG(inserttime),AVG(COUNT)
FROM fraudstar.fraudstartime 
GROUP BY TO_CHAR(startdate,'YYYYMMDD HH24')


select * from dba_data_files where file_id in (52,65,66,70,67) 