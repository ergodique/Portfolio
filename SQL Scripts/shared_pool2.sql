--generate sql to pin objects in the shared_pool which are not currently pinned.
select 'exec DBMS_SHARED_POOL.keep('||chr(39)||owner||'.'||NAME||chr(39)||','||chr(39)||'P'||chr(39)||');' as sql_to_run 
from  V$DB_OBJECT_CACHE where TYPE in ('PACKAGE','FUNCTION','PROCEDURE','PACKAGE BODY') and loads > 50 and kept='NO' and executions > 50;

 --show distribution of shared pool memory across different types of objects. 
--show if any of the objects have been pinned using the procedure DBMS_SHARED_POOL.KEEP().
select type,count(*),kept,round(SUM(sharable_mem)/1024,0) share_mem_kilo 
from V$DB_OBJECT_CACHE where sharable_mem != 0 GROUP BY type, kept order by 3,4;

 --find objects with large number of loads

SELECT owner,sharable_mem,kept,loads,name from V$DB_OBJECT_CACHE WHERE loads > 2 ORDER BY loads DESC; 

 --find objects using large amounts of memory. pin using DBMS_SHARED_POOL.KEEP( ).
SELECT owner,name,sharable_mem,kept FROM V$DB_OBJECT_CACHE 
WHERE sharable_mem > 102400 AND kept = 'NO' ORDER BY sharable_mem DESC;

 --sharable memory in shared pool consumed by the object
select OWNER,NAME,TYPE,SHARABLE_MEM from V$DB_OBJECT_CACHE where SHARABLE_MEM > 10000 
and type in ('PACKAGE','PACKAGE BODY','FUNCTION','PROCEDURE') order by SHARABLE_MEM desc;

 --determine which objects to pin execute when database is in steady state.

SELECT owner||'.'||name Oname,substr(type,1,12) "Type", sharable_mem "Size",executions,loads,
kept FROM V$DB_OBJECT_CACHE WHERE type in ('TRIGGER','PROCEDURE','PACKAGE BODY','PACKAGE')
AND executions > 0  ORDER BY executions desc,loads desc,  sharable_mem desc;

--list large, un-pinned objects.

select to_char(sharable_mem / 1024,'999999') sz_in_K, decode(kept, 'yes','yes  ','') keeped,
owner||','||name||lpad(' ',29 - (length(owner) + length(name))) || '(' ||type||')'name,
null extra, 0 iscur from v$db_object_cache v where sharable_mem > 1024 * 1000;

--list large, un-pinned procedures, packages, functions.
select owner,name,type,round(sum(sharable_mem/1024),1) sharable_mem_K from v$db_object_cache  where kept = 'NO'
and (type = 'PACKAGE' or type = 'FUNCTION' or type = 'PROCEDURE')
group by owner,name,type order by 4;
