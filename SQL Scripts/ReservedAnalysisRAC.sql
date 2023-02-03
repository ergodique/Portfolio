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
col inst_id format 999 head "Instance #"
col request_failures format 999,999,999,999 head "Misses in |General|Shared Pool"
col request_misses format 999,999,999,999 head "Reserved Area|Misses"
col FS format 999,999,999,999 head "Reserved|Free Space"
col MFS format 999,999,999,999 head "Reserved|Max"
col US format 999,999,999,999 head "Reserved|Used"
col RQ format 999,999,999,999 head "Total|Requests"
col RM format 999,999,999,999 head "Reserved|Area|Misses"
col LMS format 999,999,999,999 head "Size of|Last Miss" 
col RF format 9,999 head "Shared|Pool|Misses"
col LFS format 999,999,999,999 head "Failed|Size"
spool reserved.out

select inst_id, request_failures, request_misses
from gv$shared_pool_reserved
/

select sum(request_failures) RF, sum(last_failure_size) LFS, 
  sum(free_space) FS, sum(max_free_size) MFS
from gv$shared_pool_reserved
/


select sum(used_space) US, sum(requests) RQ, 
    sum(request_misses) RM, sum(last_miss_size) LMS
from gv$shared_pool_reserved
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
