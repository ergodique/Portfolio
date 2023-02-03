select distinct 
   u.username,
   u.osuser, 
   w.event, 
   w.p2text as reason, 
   ts.name as tablespace, 
   nvl(ddf.file_name, dtf.file_name)
from 
   gv$session_wait w, 
   gv$session u, 
   gv$tablespace ts
left outer join 
   dba_data_files ddf on ddf.tablespace_name = ts.name
left outer join 
   DBA_TEMP_FILES dtf on dtf.tablespace_name = ts.name
where u.sid = w.sid
and w.p2 = ts.TS#
and w.event = 'enq: SS - contention';

select INST_ID,sid,id1,id2,lmode,request from gv$lock where type='SS' and lmode !=0;

select * from v$session where sid = 1030;


select inst_id, tablespace_name, segment_file, total_blocks,
used_blocks, free_blocks, max_used_blocks, max_sort_blocks
from gv$sort_segment;

select inst_id, tablespace_name, blocks_cached, blocks_used
from gv$temp_extent_pool;

select inst_id,tablespace_name, blocks_used, blocks_free
from gv$temp_space_header;

select inst_id,free_requests,freed_extents
from gv$sort_segment;
