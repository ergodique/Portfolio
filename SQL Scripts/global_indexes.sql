select owner,index_name,table_name,uniqueness from dba_indexes i where I.TABLE_NAME in (select T.TABLE_NAME from dba_tables t where T.PARTITIONED = 'YES') and I.PARTITIONED = 'NO'


select * from dba_tables t where T.PARTITIONED = 'YES'


POS_TRNX_MNGMNT_INFO