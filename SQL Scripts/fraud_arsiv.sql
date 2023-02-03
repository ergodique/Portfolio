select 'ALTER table fraudstar.'||table_name||' drop partition '||partition_name||';' 
from dba_tab_partitions 
where tablespace_name in ('AUTH_'||(select  
  case
    when :b = '1' then '0901'
    when :b = '2' then '0902'
    when :b = '3' then '0903'
    when :b = '4' then '0904'
    when :b = '5' then '0905'
    when :b = '6' then '0906'
    when :b = '7' then '0907'
    when :b = '8' then '0908'
    when :b = '9' then '0909'
    when :b = '10' then '0910'
    when :b = '11' then '0911'
    when :b = '12' then '0912'
    else '????'
  end 
from dual)||'',
'AUTH_LOG_'||(select  
  case
    when :b = '1' then '0901'
    when :b = '2' then '0902'
    when :b = '3' then '0903'
    when :b = '4' then '0904'
    when :b = '5' then '0905'
    when :b = '6' then '0906'
    when :b = '7' then '0907'
    when :b = '8' then '0908'
    when :b = '9' then '0909'
    when :b = '10' then '0910'
    when :b = '11' then '0911'
    when :b = '12' then '0912'
    else '????'
  end 
from dual)||'',
'EVENTS_'||(select  
  case
    when :b = '1' then '0901'
    when :b = '2' then '0902'
    when :b = '3' then '0903'
    when :b = '4' then '0904'
    when :b = '5' then '0905'
    when :b = '6' then '0906'
    when :b = '7' then '0907'
    when :b = '8' then '0908'
    when :b = '9' then '0909'
    when :b = '10' then '0910'
    when :b = '11' then '0911'
    when :b = '12' then '0912'
    else '????'
  end 
from dual)||'',
'TRANS_'||(select  
  case
    when :b = '1' then '0901'
    when :b = '2' then '0902'
    when :b = '3' then '0903'
    when :b = '4' then '0904'
    when :b = '5' then '0905'
    when :b = '6' then '0906'
    when :b = '7' then '0907'
    when :b = '8' then '0908'
    when :b = '9' then '0909'
    when :b = '10' then '0910'
    when :b = '11' then '0911'
    when :b = '12' then '0912'
    else '????'
  end 
from dual)||'') 
union all
select 'ALTER DATABASE DATAFILE '''||name||''' RESIZE 5M;' from v$datafile where name like '%_'||(select  
  case
    when :b = '1' then '0901'
    when :b = '2' then '0902'
    when :b = '3' then '0903'
    when :b = '4' then '0904'
    when :b = '5' then '0905'
    when :b = '6' then '0906'
    when :b = '7' then '0907'
    when :b = '8' then '0908'
    when :b = '9' then '0909'
    when :b = '10' then '0910'
    when :b = '11' then '0911'
    when :b = '12' then '0912'
    else '????'
  end 
from dual)||'%'
union all
select 'drop tablespace '||tablespace_name||' INCLUDING CONTENTS AND DATAFILES;' 
from dba_tablespaces 
where tablespace_name in ('AUTH_'||(select  
  case
    when :b = '1' then '0901'
    when :b = '2' then '0902'
    when :b = '3' then '0903'
    when :b = '4' then '0904'
    when :b = '5' then '0905'
    when :b = '6' then '0906'
    when :b = '7' then '0907'
    when :b = '8' then '0908'
    when :b = '9' then '0909'
    when :b = '10' then '0910'
    when :b = '11' then '0911'
    when :b = '12' then '0912'
    else '????'
  end 
from dual)||'',
'AUTH_LOG_'||(select  
  case
    when :b = '1' then '0901'
    when :b = '2' then '0902'
    when :b = '3' then '0903'
    when :b = '4' then '0904'
    when :b = '5' then '0905'
    when :b = '6' then '0906'
    when :b = '7' then '0907'
    when :b = '8' then '0908'
    when :b = '9' then '0909'
    when :b = '10' then '0910'
    when :b = '11' then '0911'
    when :b = '12' then '0912'
    else '????'
  end 
from dual)||'',
'EVENTS_'||(select  
  case
    when :b = '1' then '0901'
    when :b = '2' then '0902'
    when :b = '3' then '0903'
    when :b = '4' then '0904'
    when :b = '5' then '0905'
    when :b = '6' then '0906'
    when :b = '7' then '0907'
    when :b = '8' then '0908'
    when :b = '9' then '0909'
    when :b = '10' then '0910'
    when :b = '11' then '0911'
    when :b = '12' then '0912'
    else '????'
  end 
from dual)||'',
'TRANS_'||(select  
  case
    when :b = '1' then '0901'
    when :b = '2' then '0902'
    when :b = '3' then '0903'
    when :b = '4' then '0904'
    when :b = '5' then '0905'
    when :b = '6' then '0906'
    when :b = '7' then '0907'
    when :b = '8' then '0908'
    when :b = '9' then '0909'
    when :b = '10' then '0910'
    when :b = '11' then '0911'
    when :b = '12' then '0912'
    else '????'
  end 
from dual)||'') ;


select 'ALTER table fraudstar.'||table_name||' drop partition '||partition_name||';' 
from dba_tab_partitions 
where tablespace_name in ('AUTH_'||(SELECT to_char(ADD_MONTHS(SYSDATE,-:1),'YYMM') from dual)||'',
'AUTH_LOG_'||(SELECT to_char(ADD_MONTHS(SYSDATE,-:1),'YYMM') from dual)||'',
'EVENTS_'||(SELECT to_char(ADD_MONTHS(SYSDATE,-:1),'YYMM') from dual)||'',
'TRANS_'||(SELECT to_char(ADD_MONTHS(SYSDATE,-:1),'YYMM') from dual)||'') 
union all
select 'ALTER DATABASE DATAFILE '''||name||''' RESIZE 5M;' from v$datafile where name like '%_'||(SELECT to_char(ADD_MONTHS(SYSDATE,-:1),'YYMM') from dual)||'%'
union all
select 'drop tablespace '||tablespace_name||' INCLUDING CONTENTS AND DATAFILES;' 
from dba_tablespaces 
where tablespace_name in ('AUTH_'||(SELECT to_char(ADD_MONTHS(SYSDATE,-:1),'YYMM') from dual)||'',
'AUTH_LOG_'||(SELECT to_char(ADD_MONTHS(SYSDATE,-:1),'YYMM') from dual)||'',
'EVENTS_'||(SELECT to_char(ADD_MONTHS(SYSDATE,-:1),'YYMM') from dual)||'',
'TRANS_'||(SELECT to_char(ADD_MONTHS(SYSDATE,-:1),'YYMM') from dual)||'') 
;





expdp system/ims2004 DIRECTORY=EXPORT_DIR DUMPFILE=AUTHORIZATIONS_P20070101.dmp TABLES=Fraudstar.AUTHORIZATIONS:P20070101 LOGFILE=AUTHORIZATIONS.P20070101.log
gzip AUTHORIZATIONS_P20070101.dmp

impdp system/ims2004 DIRECTORY=IMPORT_DIR DUMPFILE=AUTHORIZATIONS_P20061227.dmp LOGFILE=AUTHORIZATIONS.P20061227.import.log TABLE_EXISTS_ACTION=APPEND CONTENT=DATA_ONLY


select 'expdp system/ims2004 DIRECTORY=EXPORT_DIR DUMPFILE=AUTHORIZATIONS_'||PARTITION_NAME||'.dmp TABLES=Fraudstar.AUTHORIZATIONS:'||PARTITION_NAME||' LOGFILE=AUTHORIZATIONS.'||PARTITION_NAME||'.log gzip AUTHORIZATIONS_'||PARTITION_NAME||'.dmp' 
from dba_tab_partitions 
where TABLE_NAME = 'AUTHORIZATIONS' and TABLE_OWNER = 'FRAUDSTAR' and partition_name like 'P200701%'



select 'impdp system/ims2004 DIRECTORY=IMPORT_DIR DUMPFILE=AUTHORIZATIONS_'||PARTITION_NAME||'.dmp LOGFILE=AUTHORIZATIONS.'||PARTITION_NAME||'.log TABLE_EXISTS_ACTION=APPEND CONTENT=DATA_ONLY gzip AUTHORIZATIONS_'||PARTITION_NAME||'.dmp' 
from dba_tab_partitions 
where TABLE_NAME = 'AUTHORIZATIONS' and TABLE_OWNER = 'FRAUDSTAR' and partition_name like 'P200702%'



select 'ALTER index '||index_owner||'.'||index_name||' rebuild partition '||partition_name||' TABLESPACE TSGECICI;' 
from dba_ind_partitions 
where tablespace_name in ('AUTH_0709','AUTH_LOG_0709','EVENTS_0709','TRANS_0709') ;

select 'ALTER table fraudstar.'||table_name||' move partition '||partition_name||' TABLESPACE TSGECICI;' 
from dba_tab_partitions 
where tablespace_name in ('AUTH_0709','AUTH_LOG_0709','EVENTS_0709','TRANS_0709') ;


select 'ALTER table fraudstar.'||table_name||' truncate partition '||partition_name||';' 
from dba_tab_partitions 
where partition_name like 'P200802%'
order by 1;


select 'ALTER table fraudstar.'||table_name||' drop partition '||partition_name||';' 
from dba_tab_partitions 
where tablespace_name in ('AUTH_0904','AUTH_LOG_0904','EVENTS_0904','TRANS_0904') 
order by 1;

select 'drop tablespace '||tablespace_name||';' 
from dba_tablespaces 
where tablespace_name in ('AUTH_0904','AUTH_LOG_0904','EVENTS_0904','TRANS_0904') 
order by 1;





fraudda

CREATE OR REPLACE FORCE VIEW FRAUDSTAR.EVENTS_201005 AS  SELECT*    FROM FRAUDSTAR.EVENTS PARTITION (P201005);


arþivde


insert into fraudstar.AUTHORIZATIONSLOGS select * from FRAUDSTAR.AUTHORIZATIONSLOGS_201005@FRAUD;
commit;



 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100501@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100502@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100503@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100504@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100505@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100506@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100507@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100508@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100509@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100510@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100511@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100512@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100513@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100514@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100515@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100516@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100517@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100518@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100519@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100520@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100521@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100522@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100523@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100524@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100525@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100526@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100527@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100528@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100529@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100530@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100531@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100601@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100602@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100603@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100604@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100605@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100606@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100607@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100608@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100609@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100610@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100611@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100612@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100613@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100614@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100615@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100616@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100617@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100618@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100619@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100620@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100621@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100622@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100623@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100624@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100625@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100626@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100627@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100628@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100629@FRAUD;
commit;
 insert into fraudstar.AUTHORIZATIONS select * from FRAUDSTAR.AUTHORIZATIONS_P20100630@FRAUD;
commit;



insert into fraudstar.AUTHORIZATIONSLOGS select * from FRAUDSTAR.AUTHORIZATIONSLOGS_201008@FRAUD;
commit;


insert into fraudstar.AUTHORIZATIONSLOGS select * from FRAUDSTAR.AUTHORIZATIONSLOGS_201009@FRAUD;
commit;




insert into fraudstar.TRANSACTIONS select * from FRAUDSTAR.TRANSACTIONS_201005@FRAUD;
commit;


insert into fraudstar.TRANSACTIONS select * from FRAUDSTAR.TRANSACTIONS_201006@FRAUD;
commit;





