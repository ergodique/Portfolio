select 'alter '||decode(object_type,'PACKAGE BODY','PACKAGE',object_type)||' '||owner||'.'||object_name||
decode(object_type,'PACKAGE BODY',' compile body;',' compile;') list from dba_objects where status='INVALID' AND OWNER IN 
 ('POSMRC',
'CARD',
'CLS',
'STIP',
'SWITCH',
'SFR_FRONTEND_APP',
'MISP','TMS');


Select 'alter '||object_type||' '||owner||'.'||object_name||' compile;'
From dba_objects
Where status <> 'VALID'
And object_type IN ('VIEW','SYNONYM',
'PROCEDURE','FUNCTION',
'PACKAGE','TRIGGER')
--and owner= 'POSMRC';

EXEC DBMS_UTILITY.compile_schema(schema => 'SCOTT');

-- Schema level.
EXEC UTL_RECOMP.recomp_serial('SCOTT');
EXEC UTL_RECOMP.recomp_parallel(4, 'SCOTT');

-- Database level.
EXEC UTL_RECOMP.recomp_serial();
EXEC UTL_RECOMP.recomp_parallel(4);

-- Using job_queue_processes value.
EXEC UTL_RECOMP.recomp_parallel();
EXEC UTL_RECOMP.recomp_parallel(NULL, 'SCOTT');


