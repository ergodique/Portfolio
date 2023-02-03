rem -----------------------------------------------------------------------
rem Filename:   cr8like.sql
rem Purpose:    Script to create a new user (with privs) like an existing
rem             database user. User data will not be copied.
rem Date:       02-Nov-1998
rem Author:     Frank Naude, Oracle FAQ
rem Updated:    Konstantin Krivosheyev - 7 Dec 2002
rem Updated:    Frank Naude - 18 Dec 2003, 2 Dec 2004
rem -----------------------------------------------------------------------

SET pages 0 feed OFF veri OFF lines 500

ACCEPT oldname prompt "Enter user to model new user to: "
ACCEPT newname prompt "Enter new user name: "
-- accept psw     prompt "Enter new user's password: "

-- Create user...
SELECT 'create user &&newname identified by values '''||PASSWORD||''''||
-- select 'create user &&newname identified by &psw'||
       ' default tablespace '||default_tablespace||
       ' temporary tablespace '||temporary_tablespace||' profile '||
       PROFILE||';'
FROM   sys.dba_users 
WHERE  username = UPPER('&&oldname');

-- Grant Roles...
SELECT 'grant '||granted_role||' to &&newname'||
       DECODE(ADMIN_OPTION, 'YES', ' WITH ADMIN OPTION')||';'
FROM   sys.dba_role_privs
WHERE  grantee = UPPER('&&oldname');  

-- Grant System Privs...
SELECT 'grant '||PRIVILEGE||' to &&newname'||
       DECODE(ADMIN_OPTION, 'YES', ' WITH ADMIN OPTION')||';'
FROM   sys.dba_sys_privs
WHERE  grantee = UPPER('&&oldname');  

-- Grant Table Privs...
SELECT 'grant '||PRIVILEGE||' on '||owner||'.'||table_name||' to &&newname;'
FROM   sys.dba_tab_privs
WHERE  grantee = UPPER('&&oldname');  

-- Grant Column Privs...
SELECT 'grant '||PRIVILEGE||' on '||owner||'.'||table_name||
       '('||column_name||') to &&newname;'
FROM   sys.dba_col_privs
WHERE  grantee = UPPER('&&oldname');  

-- Tablespace Quotas...
SELECT 'alter user '||username||' quota '||
       DECODE(max_bytes, -1, 'UNLIMITED', max_bytes)||
       ' on '||tablespace_name||';'
FROM   sys.dba_ts_quotas
WHERE  username = UPPER('&&oldname'); 

-- Set Default Role...
SET serveroutput ON
DECLARE
  defroles VARCHAR2(4000);
BEGIN
  FOR c1 IN (SELECT * FROM sys.dba_role_privs 
              WHERE grantee = UPPER('&&oldname')
                AND default_role = 'YES'
  ) LOOP
      IF LENGTH(defroles) > 0 THEN
         defroles := defroles||','||c1.granted_role;
      ELSE
         defroles := defroles||c1.granted_role;
      END IF;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('alter user &&newname default role '||defroles||';');
END;