SELECT SYSDATE   , MAX(transactiondate) FROM fraudstar.intrfc_authorizations

SELECT COUNT(*)  FROM fraudstar.intrfc_authorizations
WHERE transactiondate BETWEEN TO_DATE('200512291640','YYYYMMDDHH24MISS') AND TO_DATE('200512291720','YYYYMMDDHH24MISS') 

SELECT COUNT(*)  FROM fraudstar.authorizations
WHERE transactiondate BETWEEN TO_DATE('200512291640','YYYYMMDDHH24MISS') AND TO_DATE('200512291720','YYYYMMDDHH24MISS') 


SELECT * FROM fraudstar.processerror WHERE insertdate>=SYSDATE-1/2 ORDER BY insertdate ASC

SELECT * FROM isbdba.servererror_log WHERE TIMESTAMP>=SYSDATE-1/24 AND login_user LIKE 'FRAUD%'


SELECT SID,serial#,username,machine,logon_time FROM v$session WHERE username='FRAUDSTAR_APP'
ORDER BY logon_time DESC

SELECT * FROM v$session WHERE SID=229

dba_data_files

SELECT * FROM fraudstar.fraudstartime 
ORDER BY 1 DESC