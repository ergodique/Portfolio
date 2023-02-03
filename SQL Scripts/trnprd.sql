select  count(*) from dba_audit_trail where OBJ_NAME='CST_SALARY_PAYMENTS'

select  count(*) from dba_audit_trail where OBJ_NAME='CST_SALARY_PAYMENTS' and username not in ('COMMON')

select  * from dba_audit_trail where OBJ_NAME='CST_SALARY_PAYMENTS' and username not in ('COMMON')

select  * from dba_audit_trail where OBJ_NAME='CST_SALARY_PAYMENTS'