select begin_interval_time,sql_id
,trunc(sum(cl_wait)) tot_cl_wait,round(sum(cl_wait)/sum(executions),2) pex_cl_wait
,trunc(sum(cc_wait)) tot_cc_wait,round(sum(cc_wait)/sum(executions),2) pex_cc_wait
,sum(executions) tot_exec 
from isbdba.sql_stats
where begin_interval_time>sysdate-20
and sql_id in ('3v08ayyux78j9','5t4rdzrm18v6a','bautu759ahjrq')
group by begin_interval_time,sql_id
order by 2,1;
