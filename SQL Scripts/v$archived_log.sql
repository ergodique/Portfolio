select trunc(first_time),trunc(sum(blocks*block_size)/1024/1024/1024) GB
from (select distinct first_change#,first_time,blocks,block_size,completion_time
from v$archived_log) 
group by trunc(first_time) 
order by trunc(first_time) desc;
