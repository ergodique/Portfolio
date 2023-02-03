select * from v$datafile v where V.STATUS not in ('SYSTEM','ONLINE');

select * from v$recover_file;

select to_char(start_time,'dd-mon-yyyy HH:MI:SS') start_time,
       type, item, units, sofar, total, to_char(timestamp,'dd-mon-yyyy HH:MI:SS') timestamp
  from v$recovery_progress;
  
  
  restore archivelog sequence between 21839  and 21841;