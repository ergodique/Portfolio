/* exec sayýsýnda artýþ olan sql_id ler */
select s1.*,s2.* from 
(select sql_id,sum(executions) exe from isbdba.sql_stats 
where begin_interval_time between trunc(sysdate-20) and trunc(sysdate-10) and username=:USR group by sql_id having sum(executions)> :exelim) s1,
(select sql_id,sum(executions) exe from isbdba.sql_stats 
where begin_interval_time between trunc(sysdate-10) and trunc(sysdate) and username=:USR group by sql_id having sum(executions)> :exelim) s2
where s1.sql_id=s2.sql_id
and s2.exe > (s1.exe)*1.5
order by s1.exe desc;

/* elapsed time artýþ olan sql_id ler */
select s1.*,s2.* from 
(select sql_id,sum(ELAPSED_TIME) exe from isbdba.sql_stats 
where begin_interval_time between trunc(sysdate-20) and trunc(sysdate-10) and username=:USR group by sql_id having sum(executions)> :exelim) s1,
(select sql_id,sum(ELAPSED_TIME) exe from isbdba.sql_stats 
where begin_interval_time between trunc(sysdate-10) and trunc(sysdate) and username=:USR group by sql_id having sum(executions)> :exelim) s2
where s1.sql_id=s2.sql_id
and s2.exe > (s1.exe)*1.5
order by s1.exe desc;

/* cc_wait time artýþ olan sql_id ler */
select s1.*,s2.* from 
(select sql_id,sum(CC_WAIT) exe from isbdba.sql_stats 
where begin_interval_time between trunc(sysdate-20) and trunc(sysdate-10) and username=:USR group by sql_id having sum(executions)> :exelim) s1,
(select sql_id,sum(CC_WAIT) exe from isbdba.sql_stats 
where begin_interval_time between trunc(sysdate-10) and trunc(sysdate) and username=:USR group by sql_id having sum(executions)> :exelim) s2
where s1.sql_id=s2.sql_id
and s2.exe > (s1.exe)*1.5
order by s1.exe desc;
