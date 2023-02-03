
REM  Filename: TrendsLC.sql
REM
REM  With 10g and higher, there is an automatic repository 
REM  of data captured on various activities in the database.
REM  You can use this script to build a matrix
REM  of the Reload and Invalidations data over time
REM
REM  You can adjust the decode statements to grab
REM  hourly information for whatever hours you want to see
REM  within the retention period for your AWR statistics data
REM 
REM  After you have the matrix information, you can load the text
REM  file into spreadsheet and build a line chart to see trends
REM  over time and find business/application activities that may
REM  be putting stresses on the Library Cache
REM
REM  NOTE:  For the reload information, the goal is to keep 
REM  hit ratios to < 10% of total loads on the system.   This 
REM  first script shows by hour the percentage of reloads 
REm  to total load.

set lines 300
set pages 999
set termout off
set trimout on
set trimspool on
set head off
set feed off


col n format a30

spool HitRatio.out
select n,
   max(decode(to_char(begin_interval_time, 'hh24'), 1,rldpct, null)) "1",
   max(decode(to_char(begin_interval_time, 'hh24'), 2,rldpct, null)) "2",
   max(decode(to_char(begin_interval_time, 'hh24'), 3,rldpct, null)) "3",
   max(decode(to_char(begin_interval_time, 'hh24'), 4,rldpct, null)) "4",
   max(decode(to_char(begin_interval_time, 'hh24'), 5,rldpct, null)) "5",
   max(decode(to_char(begin_interval_time, 'hh24'), 6,rldpct, null)) "6",
   max(decode(to_char(begin_interval_time, 'hh24'), 7,rldpct, null)) "7",
   max(decode(to_char(begin_interval_time, 'hh24'), 8,rldpct, null)) "8",
   max(decode(to_char(begin_interval_time, 'hh24'), 9,rldpct, null)) "9",
   max(decode(to_char(begin_interval_time, 'hh24'), 10,rldpct, null)) "10",
   max(decode(to_char(begin_interval_time, 'hh24'), 11,rldpct, null)) "11",
   max(decode(to_char(begin_interval_time, 'hh24'), 12,rldpct, null)) "12",
   max(decode(to_char(begin_interval_time, 'hh24'), 13,rldpct, null)) "13",
   max(decode(to_char(begin_interval_time, 'hh24'), 14,rldpct, null)) "14",
   max(decode(to_char(begin_interval_time, 'hh24'), 15,rldpct, null)) "15",
   max(decode(to_char(begin_interval_time, 'hh24'), 16,rldpct, null)) "16",
   max(decode(to_char(begin_interval_time, 'hh24'), 17,rldpct, null)) "17",
   max(decode(to_char(begin_interval_time, 'hh24'), 18,rldpct, null)) "18",
   max(decode(to_char(begin_interval_time, 'hh24'), 19,rldpct, null)) "19",
   max(decode(to_char(begin_interval_time, 'hh24'), 20,rldpct, null)) "20",
   max(decode(to_char(begin_interval_time, 'hh24'), 21,rldpct, null)) "21",
   max(decode(to_char(begin_interval_time, 'hh24'), 22,rldpct, null)) "22",
   max(decode(to_char(begin_interval_time, 'hh24'), 23,rldpct, null)) "23",
   max(decode(to_char(begin_interval_time, 'hh24'), 24,rldpct, null)) "24"
from (select '"'||namespace||'"' n, begin_interval_time, 
   round(100*((invalidations+reloads)-invalidations)/(pins-pinhits),0) rldpct
from dba_hist_librarycache a, dba_hist_snapshot b 
where (reloads > 0 or invalidations > 0) and a.snap_id=b.snap_id
and to_char(begin_interval_time,'hh24:mi') between '01:00' and '24:00'
and to_char(begin_interval_time,'dd-mon')  = to_char(sysdate-1, 'dd-mon'))
group by n;


spool off

clear col
set termout on
set trimout off
set trimspool off
set feed on
set head on

/*----------------------------------------------------------------------

Sample Output:

"TABLE/PROCEDURE"                    3101       3148       3158       3186       3203       3228       3260       3398
"CLUSTER"                                                7             7              7              7             7              7              7              7
"TRIGGER"                                               77           79            79           81           81            83            85           87 


"SQL AREA"                                          724          726         726         726         732         739          740        740 

*/