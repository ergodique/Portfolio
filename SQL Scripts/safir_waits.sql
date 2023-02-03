select 
au.USERNAME parseuser,
vs.PARSING_SCHEMA_ID SCHEMA_ID,vs.PARSING_USER_ID USER_ID,
vs.executions,vs.ELAPSED_TIME/:TIME_FACTOR ELAPSED_TIME, round((vs.ELAPSED_TIME/vs.executions/:TIME_FACTOR),2) ET_PEX,
VS.SQL_ID,VS.PLAN_HASH_VALUE , vs.module,vs.sql_text, vs.sharable_mem, vs.persistent_mem, vs.runtime_mem, 
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
--and vs.PARSING_SCHEMA_NAME='USRODAKSK'
--and vs.PARSING_SCHEMA_NAME like 'SAFI%'
--and sql_id in ('3v08ayyux78j9','1adzzcqrhm84s')
--and plan_hash_value in (3025088192)
and vs.MODULE  not in ('w3wp.exe') 
and au.USERNAME not in ('SYS','SYSTEM','DBSNMP','PRJSFRUSR')
and au.USERNAME not like ('IS%')
--and vs.PARSING_SCHEMA_NAME in ('USRBOMTAKIP')
and (executions > 1000)
--and last_load_time > sysdate-15/1440
--and (InStr(Upper(vs.sql_FULLtext), 'KYP_CBTEEXPOSURECENTRAL')>0)
/*
and (InStr(Upper(vs.sql_FULLtext), 'SMODEL.TAX_POSTING_TXPTP')>0)
and (InStr(Upper(vs.sql_FULLtext), 'SMODEL.TAX_TRANSACTION_TRPTP')>0)
and (InStr(Upper(vs.sql_FULLtext), 'EXPLAIN')=0)*/
order by 
 ELAPSED_TIME/executions desc;


select 
au.USERNAME parseuser,
vs.executions,vs.ELAPSED_TIME/:TIME_FACTOR ELAPSED_TIME, round((vs.ELAPSED_TIME/vs.executions/:TIME_FACTOR),2) ET_PEX
,VS.SQL_ID,VS.PLAN_HASH_VALUE 
, round((vs.APPLICATION_WAIT_TIME/vs.executions/:TIME_FACTOR),2) AP_PEX
, round((vs.CLUSTER_WAIT_TIME/vs.executions/:TIME_FACTOR),2) CL_PEX
, round((vs.CONCURRENCY_WAIT_TIME/vs.executions/:TIME_FACTOR),2) CC_PEX
--, round((vs.CPU_TIME/vs.executions/:TIME_FACTOR),2) CPU_PEX
, round((vs.PLSQL_EXEC_TIME/vs.executions/:TIME_FACTOR),2) PLSQL_PEX
, round((vs.USER_IO_WAIT_TIME/vs.executions/:TIME_FACTOR),2) IO_PEX
, round((vs.JAVA_EXEC_TIME/vs.executions/:TIME_FACTOR),2) JAVA_PEX
, vs.module
,substr(vs.sql_text,1,40)||'.....'
 from gv$sql vs, all_users au 
where (au.user_id(+)=vs.parsing_schema_id)
--and vs.PARSING_SCHEMA_NAME='USRODAKSK'
--and vs.PARSING_SCHEMA_NAME like 'SAFI%'
--and sql_id in ('3v08ayyux78j9','1adzzcqrhm84s')
--and plan_hash_value in (3025088192)
--and vs.MODULE  not in ('w3wp.exe') 
and au.USERNAME not in ('SYS','SYSTEM','DBSNMP','PRJSFRUSR')
and au.USERNAME not like ('IS%')
--and vs.PARSING_SCHEMA_NAME in ('USRBOMTAKIP')
and (executions > 1000)
--and last_load_time > sysdate-15/1440
--and (InStr(Upper(vs.sql_FULLtext), 'KYP_CBTEEXPOSURECENTRAL')>0)
/*
and (InStr(Upper(vs.sql_FULLtext), 'SMODEL.TAX_POSTING_TXPTP')>0)
and (InStr(Upper(vs.sql_FULLtext), 'SMODEL.TAX_TRANSACTION_TRPTP')>0)
and (InStr(Upper(vs.sql_FULLtext), 'EXPLAIN')=0)*/
order by 
 ELAPSED_TIME/executions desc;


select begin_interval_time,sql_id
,trunc(sum(cl_wait)) tot_cl_wait,round(sum(cl_wait)/sum(executions),2) pex_cl_wait
,trunc(sum(cc_wait)) tot_cc_wait,round(sum(cc_wait)/sum(executions),2) pex_cc_wait
,trunc(sum(io_wait)) tot_io_wait,round(sum(io_wait)/sum(executions),2) pex_io_wait
,sum(executions) tot_exec 
from isbdba.sql_stats
where begin_interval_time>sysdate-20
and sql_id in ('3v08ayyux78j9','5t4rdzrm18v6a','bautu759ahjrq')
group by begin_interval_time,sql_id
order by 2,1;
