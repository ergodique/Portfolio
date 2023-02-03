select './exch_drop_partition.sh  '||a.schema|| ' ' || a.tablename  ||' '|| b.partition_name
        from isbdba.arch_list a,
        (select x.table_owner table_owner,x.table_name  table_name, x.partition_name partition_name  ,
                isbdba.long_help.substr_of
                 ( 'select high_value
                        from dba_tab_partitions
                                where table_owner = :o and  table_name = :n  and partition_name = :p',
                                        1, 4000,  'o', table_owner,   'n', table_name,  'p', partition_name ) high_value
                from dba_tab_partitions x  ,isbdba.arch_list y where y.tablename=x.table_name and  x.table_owner=y.schema
                order by 2,3 ) b
                where   b.table_name=a.tablename and b.high_value <= to_char(sysdate-a.DATE_TABLE_OLTP,'YYYYMMDD') and a.tablename='AUTH_ISS_DECLINED' and a.schema= 'CARD';