
select * from dba_tables where monitoring = 'NO'

select * from dba_tab_statistics where owner in ('CREDITDB','CUST','GNRC') and stattype_locked is not null

select * from dba_tab_statistics where owner in ('CREDITDB','CUST','GNRC') and stale_stats = 'YES'

select * from dba_tab_statistics where stale_stats = 'YES' and owner not in ('SYS' )

select 'exec DBMS_STATS.UNLOCK_TABLE_STATS (ownname         => '''||owner||''',tabname         => '''||table_name||''');' 
from  dba_tab_statistics where owner in ('CREDITDB','CUST','GNRC') and stattype_locked is not null



CUST.KYP_CBTEEXPOSUREISBANK




