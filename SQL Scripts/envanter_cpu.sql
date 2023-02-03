select max(tarih),e.dbname,e.cpu_count from perf.oracle_envanter e,perf.catalogue_rel r 
where cpu_count is not null
and e.DBNAME = r.DBNAME
and r.LEVEL_ID = 'PROD'
group by e.dbname,e.cpu_count
order by 2 ;

select max(tarih),e.dbname,e.cpu_count from perf.oracle_envanter e,perf.catalogue_rel r 
where cpu_count is not null
and e.DBNAME = r.DBNAME
and r.LEVEL_ID not in ( 'PROD')
group by e.dbname,e.cpu_count
order by 2 ;


select max(tarih),e.hostname,e.dbname,e.cpu_count,e.OS_version from perf.oracle_envanter e,perf.catalogue_rel r 
where cpu_count is not null
and e.DBNAME = r.DBNAME
and r.LEVEL_ID = 'PROD'
group by e.hostname,e.dbname,e.cpu_count,e.OS_version
order by 5 ;


select max(tarih),e.hostname,e.dbname,e.cpu_count,e.OS_version from perf.oracle_envanter e,perf.catalogue_rel r 
where cpu_count is not null
and e.DBNAME = r.DBNAME
and r.LEVEL_ID not in ( 'PROD')
group by e.hostname,e.dbname,e.cpu_count,e.OS_version
order by 5 ;

select max(tarih),e.hostname,e.cpu_count,e.OS_version from perf.oracle_envanter e,perf.catalogue_rel r 
where cpu_count is not null
and e.DBNAME = r.DBNAME
and r.LEVEL_ID = 'PROD'
group by e.hostname,e.cpu_count,e.OS_version
order by 4 ;


select max(tarih),e.hostname,e.cpu_count,e.OS_version from perf.oracle_envanter e,perf.catalogue_rel r 
where cpu_count is not null
and e.DBNAME = r.DBNAME
and r.LEVEL_ID not in ( 'PROD')
group by e.hostname,e.cpu_count,e.OS_version
order by 4 ;



select max(tarih),e.hostname,r.level_id,e.cpu_count,e.OS_version from perf.oracle_envanter e,perf.catalogue_rel r 
where cpu_count is not null
and e.DBNAME = r.DBNAME
group by e.hostname,r.level_id,e.cpu_count,e.OS_version
order by 3,5 ;

