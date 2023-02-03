select s.BEGIN_INTERVAL_TIME, s.sql_id,s.EXECUTIONS,s.ELAPSED_TIME_PEX from isbdba.sql_stats_total s 
where s.DATABASE_NAME='RACPR' and s.USERNAME = 'USRKYP' and s.EXECUTIONS > 50000
and s.BEGIN_INTERVAL_TIME between to_Date ('24.08.2009','DD.MM.YYYY') and to_Date ('31.08.2009','DD.MM.YYYY')
order by 1;


select s.BEGIN_INTERVAL_TIME, s.sql_id,s.EXECUTIONS,s.ELAPSED_TIME_PEX from isbdba.sql_stats_total s 
where s.DATABASE_NAME='KYPPRD' and s.sql_id in (select distinct s.sql_id from isbdba.sql_stats_total s 
where s.DATABASE_NAME='RACPR' and s.USERNAME = 'USRKYP' and s.EXECUTIONS > 50000
and s.BEGIN_INTERVAL_TIME between to_Date ('24.08.2009','DD.MM.YYYY') and to_Date ('31.08.2009','DD.MM.YYYY')) and s.EXECUTIONS > 50000
order by 1;