select table_name,OBJECT_TYPE,total_phys_io
    from ( select owner||'.'||object_name as table_name,OBJECT_TYPE,
                  sum(value) as total_phys_io, sum(value) as tot_log_io
           from   v$segment_statistics
           where  owner!='SYS' and object_type in ('TABLE','INDEX')
     and  statistic_name in ('physical reads','physical reads direct',
                           'physical writes','physical writes direct')
           group by owner||'.'||object_name,OBJECT_TYPE
           order by total_phys_io desc) 
  where rownum <=10;
