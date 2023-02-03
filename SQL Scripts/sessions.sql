
select username,machine,count(*) from gv$session
group by username,machine
order by 3 desc

select username,count(*) from gv$session
group by username
order by 2 desc

select username,machine,service_name,count(*) from gv$session
group by username,machine,service_name
order by 4 desc

select inst_id,username,service_name,count(*) from gv$session
group by inst_id,username,service_name
order by 4 desc

select distinct username,machine from gv$session
order by 1


select username,inst_id,status,count(*) from gv$session
where username in ('USRWEBSUBE')
group by username,inst_id,status
order by 4 desc

select username,inst_id,MACHINE,service_name,count(*) from gv$session
where username = 'USRWEBSUBE' --and WAit_class != 'Idle'
and service_name = 'SRV_JOURNAL_ODAKPRD'
group by username,inst_id,machine,service_name
order by 3;

select MACHINE,count(*) from gv$session
group by machine
order by 2 desc;

select inst_id,username,module,count(*) from gv$session
where username = 'ITCAM'
group by inst_id,username,module
order by 4 desc;

select inst_id,service_name,count(*) from gv$session
group by inst_id,service_name
order by 3 desc

select username,inst_id,service_name,count(*) from gv$session
--where service_name not like 'SYS$%'
group by username,inst_id,service_name
order by 4 desc



select distinct username,service_name,MACHINE from gv$session where username in ('COMMON','SECURE')
and service_name not in ('SRVODK')
order by 3




select * from v$sql where sql_id='89wvw3mz19hah' 

select 'ALTER SYSTEM KILL SESSION '''||sid||','||serial#||''' immediate ;' from gv$session
where USERNAME = 'USROCINT' -- and event  = 'direct path read'

select 'ALTER SYSTEM KILL SESSION '''||sid||','||serial#||''' immediate ;' from gv$session
where inst_id=1 and  service_name='SRVODK' --and status='INACTIVE'

select 'ALTER SYSTEM KILL SESSION '''||sid||','||serial#||''' immediate ;' from gv$session
where module='CrtServer.exe' and status='INACTIVE'

select 'ALTER SYSTEM KILL SESSION '''||sid||','||serial#||''' immediate ;' from gv$session
where USERNAME='USRCRM' and sql_id like '%9q79%'

select 'ALTER SYSTEM DISCONNECT SESSION '''||sid||','||serial#||''' immediate ;' from gv$session
where USERNAME in ('USRKYP','COMMON') and status = 'SNIPED' 

select 'ALTER SYSTEM DISCONNECT SESSION '''||sid||','||serial#||''' immediate ;' from gv$session
where service_name='SRVODK'

select 'ALTER SYSTEM DISCONNECT SESSION '''||sid||','||serial#||''' immediate ;' from gv$session
where status='SNIPED'

select 'ALTER SYSTEM DISCONNECT SESSION '''||sid||','||serial#||''' immediate ;' from gv$session
where machine like '%kaodkwas01%'

select 'ALTER SYSTEM DISCONNECT SESSION '''||sid||','||serial#||''' immediate ;' from gv$session
where program like '%rman%' --and status != 'ACTIVE'

--RAC
select 'ALTER SYSTEM KILL SESSION '''||sid||','||serial#||',@'||inst_id||''' immediate ;' from gv$session
where USERNAME = 'USROCINT' --and (machine like 'ISBANK\0%' or machine like 'ISBANK\T1%')

select 'ALTER SYSTEM KILL SESSION '''||sid||','||serial#||''' immediate ;' from v$session
where USERNAME = 'PDUSER' and sid in (SELECT  a.session_id
       FROM gv$active_session_history a
 WHERE
 a.event = 'latch: cache buffers chains'
 AND a.sample_time > SYSDATE - 15/1440)
 
 select 'ALTER SYSTEM KILL SESSION '''||sid||','||serial#||''' immediate ;' from v$session
where USERNAME = 'PDUSER' and sid in (SELECT  a.session_id
       FROM gv$active_session_history a
 WHERE
 a.wait_class = 'Concurrency'
 AND a.sample_time > SYSDATE - 15/1440)


 

select * from gv$session where failed_over='YES'

 
select inst_id,service_name,CLIENT_INFO,count(*) from gv$session
where service_name not like 'SYS$%'
and username='COMMON'
group by inst_id,service_name,client_info
order by 1


select to_char(c.TIMESTAMP,'YYYYMMDD HH24:MI'),c.username,count(*) from isbdba.session_count c
group by to_char(c.TIMESTAMP,'YYYYMMDD HH24:MI'),c.username
order by 1 desc


/*  profil limitine yaklaþan kullanýcýlar */
SELECT *
  FROM (  SELECT a.username,
                 COUNT (A.USERNAME) SESSCOUNT,
                 DECODE (
                    b.LIMIT,
                    'DEFAULT', (SELECT LIMIT
                                  FROM dba_profiles
                                 WHERE resource_name = 'SESSIONS_PER_USER'
                                       AND PROFILE = 'DEFAULT'),
                    b.LIMIT)
                    LIMIT
            FROM dba_users a,
                 dba_profiles b,
                 V$SESSION C,
                 v$parameter d
           WHERE     d.name = 'resource_limit'
                 AND d.VALUE = 'TRUE'
                 AND A.USERNAME = C.USERNAME
                 AND a.profile = b.profile
                 AND b.resource_name = 'SESSIONS_PER_USER'
                 AND b.LIMIT NOT IN ('UNLIMITED')
        GROUP BY a.username, b.LIMIT)
 WHERE SESSCOUNT > ( (LIMIT * 90) / 100);