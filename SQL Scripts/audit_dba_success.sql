DECLARE
DBNAME VARCHAR2(20);
max_time date;
BEGIN

SELECT NAME INTO DBNAME FROM V$DATABASE;
select max(timestamp) into max_time from ISBDBA.AUDIT_DBA_SUCCESS@LINK_TO_EMREP where database_name = dbname;

INSERT INTO ISBDBA.AUDIT_DBA_SUCCESS@LINK_TO_EMREP
SELECT   DBNAME,
         RTRIM (a.os_username) os_username, 
         RTRIM (a.username) username,
         RTRIM (a.userhost) userhost,
         TIMESTAMP,
         RTRIM (a.owner) owner, RTRIM (a.obj_name) obj_name,
         RTRIM (a.action_name) action_name,
         RTRIM (a.obj_privilege) obj_privilege,
         RTRIM (a.sys_privilege) sys_privilege, 
         RTRIM (a.grantee) grantee
    FROM dba_audit_trail a
   WHERE TIMESTAMP > max_time
     AND UPPER (username) IN (SELECT a.grantee FROM dba_role_privs a WHERE a.granted_role = 'DBA')
     AND NOT (UPPER (os_username) IN
                 ('IA40841',
                  'FS46867',
                  'OD46858',
                  'KY42992',
                  'OB46856',
                  'CT38011',
                  'OD57011',
                  'SO46905'
                 )
             )
     AND NOT (    UPPER (os_username) IN ('ORACLE', 'PERF')
              AND (   UPPER (userhost) IN
                         ('KLSFRORAT1.ISBANK',
                          'KLSFRORAT2.ISBANK',
                          'KLORAGRD01.ISBANK'
                         )
                   OR UPPER (userhost) IN (SELECT host_name FROM gv$instance)
                  )
             ) 
     AND returncode = 0
ORDER BY TIMESTAMP ASC;

commit;

END;
/