select S.PARSING_SCHEMA_NAME, S.SNAP_ID, s.sql_id, S.ELAPSED_TIME_DELTA, S.EXECUTIONS_DELTA, trunc(S.ELAPSED_TIME_DELTA/S.EXECUTIONS_DELTA)/1000 msec,S.DISK_READS_DELTA from dba_hist_sqlstat s 
where S.DISK_READS_DELTA > 10000 
and S.EXECUTIONS_DELTA >=10000
and  trunc(S.ELAPSED_TIME_DELTA/S.EXECUTIONS_DELTA)/1000 > 1000
order by 1 desc;

select * from v$sql where sql_id = 'g84w5uy482cc6';

--gunluk ortalama suresi
select
  to_char(s.begin_interval_time, 'YYYYMMDD'),
  sql.sql_id,
   avg(trunc(sql.ELAPSED_TIME_DELTA/sql.EXECUTIONS_DELTA)/1000) msec
 from
   dba_hist_sqlstat        sql,
   dba_hist_snapshot         s
where
   s.snap_id = sql.snap_id
   and sql.sql_id = 'g62r35nn7cann'
   and  SQL.EXECUTIONS_DELTA >=1
group by to_char(s.begin_interval_time, 'YYYYMMDD'),sql.sql_id
order by
   1 desc;
   
--saat araliklarinda kac kez calisti   
select
  to_char(s.begin_interval_time, 'YYYYMMDD HH24'),
  sql.sql_id,
   sum(sql.EXECUTIONS_DELTA) SAYI
 from
   dba_hist_sqlstat        sql,
   dba_hist_snapshot         s
where
   s.snap_id = sql.snap_id
   and sql.sql_id = 'g62r35nn7cann'
   and  SQL.EXECUTIONS_DELTA >=1
group by to_char(s.begin_interval_time, 'YYYYMMDD HH24'),sql.sql_id
order by
   1 desc
   

--gunde kac kez calisti
select
  to_char(s.begin_interval_time, 'YYYYMMDD'),
  sql.sql_id,
   sum(sql.EXECUTIONS_DELTA) SAYI
 from
   dba_hist_sqlstat        sql,
   dba_hist_snapshot         s
where
   s.snap_id = sql.snap_id
   and sql.sql_id = 'g62r35nn7cann'
   and  SQL.EXECUTIONS_DELTA >=1
group by to_char(s.begin_interval_time, 'YYYYMMDD'),sql.sql_id
order by
   1 desc
