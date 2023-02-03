select version_count,a.* from v$sqlarea a
order by 1 desc 

alter system flush shared_pool

select distinct sql_id from v$active_session_history where
sample_time BETWEEN TO_DATE('20070327210000','YYYYMMDDHH24MISS') AND TO_DATE('20070327212000','YYYYMMDDHH24MISS') 
and p1 = 3964130080
--and sql_id = 'fc3r4tryqc3m3'


select * from v$active_session_history where
sample_time BETWEEN TO_DATE('20070327212500','YYYYMMDDHH24MISS') AND TO_DATE('20070327214000','YYYYMMDDHH24MISS') 
and sql_id = 'fc3r4tryqc3m3'

and p1 = 3964130080

