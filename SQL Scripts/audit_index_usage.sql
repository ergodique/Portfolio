DECLARE
DBNAME VARCHAR2(20);

BEGIN

SELECT NAME INTO DBNAME FROM V$DATABASE;
DELETE FROM ISBDBA.AUDIT_INDEX_USAGE@LINK_TO_EMREP WHERE DATABASE_NAME=DBNAME;

INSERT INTO ISBDBA.AUDIT_INDEX_USAGE@LINK_TO_EMREP
SELECT  DBNAME, schema_name, index_name, table_name, start_monitoring
    FROM dba_object_usage
   WHERE used = 'NO'
     AND TO_DATE (start_monitoring, 'MM/DD/YYYY HH24:MI:SS') < SYSDATE - 30
ORDER BY schema_name, start_monitoring;
COMMIT;
END;
/
