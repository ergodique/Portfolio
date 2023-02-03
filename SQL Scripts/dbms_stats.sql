BEGIN
  SYS.DBMS_STATS.GATHER_SCHEMA_STATS ( 
   OwnName        => 'CCSOWNER' ,
   Estimate_Percent  => SYS.DBMS_STATS.AUTO_SAMPLE_SIZE, 
   Degree            => 4, 
   granularity      => 'ALL', 
   Cascade           => TRUE,
   No_Invalidate     => FALSE);
END;
/



DECLARE
partnamevar varchar2(20);
BEGIN
select 'P'||TO_CHAR(sysdate-1, 'YYYYMMDD', 'NLS_CALENDAR=GREGORIAN') into partnamevar  from dual;

  SYS.DBMS_STATS.GATHER_TABLE_STATS (
      OwnName        => 'FRAUDSTAR'
     ,TabName        => 'AUTHORIZATIONS'
     --,PARTNAME      => partnamevar
    ,Granularity       => 'GLOBAL'
    ,Estimate_Percent  => SYS.DBMS_STATS.AUTO_SAMPLE_SIZE
    ,Method_Opt        => 'FOR ALL INDEXED COLUMNS SIZE AUTO '
    ,DEGREE            => 4
    ,CASCADE           => TRUE
    ,No_Invalidate     => FALSE);
END;
/


BEGIN
  SYS.DBMS_STATS.GATHER_TABLE_STATS (
      OwnName        => 'ISBDBA'
     ,TabName        => 'DBA_INDEXES'
    ,Estimate_Percent  => 1
    ,Degree            => 4
    ,Cascade           => TRUE
    ,No_Invalidate     => FALSE);
END;
/





/*export*/

exec DBMS_STATS.CREATE_STAT_TABLE ('ISBDBA', 'SAVESTATS');


exec DBMS_STATS.FLUSH_DATABASE_MONITORING_INFO;

exec DBMS_STATS.EXPORT_TABLE_STATS (
ownname => 'ARCHIVE', 
tabname => 'HOST_CONN_TRNX_LOG', 
partname =>'TRNXLOGPART_20070225',
stattab =>'STATS_TABLE', 
statid => 'MILW3WP',
cascade => TRUE,
statown => 'ISBDBA')

update isbdba.savestats set c2 = 'P20070116';



EXEC DBMS_STATS.IMPORT_TABLE_STATS (
   ownname => 'HOST', 
tabname => 'HOST_CONN_TRNX_LOG', 
--partname =>'P20070116',
stattab =>'STATS_TABLE', 
statid => 'SERDARDENEME',
cascade => TRUE,
     statown => 'ISBDBA',
    force    => TRUE)
    
  

    
exec DBMS_STATS.SET_TABLE_STATS (
   ownname => 'FRAUDSTAR', 
tabname => 'AUTHORIZATIONS', 
partname =>'P200508',
stattab =>'SAVESTATS', 
statid => 'GUNLUK',
   numrows   =>    9999, 
   numblks  =>     9999,
   --avgrlen       NUMBER   DEFAULT NULL, 
   --flags         NUMBER   DEFAULT NULL,
    statown => 'ISBDBA',
   -- cachedblk     NUMBER    DEFAULT NULL,
   --cachehit      NUMBER    DEFUALT NULL,
   force   =>      TRUE);




DBMS_STATS.EXPORT_INDEX_STATS (
   ownname => 'FRAUDSTAR', 
   indname  VARCHAR2, 
   stattab =>'STATS_TABLE',
   statid => 'ALL_INDEXES',
   statown => 'ISBDBA');
   
   
exec DBMS_STATS.EXPORT_SCHEMA_STATS (
   ownname => 'SWITCH',
   stattab =>'STATS_TABLE', 
   statid => 'SWITCH_060809',
  statown => 'ISBDBA');

EXEC DBMS_STATS.IMPORT_SCHEMA_STATS (
   ownname => 'SWITCH',
   stattab =>'STATS_TABLE', 
   statid => 'SWITCH_060809',
   statown => 'ISBDBA',
   no_invalidate TRUE),
   force   =>  FALSE);

   
 

/*delete*/ 

exec DBMS_STATS.DELETE_TABLE_STATS ('SO46905', 'ACC_ACCOUNTHISTORY_ACHTP')

 

/*import*/

exec DBMS_STATS.IMPORT_TABLE_STATS (
ownname => 'FRAUDSTAR', 
tabname => 'AUTHORIZATIONS',
partname =>'P200607',
stattab =>'STATS_TABLE', 
statid => 'HAZIRAN',
cascade => TRUE,
statown => 'ISBDBA',
no_invalidate => TRUE,
force => FALSE);


exec DBMS_STATS.IMPORT_TABLE_STATS (
ownname => 'FRAUDSTAR', 
tabname => 'AUTHORIZATIONS',
partname =>'P200607',
stattab =>'STATS_TABLE', 
statid => 'TEMMUZ',
cascade => TRUE,
statown => 'ISBDBA',
no_invalidate => TRUE),
force => FALSE);

exec DBMS_STATS.EXPORT_INDEX_STATS (
   ownname  => 'ARCHIVE', 
   indname  => 'IX_HOST_CONN_TRNX_TIME', 
   partname => 'TRNXLOGPART_20070225',
   stattab  => 'STATS_TABLE', 
   statid   => 'W3INDX',
   statown  => 'ISBDBA')
   
DBMS_STATS.IMPORT_INDEX_STATS (
   ownname  => 'ARCHIVE', 
   indname  => 'IX_HOST_CONN_TRNX_TIME', 
   partname => 'TRNXLOGPART_20070225',
   stattab  => 'STATS_TABLE', 
   statid   => 'W3INDX',
   statown  => 'ISBDBA',
   force    => TRUE);



 

 

/* belirli tablo veya indeksi kullanan sql'ler */

select --count(*) 
distinct sql_id,plan_hash_value,timestamp 
from v$sql_plan p
where OBJECT_OWNER||OBJECT_NAME in 
(select t.OWNER||t.TABLE_NAME a from dba_tables t
where t.OWNER= :owner and t.TABLE_NAME= :table_or_index_name
union
select i.TABLE_OWNER||i.TABLE_NAME a from dba_indexes i
where i.TABLE_OWNER= :owner and i.TABLE_NAME= :table_or_index_name 
union
select i.OWNER||i.INDEX_NAME a from dba_indexes i
where i.OWNER= :owner and i.INDEX_NAME= :table_or_index_name)
order by 1,3 desc


exec DBMS_STATS.DELETE_TABLE_STATS (
   ownname         => 'CUST', 
   tabname         => 'BSC_PROFIT_TERM', 
   partname        => 'P200703',
   no_invalidate   => FALSE,
   force           => TRUE)
   
exec DBMS_STATS.SET_TABLE_STATS (
   ownname         => 'CUST', 
   tabname         => 'BSC_PROFIT_TERM', 
   partname        => 'P200612',
   
   numrows       => 0, 
   numblks       => 0,
   no_invalidate   => FALSE,
   force           => TRUE
   )
   
exec DBMS_STATS.LOCK_TABLE_STATS (
   ownname         => 'CUST', 
   tabname         => 'BSC_PROFIT_TERM'
   )


exec DBMS_STATS.UNLOCK_TABLE_STATS (
   ownname         => 'CUST', 
   tabname         => 'KYP_CBTEEXPOSUREISBANK'
   )
