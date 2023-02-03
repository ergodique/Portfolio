select 
vs.PARSING_SCHEMA_NAME,INST_ID,VS.SQL_ID,
trunc(vs.elapsed_time/vs.executions)/1000 msec,vs.executions,trunc(rows_processed/executions) rows_per_exec,rows_processed  , trunc(disk_reads/executions) dr_per_exec,vs.disk_reads, vs.buffer_gets,
vs.ELAPSED_TIME,VS.PLAN_HASH_VALUE , vs.module,vs.sql_FULLtext,vs.sql_text, vs.sharable_mem, vs.persistent_mem, vs.runtime_mem, 
vs.sorts,  vs.parse_calls, vs.users_opening, vs.loads, vs.first_load_time,vs.last_load_time, vs.command_type, OPTIMIZER_MODE 
 from gv$sql vs
where 
vs.PARSING_SCHEMA_NAME in  ('RAFW')
and (executions >= 100)
--and sql_id in ('0vnmdp46ntjj0') 
--and VS.FIRST_LOAD_TIME > '2012-06-05/10:00:00'
--and (InStr(Upper(vs.sql_FULLtext), 'EVENTRESPONSE')>0)
order by 
 msec desc 
 
/*execution sayýsýna göre*/ 
select 
au.USERNAME parseuser,
trunc(vs.elapsed_time/vs.executions)/1000 msec,
vs.executions,vs.ELAPSED_TIME,VS.SQL_ID,VS.PLAN_HASH_VALUE , vs.module,vs.sql_fulltext, vs.sharable_mem, vs.persistent_mem, vs.runtime_mem, 
vs.sorts,  vs.parse_calls, 
vs.buffer_gets, vs.disk_reads, vs.users_opening, vs.loads,
vs.first_load_time,vs.last_load_time, 
--to_char(to_date(vs.first_load_time,'YYYY-MM-DD/HH24:MI:SS'),'MM/DD  HH24:MI:SS') first_load_time, 
rawtohex(vs.address) address, vs.hash_value hash_value
, rows_processed 
, vs.command_type, vs.parsing_user_id 
, OPTIMIZER_MODE 
 from gv$sql vs, all_users au 
where (au.user_id(+)=vs.parsing_schema_id)
--and sql_id in ('fhbfxap5b5d47') --'6d4cyndyxktsq','az6m4c5ysvdwy')
and au.USERNAME = 'USRWEBSUBE'
and (executions >= 1)
/*and (InStr(Upper(vs.sql_FULLtext), 'SMODEL.CMN_ORGUNITIPDEFINITION_OUITP')>0)
/*and (InStr(Upper(vs.sql_FULLtext), 'SMODEL.TAX_POSTING_TXPTP')>0)
and (InStr(Upper(vs.sql_FULLtext), 'SMODEL.TAX_TRANSACTION_TRPTP')>0)
and (InStr(Upper(vs.sql_FULLtext), 'EXPLAIN')=0)*/
order by 
executions desc  
 
/* get all execution plans of an sql_id*/  
SELECT * FROM V$SQL_PLAN WHERE SQL_ID='6d4cyndyxktsq'
order by sql_id,plan_hash_value,id

/* get the specfic execution plan of an sql_id */
SELECT * FROM V$SQL_PLAN WHERE SQL_ID='7b5yzp7r7j5zg'
--and plan_hash_value=3929020206 
order by sql_id,plan_hash_value,id

/* get the specfic historic execution plan of an sql_id */
select * from dba_hist_sql_plan
where sql_id in ('1h9zcsvppb9da')
--and plan_hash_value=137592276 
order by sql_id,plan_hash_value,id

/* get execution plans of sql's dealing with specific objects*/
select * from dba_hist_sql_plan
where sql_id in (select distinct sql_id from
dba_hist_sql_plan where OBJECT_OWNER||'.'||OBJECT_NAME='SMODEL.CMN_ORGUNITIPDEFINITION_OUITP') 
order by sql_id,plan_hash_value,id

/* get the details of an sql_id from historic views*/ 
select sp.BEGIN_INTERVAL_TIME,sp.END_INTERVAL_TIME, s.ELAPSED_TIME_TOTAL,s.ELAPSED_TIME_DELTA,s.EXECUTIONS_DELTA,s.EXECUTIONS_TOTAL, s.* 
from dba_hist_sqlstat s,dba_hist_snapshot sp
where s.sql_id in ('6d4cyndyxktsq','az6m4c5ysvdwy','9fctfnwnrwnhx','91a7u7yhbfwbx','ahp7s7wf90ab0')
and s.INSTANCE_NUMBER= sp.INSTANCE_NUMBER
and s.SNAP_ID = sp.SNAP_ID
order by sp.BEGIN_INTERVAL_TIME asc


select ELAPSED_TIME_TOTAL,ELAPSED_TIME_DELTA,EXECUTIONS_DELTA,EXECUTIONS_TOTAL, s.* from dba_hist_sqlstat s
where sql_id in ('6d4cyndyxktsq','az6m4c5ysvdwy','9fctfnwnrwnhx','91a7u7yhbfwbx','ahp7s7wf90ab0')

select * from dba_users where user_id=204

select * from DBA_hist_sqltext vs
where (InStr(Upper(vs.sql_text), 'SMODEL.TAX_PERIOD_TPETK')>0)
and (InStr(Upper(vs.sql_text), 'SMODEL.TAX_POSTING_TXPTP')>0)
and (InStr(Upper(vs.sql_text), 'SMODEL.TAX_TRANSACTION_TRPTP')>0)
and (InStr(Upper(vs.sql_text), 'EXPLAIN')=0)

select * from dba_hist_snapshot where snap_id=18487

V$SQLAREA


select * from v$sql_plan
where sql_id='g6wtc92f0gjxf'
and plan_hash_value=1289833219


--summary
select 
au.USERNAME parseuser,
trunc(vs.elapsed_time/vs.executions)/1000 msec,
vs.executions,vs.ELAPSED_TIME,VS.SQL_ID,vs.module,vs.sql_fulltext, vs.sharable_mem, vs.persistent_mem, vs.runtime_mem, 
vs.sorts,  vs.parse_calls, 
vs.buffer_gets, vs.disk_reads, vs.users_opening, vs.loads,
vs.first_load_time,vs.last_load_time, 
 rows_processed 
 from gv$sql vs, all_users au 
where (au.user_id(+)=vs.parsing_schema_id)
--and sql_id in ('7b5yzp7r7j5zg') --'6d4cyndyxktsq','az6m4c5ysvdwy')
and au.USERNAME = 'SAFIR_FRONTEND'
and (executions >= 1)
and trunc(vs.elapsed_time/vs.executions)/1000 > 5000
/*and (InStr(Upper(vs.sql_FULLtext), 'SMODEL.TAX_PERIOD_TPETK')>0)
and (InStr(Upper(vs.sql_FULLtext), 'SMODEL.TAX_POSTING_TXPTP')>0)
and (InStr(Upper(vs.sql_FULLtext), 'SMODEL.TAX_TRANSACTION_TRPTP')>0)
and (InStr(Upper(vs.sql_FULLtext), 'EXPLAIN')=0)*/
order by 
 ELAPSED_TIME/executions desc 