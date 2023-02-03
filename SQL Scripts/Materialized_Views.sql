
SELECT DISTINCT owner,mview_name,staleness,stale_since FROM dba_mviews a
WHERE owner='OWBTARGET'

SELECT * FROM dba_snapshots a 
WHERE master_owner='SYSMON'

WHERE status='INVALID' --owner='OWBTARGET' 

SELECT owner,object_name, subobject_name,object_type,created FROM dba_objects
WHERE owner='SYSTEM' 
AND object_type='MATERIALIZED VIEW'

SELECT a.owner,object_name,object_type,a.status obj_status,b.status snap_status,created,last_ddl_time, master_owner,MASTER FROM dba_objects a,dba_snapshots b
WHERE a.owner='SYSTEM' 
AND a.object_type='MATERIALIZED VIEW'
AND a.object_name=b.NAME 

SELECT * FROM dba_objects WHERE object_name LIKE 'DBA_SNAP%'

DBA_SNAPSHOT_REFRESH_TIMES

DBA_SNAPSHOT_LOGS

dba_mviews


SELECT * FROM dba_audit_trail WHERE /*username='OWBTARGET'
AND */ TIMESTAMP=TO_DATE('12/8/2005 11:01:13','MM/DD/YYYY HH24:MI:SS')

