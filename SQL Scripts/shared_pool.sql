SELECT COMPONENT ,OPER_TYPE,FINAL_SIZE Final,to_char(start_time,'dd-mon hh24:mi:ss') STARTED FROM V$SGA_RESIZE_OPS 
where component='shared pool'
order by 4 desc;


select module,trunc(sum(sharable_mem)/1024) MEMORY_KB from v$sqlarea 
group by module 
order by 2 desc;

select PARSING_SCHEMA_NAME,trunc(sum(sharable_mem)/1024) MEMORY_KB from v$sqlarea 
group by PARSING_SCHEMA_NAME
order by 2 desc;


select * from sys.literalsql;

select pool,sum(bytes)/1024/1024 from v$sgastat 
group by pool;

select pool,name,trunc(bytes/1024/1024) MEMORY_MB from v$sgastat
order by 3 desc;

select * from v$db_object_cache

select 'You may need to increase the SHARED_POOL_RESERVED_SIZE' Description,
'Request Failures = '||REQUEST_FAILURES Logic
from v$shared_pool_reserved
where REQUEST_FAILURES > 0
and 0 != (
select to_number(VALUE) 
from v$parameter 
where NAME = 'shared_pool_reserved_size')
union
select 'You may be able to decrease the SHARED_POOL_RESERVED_SIZE' Description,
'Request Failures = '||REQUEST_FAILURES Logic
from v$shared_pool_reserved
where REQUEST_FAILURES < 5
and 0 != ( 
select to_number(VALUE) 
from v$parameter 
where NAME = 'shared_pool_reserved_size')

/*Shared pool memory usage*/ 
select OWNER,
NAME||' - '||TYPE object,
SHARABLE_MEM
from v$db_object_cache
where SHARABLE_MEM > 10000 
and type in ('PACKAGE','PACKAGE BODY','FUNCTION','PROCEDURE')
order by SHARABLE_MEM desc;

/* object loaded count*/
select OWNER,
NAME,TYPE,
LOADS
from v$db_object_cache
where LOADS > 3 
and type in ('PACKAGE','PACKAGE BODY','FUNCTION','PROCEDURE')
order by LOADS desc

/*number of executions*/
select OWNER,
NAME||' - '||TYPE object,
EXECUTIONS
from v$db_object_cache
where EXECUTIONS > 100 
and type in ('PACKAGE','PACKAGE BODY','FUNCTION','PROCEDURE')
order by EXECUTIONS desc

/*details*/
select OWNER,
NAME,
DB_LINK,
NAMESPACE,
TYPE,
SHARABLE_MEM,
LOADS,
EXECUTIONS,
LOCKS,
PINS
from v$db_object_cache
order by OWNER, NAME
 
/* Library cache statistics*/
select NAMESPACE,
GETS,
GETHITS,
round(GETHITRATIO*100,2) gethit_ratio,
PINS,
PINHITS,
round(PINHITRATIO*100,2) pinhit_ratio,
RELOADS,
INVALIDATIONS
from v$librarycache

/*pinned objects*/
select NAME,
TYPE,
KEPT
from v$db_object_cache
where KEPT = 'YES'

and name like '%DUAL%'
