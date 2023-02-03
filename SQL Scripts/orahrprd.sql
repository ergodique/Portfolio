SELECT   TO_CHAR (start_time, 'dd-mm-yyyy hh24') login_time, COUNT (*) cnt
    FROM fnd_logins
   WHERE start_time > sysdate -1
     AND login_type IS NOT NULL
--    AND end_time IS NULL
GROUP BY TO_CHAR (start_time, 'dd-mm-yyyy hh24')
ORDER BY 1 desc;
