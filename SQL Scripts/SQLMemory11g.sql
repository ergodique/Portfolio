
REM   Filename:  SQLMemory11g.sql
REM
REM   You can increase/decrease the number of # of Statements to 
REM    review how memory is being allocated

set lines 100
set pages 999


col "Total Memory" for 999,999,999,999
col "Average Memory" for 999,999,999,999
col num_statements for 999,999 head "# of Statements"
col "TotExecs" for 999,999,999,999 head "Tot Execs"
col "SQL" for a20 word_wrapped

spool memoryinfo.out

SELECT sum(sharable_mem) "Total Memory"
  ,avg(sharable_mem) "Average Memory"
	,count(1) Num_Statements
	,sum(executions) "TotExecs"
  ,substr(sql_text,1,100) "SQL"
FROM v$sqlstats
WHERE executions = 1
GROUP BY substr(sql_text,1,100)
HAVING count(1) > 10
ORDER BY 3 DESC;

spool off

/* -----------------------------------------------------

Sample Output:


    Count      Sharable Total Sharable       Avg Memory          Biggest
------------ ---------------- -------------------- ---------------------- -------------------
     1,062 61,099,068      65,917,440                62,069          853,064

*/
 