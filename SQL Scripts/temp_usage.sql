SELECT s.sid "SID",s.username "User",s.program "Program", u.tablespace "Tablespace",
u.contents "Contents", u.extents "Extents", u.blocks*8/1024 "Used Space in MB", q.sql_text "SQL TEXT",
a.object "Object", k.bytes/1024/1024 "Temp File Size"
FROM v$session s, v$sort_usage u, v$access a, dba_temp_files k, v$sql q
WHERE s.saddr=u.session_addr
and s.sql_address=q.address
and s.sid=a.sid
and u.tablespace=k.tablespace_name;


SELECT s.sid "SID",s.username "User",u.tablespace "Tablespace",
 u.blocks*8/1024/1024 "Used Space in GB"
FROM v$session s, v$sort_usage u
WHERE s.saddr=u.session_addr
order by 4 desc;

select 'ALTER SYSTEM KILL SESSION '''||sid||','||serial#||''' immediate ;' 
FROM v$session s, v$sort_usage u
WHERE s.saddr=u.session_addr
and s.username='USRGKMRW' 
and u.blocks*8/1024/1024 > 1

