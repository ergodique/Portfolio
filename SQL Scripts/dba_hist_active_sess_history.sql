  SELECT sql_id,
         COUNT (*),
         MAX (tm) mx,
         AVG (tm) av,
         MIN (tm) MIN
    FROM (  SELECT sql_id, sql_exec_id, MAX (tm) tm
              FROM (SELECT sql_id,
                           sql_exec_id,
                           ( (CAST (sample_time AS DATE))
                            - (CAST (sql_exec_Start AS DATE)))
                           * (3600 * 24)
                              tm
                      FROM dba_hist_active_sess_history
                     WHERE sql_exec_id IS NOT NULL)
          GROUP BY sql_id, sql_exec_id)
GROUP BY sql_id
  HAVING COUNT (*) > 10
ORDER BY mx, av;

