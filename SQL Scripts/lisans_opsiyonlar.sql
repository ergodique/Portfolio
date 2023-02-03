Select parameter name, value
from v$option ;

select * from v$license;

Select 
decode(detected_usages,0,2,1) nop,
       name, version, detected_usages, currently_used,
       to_char(first_usage_date,'DD/MM/YYYY') first_usage_date, 
       to_char(last_usage_date,'DD/MM/YYYY') last_usage_date
from dba_feature_usage_statistics
order by 1, 2;


