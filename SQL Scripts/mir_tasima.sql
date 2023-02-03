create view smodel.ferhat9901 as select * from smodel.ACC_ACCOUNTHISTORY_ACHTP partition(P1999_01);

insert /*+ APPEND */ into smodel.ACC_ACCOUNTHISTORY_ACHTP select * from smodel.ferhat9901@RAC;

commit;




select 'create view '||table_owner||'.'||SUBSTR(table_name,1,25)||'_'||substr(partition_name,4,4)||' as select * from '||table_owner||'.'||table_name||' partition ('||partition_name||');' 
from dba_tab_partitions
where table_owner = 'CUST'; 

select 'drop view '||table_owner||'.'||SUBSTR(table_name,1,25)||'_'||substr(partition_name,4,4)||' ;' 
from dba_tab_partitions
where table_owner = 'CUST'; 



select 'insert /*+ APPEND */ into '||table_owner||'.'||table_name||' select * from '||table_owner||'.'||SUBSTR(table_name,1,25)||'_'||substr(partition_name,4,4)||'@RACPR; commit;' 
from dba_tab_partitions
where table_owner = 'CUST'
--and partition_name like '%0612%'
and table_name = 'BIR_CONSUMER_LOAN_TERM'
order by 1; 


select 'insert /*+ APPEND */ into '||owner||'.'||table_name||' select * from '||owner||'.'||table_name||'@RACPR; commit;' 
from dba_tables
where owner in ('CUST','APP','GNRC')
and partitioned = 'NO'
order by 1; 


select 'truncate table '||owner||'.'||table_name||' ;' 
from dba_tables
where owner in ('CUST','APP','GNRC')
and partitioned = 'NO'
order by 1; 


select 'revoke insert,update on '||owner||'.'||table_name||' from USROLAP;' 
from dba_tables
where owner in ('CUST','APP','GNRC')
order by 1; 



