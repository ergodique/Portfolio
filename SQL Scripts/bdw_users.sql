CREATE USER DWH
  IDENTIFIED BY DWH
  DEFAULT TABLESPACE DWHDATA
  TEMPORARY TABLESPACE TEMP
  PROFILE DEFAULT;
      GRANT CONNECT TO DWH;
  grant SELECT ANY DICTIONARY to dwh;
  grant SELECT ANY sequence to dwh;
  grant create synonym to dwh;
  grant create any table to dwh;
  grant analyze any to dwh;
  grant drop any table to dwh;
  grant insert any table to dwh;
  grant create any index to dwh;
  GRANT resource TO DWh;
  
  
  ALTER USER dwh DEFAULT ROLE ALL;
  
  
  CREATE USER SRC
  IDENTIFIED BY SRC
  DEFAULT TABLESPACE DWHDATA
  TEMPORARY TABLESPACE TEMP
  PROFILE DEFAULT;
       
    grant create any table to src;
    GRANT resource TO src;
    GRANT connect TO src;
  
  ALTER USER src DEFAULT ROLE ALL;
  
  
  
  
  CREATE USER STG
  IDENTIFIED BY STG
  DEFAULT TABLESPACE DWHDATA
  TEMPORARY TABLESPACE TEMP
  PROFILE DEFAULT;
       
    grant create any table to stg;
    GRANT resource TO stg;
    GRANT connect TO stg;
  
  ALTER USER stg DEFAULT ROLE ALL;
  
  
  CREATE USER etl
  IDENTIFIED BY etl
  DEFAULT TABLESPACE etlDATA
  TEMPORARY TABLESPACE TEMP
  PROFILE DEFAULT;
  
      GRANT CONNECT TO etl;
      GRANT resource TO etl;
    
  grant create synonym to etl;
  grant debug connect session to etl;
  grant execute on DBMS_LOCK to etl;
  grant create any table to etl;
  grant analyze any to etl;
  grant drop any table to etl;
  grant insert any table to etl;
  grant create any index to etl;
  grant SELECT ANY DICTIONARY to etl;
  grant SELECT ANY SEQUENCE to etl;
  grant execute on DBMS_STATS to etl;
  
  
  CREATE USER DWHAUX
  IDENTIFIED BY DWHAUX
  DEFAULT TABLESPACE DWHAUXDATA
  TEMPORARY TABLESPACE TEMP
  PROFILE DEFAULT;
  
      GRANT CONNECT TO DWHAUX;
      GRANT resource TO DWHAUX;
  grant create synonym to DWHAUX;
  grant debug connect session to DWHAUX;
  grant execute on DBMS_LOCK to DWHAUX;
  grant create any table to DWHAUX;
  grant analyze any to DWHAUX;
  
  grant insert any table to DWHAUX;
  grant create any index to DWHAUX;
  grant SELECT ANY DICTIONARY to DWHAUX;
  grant SELECT ANY SEQUENCE to DWHAUX;
  grant execute on DBMS_STATS to DWHAUX;
  
  
  
  CREATE USER USRDBA
  IDENTIFIED BY USRDBA
  DEFAULT TABLESPACE dwhDATA
  TEMPORARY TABLESPACE TEMP
  PROFILE DEFAULT;
       
       
    grant connect to usrdba;
    grant resource to usrdba;
  
  ALTER USER USRDBA DEFAULT ROLE ALL;
  
  
  CREATE USER USReadm
  IDENTIFIED BY USReadm
  DEFAULT TABLESPACE etladminDATA
  TEMPORARY TABLESPACE TEMP
  PROFILE DEFAULT;
       
    
    grant connect to USReadm;
    grant resource to USReadm;
  
  ALTER USER USReadm DEFAULT ROLE ALL;
  
  
  CREATE USER USRDRO
  IDENTIFIED BY USRDRO
  DEFAULT TABLESPACE dwhroDATA
  TEMPORARY TABLESPACE TEMP
  PROFILE DEFAULT;
       
    
    grant connect to USRDRO;
    grant resource to USRDRO;
  
  ALTER USER USRDRO DEFAULT ROLE ALL;
  
  
  CREATE USER USREDEV
  IDENTIFIED BY USREDEV
  DEFAULT TABLESPACE etldevDATA
  TEMPORARY TABLESPACE TEMP
  PROFILE DEFAULT;
       
    
    grant connect to USREDEV;
    grant resource to USREDEV;
  
  ALTER USER USREDEV DEFAULT ROLE ALL;
  
  
  