ALTER SESSION SET CURRENT_SCHEMA = RMAN

 

SELECT *
FROM rman.rc_backup_piece
WHERE status != 'D'
and db_key=242347
and TAG='LEVEL0'
and rsr_KEY=668701

 


select * from rc_rman_status
where rsr_key=668701

 
select distinct object_type from rc_rman_status
where db_name='FRAUD'

 

select * from rc_rman_status
where db_name='RAC'
and   operation='BACKUP'
and status='COMPLETED'
 
select * from rc_rman_status r,
(select db_key,max(start_time) sonzaman from rc_rman_status
where 
        status='COMPLETED'
and   operation='BACKUP'
and   object_type='DB INCR'
group by db_key ) sonbackup
where r.DB_KEY=sonbackup.db_key
and   r.start_time=sonbackup.sonzaman
and r.object_type='DB INCR'


select distinct operation from rc_rman_status

select db_name,operation,start_time,end_time ,trunc((end_time-start_time)*24*60)"SURE(min)" from rc_rman_status 
where db_name='MILENAS'
and object_type='DB INCR'
and status = 'COMPLETED'
order by 3 desc



select TO_CHAR(sysdate,'HH24MI') from dual;

select db_name,object_type,end_time,status  from rc_rman_status where status = 'FAILED' and operation = 'BACKUP' and end_time > sysdate - 1 --and db_name = 'RAC' order by end_time desc 

select db_name,command_id "SON BACKUP" from rc_rman_status r,
(select db_key,max(start_time) sonzaman from rc_rman_status
where 
        status='COMPLETED'
and   operation='BACKUP'
and   object_type='DB INCR'
group by db_key ) sonbackup
where r.DB_KEY=sonbackup.db_key
and   r.start_time=sonbackup.sonzaman
and r.object_type='DB INCR'



select d.name,sum(p.bytes)/1000000 from rman.rc_backup_piece p , rman.rc_database d where d.DBID = p.DB_ID group by d.name order by 2 desc



select operation,start_time,end_time  from rc_rman_status 
where db_name='FRAUD'
and object_type='DB INCR'
and status = 'COMPLETED'
order by 3 desc