select 
(select name from v$database) DBNAME,
(select host_name from v$instance) HOSTNAME,
(select version from v$instance) VERSION,
(select count(*) from dba_tables) TABLE_SAYISI,
(select count(*) from dba_indexes) INDEX_SAYISI,
(select count(*) from dba_users) USER_SAYISI,
(select count(*) from dba_tablespaces) TABLESPACE_SAYISI,
(select trunc(sum(bytes)/1024/1024/1024) from dba_segments)  GB_SIZE 
from dual;

select * from v$instance