select sid,serial#,to_char(logon_time,'YYYYMMDD HH24MI') logon_ts, sql_text,blocking_session,blocking_session_status  from v$session a ,v$sqlarea b where 
--blocking_session_status='VALID'
--and program like 'sqlld%'
--username = 'PERFSTAT' 
a.SQL_HASH_VALUE =b.HASH_VALUE;


SELECT 
      a.session_id, 
      username, 
      type, 
      mode_held, 
      mode_requested,
      lock_id1, 
      lock_id2 
FROM
      sys.v_$session b, 
      sys.dba_blockers c, 
      sys.dba_lock a
WHERE
      c.holding_session=a.session_id and
      c.holding_session=b.sid