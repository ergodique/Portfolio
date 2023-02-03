set lines 140
set pages 999

col shared_pool_size_for_estimate format 999,999,999,999 head "Shared Pool Size (MB)"
col shared_pool_size_factor head "Size Factor"
col estd_lc_memory_object_hits format 999,999,999,999 head "Estimated Hits in Library Cache"
col estd_lc_size format 999,999,999,999 head "Estimate of LC Size"
col estd_lc_memory_objects format 999,999,999,999 head "Estimate of objects in LC"

spool pooldata.out

select 
shared_pool_size_for_estimate, 
shared_pool_size_factor,
estd_lc_memory_object_hits,
estd_lc_size, estd_lc_memory_objects
from v$shared_pool_advice
order by shared_pool_size_factor
/

spool off

