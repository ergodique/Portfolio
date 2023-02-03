select * from perf.list_history where db_name = 'DBCUSPFT' and typeofop =  'B' and starttime > sysdate -30 

select distinct db_name,starttime,llocation,sql_code from perf.list_history where typeofop = 'B' and db_name = 'DBDWH' and starttime > sysdate - 60 order by 2 desc