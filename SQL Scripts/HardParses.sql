REM  hardparse.sql
set pages 10000
set lines 132
set long 500000000
set termout off
set trimout on
set trimspool on

col inst_id format 999 heading "Inst"
col hash_value heading "Hash"
col sql_fulltext format a40 word_wrapped heading "SQL"

spool literals.out
    
select inst_id,hash_value,SQL_FULLTEXT
from gv$sql
where executions=1
order by SQL_TEXT
/

spool off
set termout on
set trimout off
set trimspool off
