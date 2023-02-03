REM
REM
REM  GATHER PARAMETER SPECIFIC TO SHARED POOL / SGA TUNING
REM
REM  Run as "/ as sysdba"

set lines 120
set pages 999
clear col
set termout off
set trimout on
set trimspool on

col "Setting" format 999,999,999,999
col "MBytes" format 999,999
col lifetime format a40 heading "Database Started Last"
spool parameters.out

select to_char(startup_time, 'dd-Mon-yyyy hh24:mi:ss') Lifetime from v$instance;


select 'Shared Pool Size'||':  '||decode(value,null,-1,value) "Setting"
   ,(value/1024/1024) "MBytes"
from v$parameter where name='shared_pool_size'
union
select 'Shared Pool Reserved Area'||':  '||decode(value,null,-1,value) "Setting"
   ,(value/1024/1024) "MBytes"
from v$parameter where name='shared_pool_reserved_size'
union
select 'Log Buffer'||':  '||decode(value,null,-1,value) "Setting"
   ,(value/1024/1024) "MBytes"
from v$parameter where name='log_buffer'
union
select 'Streams Pool Size'||':  '||decode(value,null,-1,value) "Setting"
   ,(value/1024/1024) "MBytes"
from v$parameter where name='streams_pool_size'
union
select 'Buffer Cache'||':  '||decode(value,null,-1,value) "Setting" 
   ,(value/1024/1024) "MBytes"
from v$parameter where name='db_cache_size'
union
select 'Recycle Cache'||':  '|| decode(value, null,-1,value) "Setting" 
   ,(value/1024/1024) "MBytes"
from v$parameter where name='db_recycle_cache_size'
union
select 'Keep Cache'||':  '|| decode(value, null,-1,value) "Setting" 
   ,(value/1024/1024) "MBytes"
from v$parameter where name='db_keep_cache_size'
union
select '2K Cache'||':  '|| decode(value, null,-1,value) "Setting" 
   ,(value/1024/1024) "MBytes"
from v$parameter where name='db_2k_cache_size'
union
select '4K Cache'||':  '|| decode(value, null,-1,value) "Setting" 
   ,(value/1024/1024) "MBytes"
from v$parameter where name='db_4k_cache_size'
union
select '8K Cache'||':  '|| decode(value, null,-1,value) "Setting" 
   ,(value/1024/1024) "MBytes"
from v$parameter where name='db_8k_cache_size'
union
select '16K Cache'||':  '|| decode(value, null,-1,value) "Setting" 
   ,(value/1024/1024) "MBytes"
from v$parameter where name='db_16k_cache_size'
union
select '32K Cache'||':  '|| decode(value, null,-1,value) "Setting" 
   ,(value/1024/1024) "MBytes"
from v$parameter where name='db_32k_cache_size'
union
select 'Large Pool Size'||':  '||decode(value,null,-1,value) "Setting" 
   ,(value/1024/1024) "MBytes"
from v$parameter where name='large_pool_size'
union
select 'Java Pool Size'||':  '||decode(value,null,-1,value) "Setting" 
   ,(value/1024/1024) "MBytes"
from v$parameter where name='java_pool_size'
union
select 'SGA Max'||':  '|| decode(value, null,-1,value) "Setting" 
   ,(value/1024/1024) "MBytes"
from v$parameter where name='sga_max_size'
union
select 'SGA Target'||':  '|| decode(value, null,-1,value) "Setting" 
   ,(value/1024/1024) "MBytes"
from v$parameter where name='sga_target'
order by 1
/

col Setting format 999,999,99

select 'Session Cached Cursors'||':  '|| decode(value, null,-1,value) "Setting" 
from v$parameter where name='session_cached_cursors'
union
select 'Open Cursors'||':  '||decode(value,null,-1,value) "Setting" 
from v$parameter where name='open_cursors'
union
select 'Processes'||':  '||decode(value,null,-1,value) "Setting" 
from v$parameter where name='processes'
union
select 'Sessions'||':  '||decode(value,null,-1,value) "Setting" 
from v$parameter where name='sessions'
union
select 'DB Files'||':  '||decode(value,null,-1,value) "Setting" 
from v$parameter where name='db_files'
union
select 'Shared Server (MTS)'||':  '||decode(value,null,-1,value) "Setting" 
from v$parameter where name='shared_server'
order by 1
/


col Setting format a30

select 'Cursor Sharing'||':  '|| value "Setting" 
from v$parameter where name='cursor_sharing'
union
select 'Query Rewrite'||':  '||value "Setting" 
from v$parameter where name='query_rewrite_enabled'
union
select 'Statistics Level'||':  '||value "Setting" 
from v$parameter where name='statistics_level'
union
select 'Cache Advice'||':  '||value "Setting" 
from v$parameter where name='db_cache_advice'
union
select 'Compatible'||':  '||value "Setting" 
from v$parameter where name='compatible'
order by 1
/

col resource_name format a25 head "Resource"
col current_utilization format 999,999,999,999 head "Current"
col max_utilization format 999,999,999,999 head "HWM"
col intl format a15 head "Setting"

select resource_name, current_utilization, max_utilization, initial_allocation intl
from v$resource_limit
where resource_name in ('processes', 'sessions','enqueue_locks','enqueue_resources',
   'ges_procs','ges_ress','ges_locks','ges_cache_ress','ges_reg_msgs',
   'ges_big_msgs','ges_rsv_msgs','gcs_resources','dml_locks','max_shared_servers')
/

col Parameter format a35 wrap
col "Session Value" format a25 wrapped
col "Instance Value" format a25 wrapped

select  a.ksppinm  "Parameter",
             b.ksppstvl "Session Value",
             c.ksppstvl "Instance Value"
      from x$ksppi a, x$ksppcv b, x$ksppsv c
     where a.indx = b.indx and a.indx = c.indx
       and a.ksppinm in ('_kghdsidx_count','__shared_pool_size','__streams_pool_size',
         '__db_cache_size','__java_pool_size','__large_pool_size', '_PX_use_large_pool', 
         '_large_pool_min_alloc','_shared_pool_reserved_min','_shared_pool_reserved_min_alloc',
         '_shared_pool_reserved_pct','_4031_dump_bitvec','4031_dump_interval',
         '_4031_max_dumps','4031_sga_dump_interval','4031_sga_max_dumps', '_kill_java_threads_on_eoc',
         '_optim_peek_user_binds','_px_bind_peek_sharing','event','_kgl_heap_size',
         '_library_cache_advice','_io_shared_pool_size','_NUMA_pool_size')
order by 1;

spool off
clear col
set termout on
set trimout off
set trimspool off

/* -------------------------------------------------

Sample Output:

Setting                                                        MBytes
------------------------------------------------------ -----------
16K Cache:  0                                                       0
2K Cache:  0                                                         0
32K Cache:  0                                                       0
4K Cache:  0                                                         0
8K Cache:  0                                                         0
Buffer Cache:  0                                                    0
Java Pool Size:  0                                                 0
Keep Cache:  0                                                     0
Large Pool Size:  0                                               0
Log Buffer:  7024640                                            7
Recycle Cache:  0                                                 0
SGA Max:  734003200                                     700
SGA Target:  612368384                                 584
Shared Pool Size:  0                                              0
Streams Pool Size:  0                                            0

15 rows selected.


Setting
-----------------------------------------------------------------
DB Files:  200
Open Cursors:  300
Processes:  150
Session Cached Cursors:  25
Sessions:  170


Setting
------------------------------
Cache Advice:  ON
Compatible:  10.2.0.1.0
Cursor Sharing:  EXACT
Query Rewrite:  TRUE
Statistics Level:  TYPICAL
	

Resource                      Current           HWM Setting
------------------------- ---------------- ---------------- ---------------
processes                               25               26         150
sessions                                  29               30         170
enqueue_locks                       21               28       2300
enqueue_resources              21                21         968
ges_procs                                0                  0              0
ges_ress                                  0                  0              0
ges_locks                                0                  0               0
ges_cache_ress                     0                  0               0
ges_reg_msgs                        0                  0               0
ges_big_msgs                        0                  0               0
ges_rsv_msgs                        0                   0               0
gcs_resources                        0                  0                0
dml_locks                                0                  8           748
max_shared_servers             2                  2    UNLIMITED

14 rows selected.


Parameter                           Session Value             Instance Value
----------------------------------- ------------------------- -------------------------
_4031_dump_bitvec                      67194879              67194879
_4031_max_dumps                                3600                       3600
_PX_use_large_pool                          FALSE                   FALSE
__db_cache_size                        503316480            503316480
__java_pool_size                             4194304                4194304
__large_pool_size                           4194304                4194304
__shared_pool_size                      92274688             92274688
__streams_pool_size                                    0                             0
_kghdsidx_count                                            1                             1
_kgl_heap_size                                       1024                      1024
_large_pool_min_alloc                         16000                    16000
_library_cache_advice                          TRUE                     TRUE
_optim_peek_user_binds                     TRUE                     TRUE
_shared_pool_reserved_min_alloc      4400                       4400
_shared_pool_reserved_pct                        5                              5
event                               10235 trace name context  10235 trace name context
                                                   forever, level 65536      forever, level 65536


15 rows selected.

*/