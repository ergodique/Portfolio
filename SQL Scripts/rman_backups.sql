select db_name,object_type,end_time,status
from rman.rc_rman_status
where status in  ('FAILED','COMPLETED WITH ERRORS','RUNNING WITH ERRORS','COMPLETED WITH WARNINGS')
and operation = 'BACKUP'
and end_time > sysdate -1
order by start_time desc;


select step_name,start_time,end_time from sysman.mgmt_job_history
where step_name like  'BACKUP%'
and end_time > sysdate -1
and step_status_code =255
order by end_time desc;

select db_name,end_time, status
from rman.rc_rman_status
where status='COMPLETED' 
and end_time is not null
and operation='BACKUP'
order by end_time desc

select db_name,max(end_time),status from rman.rc_rman_backup_job_details
where end_time is not null
and db_name in (select distinct target_name from sysman.mgmt_targets mt where mt.target_type in ( 'oracle_database','rac_database'))
and status = 'COMPLETED'
and input_type in ('DB FULL','DB INCR')
having max(end_time) < sysdate -7
group by db_name,status
order by 2;

select distinct target_name from sysman.mgmt_targets mt where mt.target_type in ( 'oracle_database','rac_database')
