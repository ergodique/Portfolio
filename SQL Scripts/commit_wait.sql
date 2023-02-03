select sample_id, sum( time_waited)  from V$ACTIVE_SESSION_HISTORY where wait_class = 'Commit'
group by sample_id
order by sample_id desc


select *  from V$ACTIVE_SESSION_HISTORY
order by 1 desc


select to_char(sample_time,'YYYYMMDD HH24:MI'), sum( time_waited)  from V$ACTIVE_SESSION_HISTORY where wait_class = 'Commit'
group by to_char(sample_time,'YYYYMMDD HH24:MI')
order by 1 desc