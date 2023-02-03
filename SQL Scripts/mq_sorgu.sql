select * from sims.mq_log_manager_stats
where sys_name='TESE' 
and qmgr='CSQ2' 
order by jdate desc;

select * from sims.mq_log_manager_stats
where sys_name='TESD' 
and qmgr='CSQ1' 
order by jdate desc;

select * from sims.mq_log_manager_stats_hist
where sys_name='TESD' 
and qmgr='CSQ1' 
and jdate > sysdate -25
order by jdate desc;

select * from sims.mq_log_manager_stats
where sys_name='SYSA' 
and qmgr='CSQ1' 
order by jdate desc;

select * from sims.mq_log_manager_stats_hist
where sys_name='SYSA' 
and qmgr='CSQ1' 
and jdate > sysdate -3
order by jdate desc;