
REM  Filename:  SQLVersions9i.sql
REM
REM  Investigate versions of code in the Library Cache
REM  You can increase/decrease the number of versions to look for problems
REM
REM   runs on 8i and 9i/9.2 releases
REM
set pages 999
set lines 100
col sql_text for a30 word_wrapped head "SQL"
col version_count for 999,999 head "Versions"

spool codeversions.out

select sql_text, version_count
from v$sqlarea
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

col s_text format a55 word_wrapped head "Object in Memory"
col s_id head "SQL ID"
col VERSIONS_VARIANCE format 999,999,999 head "Variance"

select sql_id s_id, sql_text s_text, (SQLAREA_CNT-SHARED_CNT) VERSIONS_VARIANCE 
from (select a.sql_id, a.version_count SQLAREA_CNT, count(*) SHARED_CNT,
   sql_text
from v$sqlarea a, v$sql_shared_cursor c
where a.sql_id=c.sql_id
and a.version_count > 1
group by a.sql_id, a.version_count, sql_text) vers
/

spool off

/*---------------------------------------------------


SQL                                                            Versions
---------------------------------------------------- --------------
select                                                                     10
con#,obj#,rcon#,enabled,nvl(de
fer,0) from cdef$ where
robj#=:1

select                                                                       8
con#,type#,condlength,intcols,
robj#,rcon#,match#,refact,nvl(
enabled,0),rowid,cols,nvl(defe
r,0),mtime,nvl(spare1,0) from
cdef$ where obj#=:1

...

SQL ID        Object in Memory                                            Variance
------------- ------------------------------------------------------- ------------
52umjphjycvka select location_name, user#, user_context,                         0
              context_size, presentation,  version, status,
              any_context, context_type, qosflags, payload_callback,
              timeout, reg_id, reg_time, ntfn_grouping_class,
              ntfn_grouping_value,  ntfn_grouping_type,
              ntfn_grouping_start_time, ntfn_grouping_repeat_count
              from reg$ where subscription_name = :1 and  namespace =
              :2  order by location_name, user#, presentation,
              version

47a50dvdgnxc2 update sys.job$ set failures=0, this_date=null,                    1
              flag=:1, last_date=:2,  next_date = greatest(:3,
              sysdate),  total=total+(sysdate-nvl(this_date,sysdate))
              where job=:4

2xgubd6ayhyb1 select max(procedure#) from procedureplsql$ where                 -2
              obj#=:1

38pn2vmg711x1 SELECT INST_SCHEMA, INST_NAME, INST_MODE, INST_SUB_ID              1
              FROM WK$INST_LIST WHERE INST_ID = :B1

...

*/