SELECT a.owner,a.object_name,a.object_type, a.CREATED, a.LAST_DDL_TIME, a.STATUS FROM dba_objects a WHERE a.owner IN ('CARD','NSW','VISA','POSMRC','SWITCH','ECCF','HSM','MAIL','EMV') AND a.status ^= 'VALID' ORDER BY 1,2;


SELECT username,FAILOVER_TYPE,FAILOVER_METHOD ,FAILED_OVER,COUNT(*)   FROM v$session 
WHERE failed_over='YES'
GROUP BY username,FAILOVER_TYPE,FAILOVER_METHOD ,FAILED_OVER

SELECT username,machine,FAILOVER_TYPE,FAILOVER_METHOD ,FAILED_OVER,COUNT(*)   FROM v$session 
--WHERE username='KKM_USER' --failed_over='YES'
GROUP BY username,machine,FAILOVER_TYPE,FAILOVER_METHOD ,FAILED_OVER