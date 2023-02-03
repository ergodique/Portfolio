/* Formatted on 17.04.2012 09:58:01 (QP5 v5.139.911.3011) */
SELECT *
  FROM (  SELECT REPLACE (event, ' ') event,
                 SUM (DECODE (wait_Time, 0, 0, 1)) "Prev",
                 SUM (DECODE (wait_Time, 0, 1, 0)) "Curr",
                 COUNT (*) "TOT",
                 SUM (seconds_in_wait) SECONDS_IN_WAIT
            FROM v$session_Wait
           WHERE wait_class IN
                    ('Concurrency',
                     'User I/O',
                     'Commit',
                     'Application',
                     'Configuration')
        GROUP BY event
        ORDER BY 4 DESC)
 WHERE Tot > 5 AND SECONDS_IN_WAIT > 3;