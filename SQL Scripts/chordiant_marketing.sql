CREATE TABLESPACE MDSYSDATA DATAFILE 
  '/oracle/oradata/DWDEV/mdsysdata01.dbf' SIZE 100M AUTOEXTEND ON NEXT 100M MAXSIZE UNLIMITED
LOGGING
ONLINE
PERMANENT
EXTENT MANAGEMENT LOCAL AUTOALLOCATE
BLOCKSIZE 8K
SEGMENT SPACE MANAGEMENT AUTO
FLASHBACK ON;

CREATE TABLESPACE MDSYSINDX DATAFILE 
  '/oracle/oradata/DWDEV/mdsysindx01.dbf' SIZE 100M AUTOEXTEND ON NEXT 100M MAXSIZE UNLIMITED
LOGGING
ONLINE
PERMANENT
EXTENT MANAGEMENT LOCAL AUTOALLOCATE
BLOCKSIZE 8K
SEGMENT SPACE MANAGEMENT AUTO
FLASHBACK ON;

CREATE TABLESPACE MDDYNDATA DATAFILE 
  '/oracle/oradata/DWDEV/mddyndata01.dbf' SIZE 100M AUTOEXTEND ON NEXT 100M MAXSIZE UNLIMITED
LOGGING
ONLINE
PERMANENT
EXTENT MANAGEMENT LOCAL AUTOALLOCATE
BLOCKSIZE 8K
SEGMENT SPACE MANAGEMENT AUTO
FLASHBACK ON;

CREATE TABLESPACE MDDYNINDX DATAFILE 
  '/oracle/oradata/DWDEV/mddynindx01.dbf' SIZE 100M AUTOEXTEND ON NEXT 100M MAXSIZE UNLIMITED
LOGGING
ONLINE
PERMANENT
EXTENT MANAGEMENT LOCAL AUTOALLOCATE
BLOCKSIZE 8K
SEGMENT SPACE MANAGEMENT AUTO
FLASHBACK ON;

CREATE TABLESPACE MDCOMDATA DATAFILE 
  '/oracle/oradata/DWDEV/mdcomdata01.dbf' SIZE 100M AUTOEXTEND ON NEXT 100M MAXSIZE UNLIMITED
LOGGING
ONLINE
PERMANENT
EXTENT MANAGEMENT LOCAL AUTOALLOCATE
BLOCKSIZE 8K
SEGMENT SPACE MANAGEMENT AUTO
FLASHBACK ON;

CREATE TABLESPACE MDCOMINDX DATAFILE 
  '/oracle/oradata/DWDEV/mdcomindx01.dbf' SIZE 100M AUTOEXTEND ON NEXT 100M MAXSIZE UNLIMITED
LOGGING
ONLINE
PERMANENT
EXTENT MANAGEMENT LOCAL AUTOALLOCATE
BLOCKSIZE 8K
SEGMENT SPACE MANAGEMENT AUTO
FLASHBACK ON;

CREATE ROLE MD_ACCESS;

CREATE USER MDADMIN
  IDENTIFIED BY MDADMIN
  DEFAULT TABLESPACE MDSYSDATA
  TEMPORARY TABLESPACE TEMP
  PROFILE DEFAULT
  ACCOUNT UNLOCK;
     
  ALTER USER MDADMIN QUOTA UNLIMITED ON MDSYSDATA;
   ALTER USER MDADMIN QUOTA UNLIMITED ON MDSYSINDX;
   ALTER USER MDADMIN QUOTA UNLIMITED ON MDDYNDATA;
   ALTER USER MDADMIN QUOTA UNLIMITED ON MDDYNINDX;
   ALTER USER MDADMIN QUOTA UNLIMITED ON MDCOMDATA;
   ALTER USER MDADMIN QUOTA UNLIMITED ON MDCOMINDX;
   grant connect,create trigger to mdadmin;
grant md_access to mdadmin;

create role md_application;

grant md_application to mdadmin with admin option;

grant create any table, create any index, create any view to md_application;


CREATE USER MDCUST
  IDENTIFIED BY MDCUST
  DEFAULT TABLESPACE MDSYSDATA
  TEMPORARY TABLESPACE TEMP
  PROFILE DEFAULT
  ACCOUNT UNLOCK;
     
  ALTER USER MDCUST QUOTA UNLIMITED ON MDSYSDATA;
   ALTER USER MDCUST QUOTA UNLIMITED ON MDSYSINDX;
   ALTER USER MDCUST QUOTA UNLIMITED ON MDDYNDATA;
   ALTER USER MDCUST QUOTA UNLIMITED ON MDDYNINDX;
   ALTER USER MDCUST QUOTA UNLIMITED ON MDCOMDATA;
   ALTER USER MDCUST QUOTA UNLIMITED ON MDCOMINDX;
   grant connect to mdCUST;
   

CREATE USER USRMDCUST
  IDENTIFIED BY USRMDCUST
  DEFAULT TABLESPACE users
  TEMPORARY TABLESPACE TEMP
  PROFILE DEFAULT
  ACCOUNT UNLOCK;
  
  grant connect to usrmdCUST;
  
CREATE USER USRMDADMIN
  IDENTIFIED BY USRMDADMIN
  DEFAULT TABLESPACE users
  TEMPORARY TABLESPACE TEMP
  PROFILE DEFAULT
  ACCOUNT UNLOCK;
  
  grant connect to usrmdadmin;