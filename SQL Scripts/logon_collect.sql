
/* logons */
SELECT machine,logon_time,a.* FROM isbdba.logon_collect a 
WHERE 1=1
AND username='KKM_USER'
AND logon_time> SYSDATE - 450/1440
AND program IN ('Switch.exe', 'CrdServer.exe', 'HSMServer.exe', 'hc_gw.exe')

/* group logons*/
SELECT TO_CHAR(logon_time,'YYYYMMDD HH24:MI'), username, machine, program , COUNT(*) 
FROM isbdba.logon_collect 
WHERE 1 = 1 
AND username = 'KKM_USER'
AND logon_time > SYSDATE - 120/1440
AND program IN ('Switch.exe','CrdServer.exe','HSMServer.exe','hc_gw.exe')
GROUP BY TO_CHAR(logon_time, 'YYYYMMDD HH24:MI'),username,machine,program
ORDER BY 1 DESC

/* logoffs */
SELECT * FROM ISBDBA.logoff_collect
--WHERE 1=1 
--AND username='KKM_USER' 
--AND trg_date > SYSDATE - (90/1440) 


