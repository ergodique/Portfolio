
SELECT l.*,o.*,s.* FROM v$locked_object l, dba_objects o,v$session s WHERE l.object_id=o.object_id AND l.session_id = s.SID

SELECT * FROM v$lock

SELECT s.username,s.osuser,s.SID,s.serial#,s.machine,o.owner,o.object_name,o.object_type, l.locked_mode
FROM v$locked_object l, dba_objects o,v$session s 
WHERE l.object_id=o.object_id AND l.session_id = s.SID
and s.sid=137
--AND s.username = 'OZLRAC'

SELECT * FROM v$session WHERE SID=327

SELECT * FROM v$px_session

SELECT 'TABLE' TYPE, a.DEGREE,a.OWNER ,a.table_name , 'N/A' index_name FROM dba_tables a WHERE a.DEGREE > TO_CHAR(1)
UNION ALL 
SELECT 'INDEX' TYPE, a.DEGREE, a.table_owner owner, a.table_name, a.index_name FROM dba_indexes a WHERE a.DEGREE>TO_CHAR(1)