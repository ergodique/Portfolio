SELECT tablespace_name,COUNT(*) AS fragments,
SUM(bytes) AS total,
MAX(bytes) AS largest
FROM dba_free_space
GROUP BY tablespace_name order by FRAGMENTS DESC;


SELECT * FROM V$DATAFILE

Tablespace fragmentation bilgisi ve doluluk oranlarý:

select    a.TABLESPACE_NAME,
    trunc(a.BYTES/1024/1024/1024) Gbytes_used,
    trunc(b.BYTES/1024/1024/1024) Gbytes_free,
    b.largest,
    round(((a.BYTES-b.BYTES)/a.BYTES)*100,2) percent_used
from     
    (
        select     TABLESPACE_NAME,
            sum(BYTES) BYTES 
        from     dba_data_files 
        group     by TABLESPACE_NAME
    )
    a,
    (
        select     TABLESPACE_NAME,
                                               sum(BYTES) BYTES ,
                                               max(BYTES) largest 
                               from      dba_free_space 
                               group    by TABLESPACE_NAME
                )
                b
where a.TABLESPACE_NAME=b.TABLESPACE_NAME
order    by 3 desc
