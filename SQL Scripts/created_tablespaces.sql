--select * from v$archived_log
--select * from v$archive_dest
--select * from v$database
--select * from dba_objects where OBJECT_TYPE IN ('VIEW','SYNONYM') and OBJECT_NAME like '%ARCHIVE%'
--select * from v$archive_dest_status
select b.name TableSpace, a.name DataFile, a.creation_time, a.create_bytes, a.bytes from v$datafile a, v$tablespace b where a.ts#=b.ts# and a.creation_time>sysdate-15 