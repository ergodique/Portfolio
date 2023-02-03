

select c.tablespace_name,
	   a.file_name,
       round(a.bytes/1048576) Megs_Alloc,
       round(b.bytes/1048576) Megs_Free,
       round((a.bytes-b.bytes)/1048576) Megs_Used,
       round(b.bytes/a.bytes * 100) Pct_Free,
       round((a.bytes-b.bytes)/a.bytes * 100) Pct_Used
	   ,a.AUTOEXTENSIBLE
	   ,round(a.MAX_EXT_BYTES/(1024*1024)) Megs_Max 	   
from (select tablespace_name,
	 		 file_name,
             sum(a.bytes) bytes,
             min(a.bytes) minbytes,
             max(a.bytes) maxbytes,
			 a.maxbytes max_ext_bytes,
			 a.AUTOEXTENSIBLE
      from sys.dba_data_files a
      group by tablespace_name,file_name,a.maxbytes,a.AUTOEXTENSIBLE) a,
     (select a.tablespace_name,
	 		 a.file_name,
             nvl(sum(b.bytes),0) bytes
      from sys.dba_data_files a,
           sys.dba_free_space b
      where a.tablespace_name = b.tablespace_name (+)
        and a.file_id         = b.file_id (+)
      group by a.tablespace_name,a.file_name
	  ) b,
      sys.dba_tablespaces c
where a.tablespace_name = b.tablespace_name (+)
  and a.file_name = b.file_name (+)
  and a.tablespace_name = c.tablespace_name
--  and a.tablespace_name = 'TSKKITP'
order by pct_used desc;

