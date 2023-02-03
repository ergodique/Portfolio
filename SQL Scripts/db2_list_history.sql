SELECT tarih, SUM(gb) FROM sims.top50db GROUP BY tarih ORDER BY tarih ASC

SELECT * FROM perf.list_history WHERE typeofop ='N'

SELECT typeofop, COUNT(*) FROM perf.list_history --where typeofop not in ('L','B','A') and 
--starttime >= to_date('20050720 10','YYYYMMDD HH24') --order by starttime desc
GROUP BY typeofop


SELECT MAX(STARTTIME) FROM perf.list_history
WHERE db_name='DBDWH'


SELECT TABSCHEMA,TABNAME,starttime,ROUND((endtime-starttime)*24*60*60,2) sure_sn FROM perf.list_history
WHERE typeofop='L'
AND optype='R'
AND starttime>SYSDATE-120
--AND ROUND((endtime-starttime)*24*60,2) > 15 
AND RTRIM(tabschema) IN ('SMODEL','SKREDI')
--AND tabname = 'DVS_DURUM_DSDTA'
ORDER BY 1,2,3


SELECT TABSCHEMA,TABNAME,starttime,ROUND((endtime-starttime)*24*60*60,2) sure_sn FROM perf.list_history
WHERE typeofop='L'
AND optype='R'
AND (tabschema,tabname) IN (
SELECT TABSCHEMA,TABNAME sure_sn FROM perf.list_history
WHERE typeofop='L'
AND optype='R'
AND starttime>SYSDATE-120
AND RTRIM(tabschema) IN ('SMODEL','SKREDI')
AND tabname NOT LIKE 'ABM%'
GROUP BY TABSCHEMA,TABNAME
HAVING AVG(ROUND((endtime-starttime)*24*60,2)) > 10 /* ortalama sure 15 dakikdan buyuk olanlar*/
)
ORDER BY 1,2,3

