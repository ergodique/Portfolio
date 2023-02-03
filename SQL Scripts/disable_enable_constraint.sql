select 'ALTER TABLE '||u.owner||'.'||c.table_name|| 
' DISABLE CONSTRAINT '||constraint_name||' ;' 
from DBA_constraints c, DBA_tables u 
where c.table_name = u.table_name
and u.owner in ('ODAK','TAX'); 


select 'ALTER TABLE '||u.owner||'.'||c.table_name|| 
' ENABLE CONSTRAINT '||constraint_name||' ;' 
from DBA_constraints c, DBA_tables u 
where c.table_name = u.table_name
and u.owner in ('ODAK','TAX'); 