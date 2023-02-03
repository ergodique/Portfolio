select trunc(completion_time),round(sum(block_size*blocks)/1024/1024/1024,2) from v$archived_log
group by trunc(completion_time)
order by 1 desc

select avg(round(sum(block_size*blocks)/1024/1024/1024,2)) from v$archived_log
group by trunc(completion_time)

select  trunc(completion_time),  count (*) from v$archived_log
group by  trunc(completion_time)
order by 1 desc

