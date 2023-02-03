select A.DB_NAME, max(A.START_TIME) from PERF.JOBMONITOR_STATS a where A.SUCCES_FAILURE ='SUCCESS' and A.JOB_TYPE = 'BACKUP_INC0' and a.db_name like '%PRD%'
group by a.db_name
order by 2 


select a.*, A.JOB_EXEC_TIME/3600 SURE from PERF.JOBMONITOR_STATS a where A.db_name in ('SAFIRPRD','ODAKPRD','OLPRD') and A.JOB_TYPE = 'BACKUP_INC0' and A.START_TIME > sysdate -7
order by A.START_TIME desc

select a.*, A.JOB_EXEC_TIME/3600 SURE from PERF.JOBMONITOR_STATS a where A.db_name in ('SAFIRPRD') and A.JOB_TYPE = 'BACKUP_INC0'  and A.SUCCES_FAILURE = 'SUCCESS'
order by A.START_TIME desc



select * from PERF.JOBMONITOR_STATS a where A.db_name in ('SAFIRPRD','ODAKPRD') and A.JOB_TYPE like 'BACKUP_%' and A.START_TIME > sysdate -2
order by A.START_TIME desc


select to_char(A.START_TIME,'YYYYMM'),count(*) from PERF.JOBMONITOR_STATS a where A.SUCCES_FAILURE ='SUCCESS' and A.JOB_TYPE like '%ARC%' and a.db_name like '%PRD%'
group by to_char(A.START_TIME,'YYYYMM')
order by 1 desc
