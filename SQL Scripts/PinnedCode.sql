
REM   Filename:  PinnedCode.sql
REM
REM   This query will show you memory requirements of the 'pinned' 
REM   code in your database.    If you need to 'pin' many objects in the
REM   Shared Pool, Oracle recommends you determine the memory 
REM   allocated for these objects and increase the Shared Pool to
REM   accommodate the 'pinned' objects without impacting other 
REM   memory allocations over time.     
REM
REM   NOTE:  Some ORA-4031 issues can be narrowed to cases 
REM   where 100s or 1000s of objects are 'pinned' in the Shared 
REM   Pool over time, but no increases to the size of the Shared 
REM   Pool were implemented as well.
REM
REM    runs on 8i/9i/9.2/10g
REM

set pages 999
set lines 120
col owner format a30
col name format a30
col type format a30
col sharable_mem format 999,999,999,999 head "Memory Used"
col ttl format 999,999,999,999,999 head "Total Pinned Memory"

spool pinned.out

select owner, name, type, sharable_mem
from v$db_object_cache
where  kept = 'YES'
order by sharable_mem desc;

select sum(sharable_mem) ttl from v$db_object_cache where kept='YES';


spool off
clear col

/*---------------------------------------------------------

Sample Output:

Owner                          Name                           Type                                     Memory Used
----------------------------- --------------------------------- ------------------------------ ---------------------
SYS                             COL$                                TABLE                                          1,984
SYS                             CCOL$                             TABLE                                          1,877
SYS                             CDEF$                             TABLE                                          1,653
SYS                             FET$                                 TABLE                                          1,636
SYS                             PROXY_ROLE_DATA$ TABLE                                          1,620
SYS                             C_OBJ#_INTCOL#         CLUSTER                                    1,434
.
.
.

 Total Pinned Memory
------------------------------
                         49,268

*/
