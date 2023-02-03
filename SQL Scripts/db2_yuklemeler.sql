SELECT RTRIM(TABSCHEMA)||'.'||TABNAME , starttime, ROUND((endtime-starttime)*24*60*60,4) sn  FROM perf.list_history
WHERE 1=1
AND db_name='DBCUSPFT'
AND TYPEOFOP ='L'
AND optype='R'
AND starttime>SYSDATE-120
--and (endtime-starttime)*24*60*60>500
AND tabname='ABM_MSTGLGD_MG1TP'
--and tabname='ABM_MSTGLGD_MG2TP'
--and tabname='ABM_MUSTERIOZET_MOZTP'
--and tabname='ABM_ISLEMORT_AIOTD'
--and tabname='ABM_ADTGLGD_AG1TP'
--and tabname='ABM_ADTGLGD_AG2TP'
--AND tabname='ABM_MUADTGLGD_MAGTO'
ORDER BY starttime ASC

SELECT DISTINCT RTRIM(TABSCHEMA)||'.'||TABNAME ,COUNT(*)  FROM perf.list_history
WHERE 1=1
AND db_name='DBCUSPFT'
AND TYPEOFOP ='L'
AND optype='R'
AND (endtime-starttime)*24*60*60>500
GROUP BY RTRIM(TABSCHEMA)||'.'||TABNAME 