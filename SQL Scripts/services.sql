select service_name,inst_id,count(*) from gv$session
group by service_name , inst_id
order by 1 