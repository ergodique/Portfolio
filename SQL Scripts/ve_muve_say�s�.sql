/* Formatted on 2009/12/03 17:25 (Formatter Plus v4.8.8) */
SELECT TO_DATE (last_Day(add_months(SYSDATE, -1)), 'DD.MM.YYYY') FROM dual;

SELECT TRUNC(add_months(SYSDATE, -1),'MM') FROM dual;



SELECT   jtrxname, COUNT (*)
    FROM websube.journal
   WHERE jtrxname IN ('VE', 'MUVE')
     AND jopdate BETWEEN TRUNC(add_months(SYSDATE, -1),'MM')
                     AND TO_DATE (last_Day(add_months(SYSDATE, -1)), 'DD.MM.YYYY')
GROUP BY jtrxname;