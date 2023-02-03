set numwidth 15
column type format a20 truncate
column item format a25 truncate
column units format a10 truncate
column name format a30 truncate


select to_char(start_time,'dd-mon-yyyy HH:MI:SS') start_time,
       type, item, units, sofar, total, to_char(timestamp,'dd-mon-yyyy HH:MI:SS') timestamp
  from v$recovery_progress;