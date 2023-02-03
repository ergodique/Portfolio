select * from dba_hist_sql_plan where sql_id = '3qkhb7p97nj8x'
order by 2 desc

select * from v$sql_plan where sql_id='3qkhb7p97nj8x'

select distinct plan_hash_value,timestamp from dba_hist_sql_plan where sql_id = '3qkhb7p97nj8x'
order by 2 desc

select distinct plan_hash_value from v$sql_plan where sql_id='3qkhb7p97nj8x'

select * from v$sql_plan where operation='TABLE ACCESS' and options='FULL'