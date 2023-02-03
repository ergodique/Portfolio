SELECT PARSING_SCHEMA_NAME,SQL_FULLTEXT  FROM v$sql
WHERE 1=1
AND PARSING_SCHEMA_NAME ='KKM_USER'
--AND LOWER(SQL_FULLTEXT) LIKE '%rownum%'


/* Formatted on 2005/04/26 09:37 (Formatter Plus v4.8.5) */
SELECT u.NAME username, s.sql_text 
  FROM v$sqlarea s, SYS.USER$ u
 WHERE s.parsing_user_id = u.USER# AND u.NAME = 'KKM_USER' 
 --AND UPPER(s.SQL_TEXT) LIKE '%INTRF%'

 
 /* Formatted on 2005/04/26 09:37 (Formatter Plus v4.8.5) */
 -- v$session ile de dba_hist_active_sess_history ile de sql_id kolonlarý üzerinden join yapýlýyor
SELECT u.NAME username, s.sql_text, vs.*
  FROM v$sqlarea s, SYS.USER$ u, 
  --v$session vs 
  dba_hist_active_sess_history vs 
 WHERE s.parsing_user_id = u.USER# AND u.NAME = 'KKM_USER' 
AND s.sql_id = vs.sql_id
--AND UPPER(vs.program) LIKE 'TOAD%'
--AND UPPER(s.SQL_TEXT) LIKE '%COUNT%'
 
 SELECT * FROM v$sqltext WHERE
 address ='7B643C28'
 ORDER BY piece ASC 
 --upper(sql_text) like '%INTRF%' 

--SELECT p_user.*, p_schema.*
--  FROM (SELECT s.sql_id, u.NAME parsing_user
--          FROM v$sqlarea s, SYS.user$ u
--         WHERE s.parsing_user_id = u.user# AND u.user# != 0) p_user,
--       (SELECT s.sql_id, u.NAME parsing_schema, s.sql_text
--          FROM v$sqlarea s, SYS.user$ u
--         WHERE s.parsing_schema_id = u.user# AND u.user# != 0) p_schema
-- WHERE p_user.sql_id = p_schema.sql_id
--   AND p_user.parsing_user != p_schema.parsing_schema

/*actvie sqls and their associated session info*/
SELECT u.NAME username, s.sql_text, vs.*
  FROM v$sqlarea s, SYS.USER$ u, v$session vs --dba_hist_active_sess_history vs 
 WHERE s.parsing_user_id = u.USER# AND vs.status = 'ACTIVE'  
AND s.sql_id = vs.sql_id