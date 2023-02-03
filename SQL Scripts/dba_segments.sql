select sum(bytes)/1024/1024/1024 GB from dba_segments;



select sum(bytes)/1024/1024/1024 GB from dba_segments
where owner in ('CREDITDB','CREDITLOG','STAGE');


select owner,trunc(sum(bytes)/1024/1024/1024) SIZE_GB from dba_segments
group by owner
having sum(bytes)/1024/1024/1024 > 1
order by 2 desc


select s.OWNER,s.SEGMENT_NAME,s.SEGMENT_TYPE,trunc(sum(bytes)/1024/1024/1024) SIZE_GB  from dba_segments s
group by s.owner,s.segment_name,s.segment_type
having sum(bytes)/1024/1024/1024 > 1
order by 4 desc


select s.OWNER,s.SEGMENT_NAME,s.partition_name,s.SEGMENT_TYPE,trunc(sum(bytes)/1024/1024/1024) SIZE_GB  from dba_segments s
group by s.owner,s.segment_name,s.partition_name,s.segment_type
having sum(bytes)/1024/1024/1024 > 1
order by 5 desc