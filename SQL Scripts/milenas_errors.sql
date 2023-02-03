
/* 
Cemal : 	0216 622 21 83
	  		0505 482 83 86
Gökberk:	0532 674 69 24	
Tufan:		0555 552 51 55
Murat:		0216 360 94 95
Kýlýç:		0216 472 58 13

http://10.37.51.38/MILMON_CAGRI/webform1.aspx


SWITCH.exe,30
HSMServer.exe,18
w3wp.exe,3
milenasmonitorbase.exe,5
CrdServer.exe,36
hc_gw.exe,40  

*/

SELECT a.program, a.Machine, FAILED_OVER ,FAILOVER_METHOD,FAILOVER_TYPE , COUNT(*)  FROM v$session a
WHERE username='KKM_USER'
GROUP BY a.program, a.Machine, FAILED_OVER ,FAILOVER_METHOD,FAILOVER_TYPE
ORDER BY 2,1

SELECT program,machine,logon_time,SYSDATE,ROUND((SYSDATE-logon_time)*24,3) "KAÇ SAATTÝR AKTÝF" FROM v$session 
WHERE username='KKM_USER'
AND program IN ('Switch.exe','CrdServer.exe','HSMServer.exe','hc_gw.exe')
ORDER BY logon_time DESC

SELECT a.program, a.Machine, FAILED_OVER ,FAILOVER_METHOD,FAILOVER_TYPE , status,COUNT(*)  FROM v$session a
WHERE username='TEST'
GROUP BY a.program, a.Machine, FAILED_OVER ,FAILOVER_METHOD,FAILOVER_TYPE,status
ORDER BY 2,1


SELECT a.program, a.Machine, FAILED_OVER ,FAILOVER_METHOD,FAILOVER_TYPE , COUNT(*)  FROM v$session a
WHERE FAILED_OVER='YES'
GROUP BY a.program, a.Machine, FAILED_OVER ,FAILOVER_METHOD,FAILOVER_TYPE

SELECT program,FAILED_OVER ,FAILOVER_METHOD,FAILOVER_TYPE ,COUNT(*)  FROM v$session a
WHERE username='KKM_USER'
GROUP BY a.program, FAILED_OVER ,FAILOVER_METHOD,FAILOVER_TYPE
ORDER BY 1

SELECT a.program, a.Machine, FAILED_OVER ,FAILOVER_METHOD,FAILOVER_TYPE , logon_time,status  FROM v$session a
WHERE 1=1
--AND program ='w3wp.exe'
AND logon_time > SYSDATE - 50/1440
AND username='KKM_USER'
--AND program IN ('Switch.exe','CrdServer.exe','HSMServer.exe','hc_gw.exe')
--AND failover_method='NONE'
ORDER BY logon_time DESC

v$session_connect_info

SELECT machine,program,FAILED_OVER ,FAILOVER_METHOD,FAILOVER_TYPE , status,COUNT(*)  FROM v$session a
WHERE username='KKM_USER'
GROUP BY a.program, a.Machine, FAILED_OVER ,FAILOVER_METHOD,FAILOVER_TYPE,status
ORDER BY 1

SELECT sys_date,/*SUBSTR(LPAD(sys_time,6,'0'),1,2),*/ COUNT(*) FROM SWITCH.HOST_CONN_TRNX_LOG
WHERE SOURCE='SW'
AND sys_date='20060201'
GROUP BY sys_date
--GROUP BY SUBSTR(LPAD(sys_time,6,'0'),1,2)
--ORDER BY SUBSTR(LPAD(sys_time,6,'0'),1,2)


select inst_id,program,failed_over,count(*) from gv$session
where username='KKM_USER'
group by inst_id,program,failed_over
order by program,failed_over

