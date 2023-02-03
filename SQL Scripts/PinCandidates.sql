
REM   Filename: PinCandidates.sql
REM
REM   This will show you candidate objects for pinning
REM  
REM   Note.61760.1 Using the Oracle DBMS_SHARED_POOL Package 
REM   Note.1012047.6 How To Pin Objects in Your Shared Pool 
REM   
REM   You can increase/decrease the 'sharable_mem > 1000' 
REM   and/or the 'executions > 10' to fit your environment
REM   
REM   runs on 8i/9i/9.2/10g
REM

set pages 999
set lines 120
col owner format a20 heading "Owner"
col name format a25 heading "Name"
col type format a25 heading "Type"
col sharable_mem format 999,999,999,999 heading "Memory Used"

spool newpins.out

select owner, name, type, sharable_mem
from v$db_object_cache
where sharable_mem > 1000 and executions > 10
and (type='PACKAGE' or type = 'PACKAGE BODY' or type='FUNCTION'
   or type = 'PROCEDURE') and kept= 'NO'
order by sharable_mem desc
/

REM
REM    Looking at the SQL code data about executions 
REM    and memory usage from two other perspectives as well.
REM    

col sql_fulltext format a40 word_wrapped heading "Code Loaded"
col sharable_mem format 999,999,999,999 heading "Memory Footprint"
col invalidations format 999,999,999 heading "Invalidations"
col loads format 999,999,999 heading "Loads"
col executions format 999,999,999,999 heading "Executions"

select sql_fulltext, sharable_mem, invalidations, loads, executions 
from v$sql
where loads > invalidations
and executions > 1000
order by sharable_mem desc
/

select sql_fulltext, sharable_mem, invalidations, loads 
from v$sql
where loads > invalidations
and sharable_mem > 190000
order by loads desc
/

spool off


/*---------------------------------------------------------------------

Sample Output:

Owner                  Name         Type           Memory Used
----- --------------------- ------------ ---------------------
SYS             DBMS_OUTPUT      PACKAGE                13,091
SYS   DBMS_APPLICATION_INFO      PACKAGE                12,369
SYS             DBMS_OUTPUT PACKAGE BODY                 6,219

*/