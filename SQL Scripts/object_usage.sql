select a.owner , a.object_name,sum(b.bytes)/1024/1024/1024 GB from 
(select owner,object_name from dba_objects
where owner not in ('APP','CTXSYS','DBSNMP','SYS','SYSTEM','SYSMAN','XDB','WMSYS') and object_type = 'TABLE'
minus
(select object_owner,object_name from dba_hist_sql_plan where object_type = 'TABLE' and object_owner not in ('APP','CTXSYS','DBSNMP','SYS','SYSTEM','SYSMAN','XDB','WMSYS')
union
select object_owner,object_name from gv$sql_plan where object_type = 'TABLE' and object_owner not in ('APP','CTXSYS','DBSNMP','SYS','SYSTEM','SYSMAN','XDB','WMSYS')
group by object_owner,object_name
)) a ,dba_segments b
where a.owner=b.owner and a.object_name = b.segment_name
group by a.owner,a.object_name
order by 3 desc;


select owner,segment_name,sum(bytes)/1024/1024/1024 GB from dba_segments
group by owner,segment_name
order by 3 desc













