REM 
REM   Investigate memory chunk stress in the Shared Pool
REM   It is safe to run these queries as often as you like.    
REM   Large memory misses in the Shared Pool
REM   will be attemped in the Reserved Area.    Another 
REM   failure in the Reserved Area causes an 4031 error
REM
REM   What should you look for?
REM   Reserved Pool Misses = 0 can mean the Reserved 
REM   Area is too big.  Reserved Pool Misses always increasing
REM   but "Shared Pool Misses" not increasing can mean the Reserved Area 
REM   is too small.  In this case flushes in the Shared Pool
REM   satisfied the memory needs and a 4031 was not actually
REM   reported to the user.  Reserved Area Misses and 
REM   "Shared Pool Misses" always increasing can mean 
REM   the Reserved Area is too small and flushes in the 
REM   Shared Pool are not helping (likely got an ORA-04031).
REM   

clear col
set lines 100
set pages 999
set termout off
set trimout on
set trimspool on
col free_space format 999,999,999,999 head "Reserved|Free Space"
col max_free_size format 999,999,999,999 head "Reserved|Max"
col avg_free_size format 999,999,999,999 head "Reserved|Avg"
col used_space format 999,999,999,999 head "Reserved|Used"
col requests format 999,999,999,999 head "Total|Requests"
col request_misses format 999,999,999,999 head "Reserved|Area|Misses"
col last_miss_size format 999,999,999,999 head "Size of|Last Miss" 
col request_failures format 9,999 head "Shared|Pool|Miss"
col last_failure_size format 999,999,999,999 head "Failed|Size"
spool reserved.out

select request_failures, last_failure_size, free_space, max_free_size, avg_free_size
from v$shared_pool_reserved
/


select used_space, requests, request_misses, last_miss_size
from v$shared_pool_reserved
/

spool off
set termout on
set trimout off
set trimspool off
clear col

/* ---------------------------------------------

Sample Output:

                        Failed      Reserved     Reserved     Reserved
4031s?              Size  Free Space              Max               Avg
----------- ---------------- ------------------ ---------------- ----------------
           1               540     5,307,832       212,888       196,586


                                                          Reserved
        Reserved                 Total                Pool             Size of
               Used          Requests           Misses        Last Miss
-------------------- -------------------- ------------------- -------------------
          14,368                          2                       0                       0

*/
