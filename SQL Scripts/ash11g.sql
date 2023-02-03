select * from
(select  ash.sql_id,nvl(EN.WAIT_CLASS,'ON_CPU') class from gv$active_Session_history ash, v$event_name en
where ash.sample_time > sysdate - interval '60' second
and  ash.SQL_ID is not NULL  and en.event# (+)=ash.event#
UNION ALL
select ash.sql_id,'TOTAL' from gv$active_Session_history ash
where ash.sample_time > sysdate - interval '60' second
and ash.sql_id is not null
 ) pivot (count(*)   FOR class IN ('ON_CPU' ON_CPU,'Concurrency' Conc,'User I/O' "UI/O",'System I/O' "SI/O",'Administrative' Adm,'Other' Oth,
'Configuration' Conf ,'Scheduler' Sche,'Cluster' "CLST",'Application' App,'Queueing' Que,'Idle' Idle,'Network' Ntw,'Commit' Cmt ,'TOTAL' TOTAL))
order by  TOTAL desc;