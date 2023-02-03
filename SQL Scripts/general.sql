drop table dwh.bs1

select * from v$session where sid=273

select * from v$session_wait where sid=273 or sid in
 (  
select sid from v$px_session where qcsid=273
)
order by event desc

select * from v$px_session where qcsid=273
 
where sid in (select sid from v$session where osuser='bsalturk')

select * from V$SESSION WHERE SID=273

select * from v$session_longops where sid in (     
select sid from v$px_session where qcsid=273  
)
and sofar <>totalwork

alter table dwh.RTX_LT_DW parallel

select * from V$SESSION_WAIT 
where event ! ='SQL*Net message from client'
and event='SQL*Net more data from dblink'
order by event

select blocks from dba_tab_partitions where table_name='TRTX_TAG' AND table_OWNER='DWH'

select degree,table_name from dba_tables where --table_name like 'CADM_%' and 
owner='DWH'

select 'alter table dwh.'||table_name || ' parallel ;'  from dba_tables where table_name like 'CADM_%'
and owner='DWH'


commit

select * from v$resource_limit

select * from v$parameter where name like '%pga%'

alter system set parallel_execution_message_size=127384 scope=spfile

alter system set parallel_adaptive_multi_user=false;

alter system set pga_aggregate_target=27300M --scope=spfile



ALTER TABLESPACE TEMP2 ADD TEMPFILE '/f12/oradata/temp2731_12.dbf' SIZE 27348M AUTOEXTEND OFF;


select * from 
 dba_free_space where tablespace_name='TEMP'
 
 select * from dba_temp_files
 
 select * from v$tempstat

SELECT   b.tablespace, b.segtype,b.segfile#, b.segblk#, b.extents,b.blocks, a.sid, a.serial#,            
a.username, a.osuser, a.status  
FROM     v$session a,V$TEMPSEG_USAGE b  
WHERE    a.saddr = b.session_addr  
--and sid=273
and ( SID=273 or sid in (select  sid from v$px_session where qcsid=273) )
ORDER BY b.tablespace, b.segfile#, b.segblk#, b.blocks; 


select * from v$pgastat

select * from  V$SQL_WORKAREA_ACTIVE 
where sid in (
select sid from v$px_session where qcsid=273
)
order by work_area_size desc

select * from  v$pga_target_advice

select * from v$sga

select * from v$pgastat


select name, value from v$parameter          where name in ('sga_max_size', 'shared_pool_size', 'db_cache_size',          'large_pool_size','java_pool_size'); 

select * from dwh.rtx_transformed_bno_out

commit


select * from v$px_session

select sum(bytes) from 
 dba_free_space
where tablespace_name='TSSTAGE'


ant.trtx_tag

select * from dba_mviews




select * from trtx_tag

alter table dwh.trtx_tag truncate partition CADM_CALL_STATS_273040831


startup pfile='/u01/app/oracle/product/9.2/dbs/inittarget2.ora'



SELECT cache#, type, parameter                            FROM v$rowcache                               WHERE cache# = 5 




select (trunc(sysdate) - to_dcate('20040930','yyyymmdd') ) / 7 from dual

select * from v$sess_io

       
desc rtx_lt_dw



select * from v$session where sid=273


select * from v$px_session where sid=273

 -- Nekadar UNDO kullaniyor
 SELECT s.sid, s.serial#, s.username, s.program, 
  t.used_ublk, t.used_urec
 FROM v$session s, v$transaction t
 WHERE s.taddr = t.addr
 and ( sid=273 or sid in ( select sid from v$px_session where qcsid=273) )
 ORDER BY 5 desc, 6 desc, 1, 2, 3, 4;

 
 select * from v$process where spid=9277
 
 select * from dba_mview_logs
 
 select s.sid,p.*
from v$session s, v$process p
where s.paddr=p.addr
--and ( s.sid= or  s.sid in (select sid from v$px_session where qcsid=50) )
and p.spid=9277  --273486
--AND SID = 981 
--order by spid asc

select * from v$session_wait where wait_class <> 'Idle'

select * from v$parameter where name like '%job%'

alter system set job_queue_processes=8

select 'GRANT EXECUTE ON ' || OBJECT_NAME || ' TO OWF_MGR;'  from dba_objects where owner='SYS' and object_type='PACKAGE' 
and object_name like 'UTL%'



alter system dump datafile 1937 block 19141

alter system dump datafile 1932 block 23621

select * from kkpap_pruning 


select * from v$session_wait where sid in (select sid from v$session where user='EUL')
order by event 

select * from v$session where sid=273

alter system kill session '273,23363'

select * from v$parameter where name like '%pga%' 



