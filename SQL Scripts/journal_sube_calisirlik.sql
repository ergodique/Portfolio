select substr(jtime,1,5) saat,count(*) from websube.journal
where jopdate= '13:03:2012'
and jtime>'08:20:00'
and jtime<'11:20:00'
group by  substr(jtime,1,5) 
order by 1 desc;

