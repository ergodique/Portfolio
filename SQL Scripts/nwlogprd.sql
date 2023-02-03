select 'alter table '||table_owner||'.'||table_name||' truncate partition '||partition_name||';'
                from dba_tab_partitions where table_owner = 'NETDATA' and 
                to_date(substr(netdata.long_help.substr_of
                 ( 'select high_value
                        from dba_tab_partitions
                                where table_owner = :o and  table_name = :n  and partition_name = :p',
                                        1, 4000,  'o', table_owner,   'n', table_name,  'p', partition_name  ) ,10,11),'YYYY-MM-DD') < sysdate -31
                order by 1;
                
select table_owner,table_name,partition_name,to_date(substr(netdata.long_help.substr_of
                 ( 'select high_value
                        from dba_tab_partitions
                                where table_owner = :o and  table_name = :n  and partition_name = :p',
                                        1, 4000,  'o', table_owner,   'n', table_name,  'p', partition_name  ) ,10,11),'YYYY-MM-DD') high_value
                from dba_tab_partitions where table_owner = 'NETDATA' and 
                to_date(substr(netdata.long_help.substr_of
                 ( 'select high_value
                        from dba_tab_partitions
                                where table_owner = :o and  table_name = :n  and partition_name = :p',
                                        1, 4000,  'o', table_owner,   'n', table_name,  'p', partition_name  ) ,10,11),'YYYY-MM-DD') < sysdate -31
                order by 4;


select partition_name,high_value  from dba_tab_partitions where table_owner = 'NETDATA' --and  table_name = 'KDC_FWSM_LOG'
order by 1