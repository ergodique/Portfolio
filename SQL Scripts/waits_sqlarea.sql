select trunc(sa.elapsed_time/sa.executions)/1000 average_time_msec,sa.EXECUTIONS,sa.ELAPSED_TIME,
(sa.user_io_wait_time+sa.CLUSTER_WAIT_TIME+sa.APPLICATION_WAIT_TIME+sa.CONCURRENCY_WAIT_TIME) total_waits ,sa.user_io_wait_time,sa.CLUSTER_WAIT_TIME,sa.APPLICATION_WAIT_TIME,sa.CONCURRENCY_WAIT_TIME,sa.CPU_TIME 
,sa.SQL_FULLTEXT
from gv$sql sa 
where sa.PARSING_SCHEMA_NAME = 'USRKYP'
and sa.executions > 0
and trunc(sa.elapsed_time/sa.executions)/1000 > 5
order by sa.elapsed_time/sa.executions desc