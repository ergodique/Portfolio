
REM  Filename:  SQLVersions10g.sql
REM
REM  V$SQLSTATS is new to 10g.
REM  You can increase/decrease the number of versions to 
REM  look for problems
REM

set pages 999

set lines 100
col sql_id for a15 head "ID"
col sql_text for a30 word_wrapped head "SQL"
col version_count for 999,999 head "Versions"

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

/*------------------------------------------------------

Sample Output:

ID                      SQL                                                                                                                                              Versions
-------------------- ----------------------------------------------------------------------------------------------------------------------- -------------
345fpazn7j3y7 SELECT SEVERITY_CODE, COLLECTION_TIMESTAMP, SEVERITY_GUID FROM               14
                          MGMT_SEVERITY, (SELECT MAX(COLLECTION_TIMESTAMP) AS MAX_TIMESTAMP
                          FROM MGMT_SEVERITY WHERE TARGET_GUID = :B5 AND METRIC_GUID = :B4
                         AND KEY_VALUE = :B3 AND COLLECTION_TIMESTAMP > :B2 AND
                         SEVERITY_CODE != :B1 ) TS WHERE TARGET_GUID = :B5 AND METRIC_GUID
                         = :B4 AND KEY_VALUE = :B3 AND COLLECTION_TIMESTAMP =
                         MAX_TIMESTAMP ORDER BY LOAD_TIMESTAMP DESC ,
                         DECODE(SEVERITY_CODE, :B10 , 1, :B9 , 2, :B8 , 3, :B7 , 4, :B6 ,
                         5, 9)

14566d856s6hs SELECT owner# FROM sys.wri$_adv_tasks WHERE id = :1                                                    13
31a13pnjps7j3 SELECT source,        (case when time_secs < 1 then 1 else                                                           8
                           time_secs end) as time_secs,        operation FROM   ( SELECT  1
                           as source,                 trunc((sysdate - cast(ll.log_date as
                           date)) * 86400)                   as time_secs,
                           decode(ll.operation,                        'OPEN',  0
                           ,  1 ) as operation,                 ll.log_id as log_id
                           FROM  DBA_SCHEDULER_WINDOW_LOG ll ,                 ( SELECT
                           max(l.log_id) as max_log_id                   FROM
                           DBA_SCHEDULER_WINDOW_LOG l ,
                           DBA_SCHEDULER_WINGROUP_MEMBERS m                   WHERE
                           l.window_name = m.window_name                     AND
                          m.window_group_name = 'MAINTENANCE_WINDOW_GROUP'
                          AND  l.operation in ('OPEN', 'CLOSE')                     AND
                          CAST(l.log_date AS DATE) <                          (SELECT
                          cast(s1.end_interval_time as date)                           FROM
                          WRM$_SNAPSHOT s1                           WHERE  s1.dbid = :dbid
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