select './exch_trunc_partition.sh  '||a.schema|| ' ' || a.tablename  ||' '|| b.partition_name
        from isbdba.arch_list a,
        (select x.table_owner table_owner,x.table_name  table_name, x.partition_name partition_name  ,
                isbdba.long_help.substr_of
                 ( 'select high_value
                        from dba_tab_partitions
                                where table_owner = :o and  table_name = :n  and partition_name = :p',
                                        1, 4000,  'o', table_owner,   'n', table_name,  'p', partition_name ) high_value
                from dba_tab_partitions x  ,isbdba.arch_list y where y.tablename=x.table_name and  x.table_owner=y.schema
                order by 2,3 ) b
                where   b.table_name=a.tablename and b.high_value <= to_char(sysdate-a.DATE_TABLE_OLTP,'YYYYMMDD') and a.tablename='MISP_TRNX_HISTORY' and a.schema= 'MISP'
                and b.table_name||b.partition_name not in (select tablename||partname from isbdba.arch_trunc_control where RC_TR =0 );
                
--ONLINE TABLO PARTITION DROP
select './exch_drop_partition.sh  '||a.schema|| ' ' || a.tablename  ||' '|| b.partition_name||' '||c.partition_name
        from isbdba.arch_list a,
        (select x.table_owner table_owner,x.table_name  table_name, x.partition_name partition_name  ,
                isbdba.long_help.substr_of 
                 ( 'select high_value 
                        from dba_tab_partitions
                                where table_owner = :o and  table_name = :n  and partition_name = :p',
                                        1, 4000,  'o', table_owner,   'n', table_name,  'p', partition_name ) high_value
                from dba_tab_partitions x  ,isbdba.arch_list y where y.tablename=x.table_name and  x.table_owner=y.schema
                order by 2,3 ) b, 
                (select x.table_owner table_owner,x.table_name  table_name, x.partition_name partition_name  
                from dba_tab_partitions x  ,isbdba.arch_list y where y.tablename||'_ARCH'=x.table_name and  x.table_owner='ARCHIVE'
                order by 2,3 ) c
                where   substr(c.partition_name,-8,8)=substr(b.partition_name,-8,8) AND c.table_name=a.tablename||'_ARCH' 
                AND b.table_name=a.tablename and b.high_value <= to_char(sysdate-a.DATE_TABLE_OLTP,'YYYYMMDD') and a.tablename='MRC_EOD_LOG' and a.schema= 'POSMRC';




--ARSIV TABLOSU EXPORT
select './archive_proc.sh ARCHIVE  ' || a.tablename  || '_ARCH ' || b.partition_name
  from isbdba.arch_list a,
        (select x.table_owner table_owner,x.table_name  table_name, x.partition_name partition_name  ,
                isbdba.long_help.substr_of
                 ( 'select high_value
                        from dba_tab_partitions
                                where table_owner = :o and  table_name = :n  and partition_name = :p',
                                        1, 4000,  'o', table_owner,   'n', table_name,  'p', partition_name ) high_value
                from dba_tab_partitions x  ,isbdba.arch_list y where y.tablename='MISP_TRNX_HISTORY' and x.table_name = 'MISP_TRNX_HISTORY_ARCH' and  x.table_owner='ARCHIVE' and y.schema = 'MISP' order by 2,3 ) b
                where  a.tablename='MISP_TRNX_HISTORY' and a.schema='MISP' and  b.table_name='MISP_TRNX_HISTORY_ARCH' 
                and b.table_owner = 'ARCHIVE' and b.table_name||b.partition_name not in (select tablename||partname from isbdba.arch_control where RC_EXP =0 ) 
                and  b.high_value <= to_char(sysdate-a.DATE_TABLE_ARCHIVE-a.DATE_TABLE_OLTP,'YYYYMMDD')