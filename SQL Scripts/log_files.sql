select * from dba_data_files 
where file_name like '/ocfs/db001/RACTS/redo%'

-- redo log files and status
SELECT * FROM v$logfile

-- redo log group info
SELECT * FROM v$log

-- list redolog group files and their status
SELECT a.*,b.status,b.bytes/(1024*1024) SIZE_MB,b.archived, b.first_time FROM gv$logfile a,gv$log b 
WHERE a.inst_id=b.inst_id and a.GROUP#=b.GROUP# --AND b.status<>'INACTIVE' 
ORDER BY b.first_time ASC


SELECT * FROM dba_objects WHERE object_name LIKE '%ARCHIVE%'

-- list archivelogs and sizes
SELECT NAME, FIRST_TIME, NEXT_TIME ,COMPLETION_TIME , (SUM(BLOCKS*BLOCK_SIZE))/(1024*1024) arch_size_MB FROM v$archived_log a 
WHERE first_time>SYSDATE-1
GROUP BY NAME, FIRST_TIME,NEXT_TIME ,COMPLETION_TIME

-- list archive log sizes group by days
select inst_id,trunc(first_time) ARC_STIME,count(*) sayi,SUM((BLOCKS*BLOCK_SIZE)/(1024*1024*1024)) arch_size_GB
FROM gv$archived_log
group by inst_id,trunc(first_time)
order by trunc(first_time) asc,inst_id asc

select trunc(first_time) ARC_STIME,count(*) sayi,SUM((BLOCKS*BLOCK_SIZE)/(1024*1024*1024)) arch_size_GB
FROM gv$archived_log
group by trunc(first_time)
order by 3 desc

SELECT * FROM (SELECT TO_CHAR(FIRST_TIME,'YYYYMMDD' ) time_range, COUNT(*) sayi, (SUM(BLOCKS*BLOCK_SIZE))/(1024*1024*1024) arch_size_GB FROM v$archived_log
WHERE first_time > SYSDATE-90
GROUP BY TO_CHAR(FIRST_TIME,'YYYYMMDD' )) a WHERE a.arch_size_GB>50 

-- log_archive_dest_n parameters
SELECT * FROM v$archive_dest
