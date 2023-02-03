SELECT SAMPLE_TIME, EVENT, TIME_WAITED
    FROM V$ACTIVE_SESSION_HISTORY
   WHERE SAMPLE_TIME BETWEEN TO_DATE ('27-01-2011 09:30', 'DD-MM-YYYY HH24:MI')
                         AND  TO_DATE ('27-01-2011 09:40',
                                       'DD-MM-YYYY HH24:MI')
         AND EVENT = 'log file parallel write'
ORDER BY 1 ASC;


SELECT SAMPLE_TIME, EVENT, TIME_WAITED
    FROM V$ACTIVE_SESSION_HISTORY
   WHERE SAMPLE_TIME BETWEEN TO_DATE ('01-09-2011 09:00', 'DD-MM-YYYY HH24:MI')
                         AND  sysdate
         AND EVENT = 'log file parallel write'
         and TIME_WAITED = 0
ORDER BY 1 desc