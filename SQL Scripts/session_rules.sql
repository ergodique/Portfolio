select * from isbdba.session_rules_error_log where LOGON_TIME > sysdate -1
order by LOGON_TIME desc

select * from isbdba.session_rules_log where LOGON_TIME > sysdate -1
order by logon_time desc

select  program,a.* from v$session a where username = 'SAFIR_BATCH' and program = 'MRSScheduler.exe'