
SELECT * FROM dba_objects WHERE object_name LIKE '%HIST%BLOCK%'

SELECT * FROM dba_audit_trail

SELECT * FROM dba_audit_session ORDER BY TIMESTAMP DESC

SELECT * FROM dba_audit_statement

SELECT * FROM dba_audit_object

SELECT * FROM dba_audit_exists

SELECT * FROM dba_audit_policies

SELECT * FROM dba_audit_policy_columns