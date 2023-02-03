
REM   Filename:  SQLMemory10g.sql
REM
REM  This does not work prior to 10g, as the V$SQLSTATS view is new to 10g
REM   You can increase/decrease the number of # of Statements to review how memory is being allocated

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
HAVING count(1) > 5
ORDER BY 3 DESC;

spool off
/*----------------------------------------

Sample Output:

    Total Memory   Average Memory # of Statements        Tot Execs SQL
---------------------- ------------------------- ---------------------- -------------------- ------------------------------------
             360,831                    60,139                          6                        6 SELECT
                                                                                                                DECODE(OBJECT_TYPE,'
                                                                                                                TABLE',2,'VIEW',2,'P
                                                                                                                ACKAGE',3,'PACKAGE
                                                                                                                BODY',3,'PROCEDURE',
                                                                                                                4,'FUNCTION',5

/*