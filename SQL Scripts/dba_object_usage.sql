
--------------------------------------------------------
-- Connect with user SYS before executing this script
--------------------------------------------------------
-- 28.03.2005 Ýlker Anaç 
--------------------------------------------------------


CREATE OR REPLACE VIEW DBA_OBJECT_USAGE
(SCHEMA_NAME,INDEX_NAME, TABLE_NAME, MONITORING, USED, START_MONITORING, 
 END_MONITORING)
AS 
select us.name schema, io.name index_name, t.name table_name,
       decode(bitand(i.flags, 65536), 0, 'NO', 'YES'),
       decode(bitand(ou.flags, 1), 0, 'NO', 'YES'),
       ou.start_monitoring,
       ou.end_monitoring
from sys.obj$ io, sys.obj$ t, sys.ind$ i, sys.object_usage ou, sys.user$ us
where io.owner# = us.USER#
  and i.obj# = ou.obj#
  and io.obj# = ou.obj#
  and t.obj# = i.bo#;
  
CREATE PUBLIC SYNONYM DBA_OBJECT_USAGE FOR DBA_OBJECT_USAGE;

GRANT SELECT ON  DBA_OBJECT_USAGE TO SELECT_CATALOG_ROLE;  