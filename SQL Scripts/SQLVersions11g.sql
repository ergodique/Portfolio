REM  V$SQLSTATS is new to 10g.
REM  You can increase/decrease the number of versions to look for problems
REM
set pages 999
set lines 100
col sql_id for a15 head "SQL ID"
col sql_text for a30 word_wrapped head "SQL"
col version_count for 999,999

spool codeversions.out

select sql_id, sql_text, version_count
from v$sqlstats
where version_count > 5
order by version_count desc
/

REM  
REM   This is a "checksum" type script.  Focusing on versions
REM   or copies of objects in the Library Cache--
REM   What kind of variances do you see between 
REM   V$SQLAREA and V$SQL_SHARED_CURSOR?  
REM     > 0 More versions tracked in V$SQLAREA
REM     < 0 More versions tracked in V$SQL_SHARED_CURSOR
REM

prompt ***Watch for***
PROMPT Variance > 0 means more versions tracked in V$SQLAREA
prompt Variance < 0 means more versions tracked in V$SQL_SHARED_CURSOR


col s_text format a55 word_wrapped head "Object in Memory"
col s_id head "SQL ID"
col VERSIONS_VARIANCE format 999,999,999 head "Variance"

select sql_id s_id, sql_text s_text, (SQLAREA_CNT-SHARED_CNT) VERSIONS_VARIANCE 
from (select a.sql_id, a.version_count SQLAREA_CNT, count(*) SHARED_CNT,
   sql_text
from v$sqlarea a, v$sql_shared_cursor c
where a.sql_id=c.sql_id
and a.version_count > 8
group by a.sql_id, a.version_count, sql_text) vers
/

spool off