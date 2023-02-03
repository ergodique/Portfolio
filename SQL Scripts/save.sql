SELECT a.* FROM dba_indexes a
WHERE a.TABLE_OWNER IN ('CARD','ECCF','EMV','HSM','SWITCH','UTILITY','POSMRC')
AND a.owner NOT IN ('CARD','ECCF','EMV','HSM','SWITCH','UTILITY','POSMRC')

UPDATE emv.card_chip_rel
   SET last_online_atc = :last_online_atc
 WHERE ins_code = :ins_code AND chip_no = :chip_no
 
/* Formatted on 2005/12/29 09:22 (Formatter Plus v4.8.5) */
SELECT DISTINCT status, module, sql_address,  sql_hash_value, sql_id,
                prev_sql_addr, prev_hash_value, prev_sql_id
           FROM v$session 
          WHERE username = 'KKM_USER'
		               --AND module='CrdServer.exe' 

 SELECT DISTINCT s.status,s.module,s.SQL_ADDRESS,s.SQL_HASH_VALUE,s.SQL_ID,s.PREV_SQL_ADDR,s.PREV_HASH_VALUE,s.PREV_SQL_ID, p.*       FROM v$session s, v$sql_plan p
 WHERE username='KKM_USER' --AND module='CrdServer.exe'
 AND s.sql_hash_value = p.hash_value
 AND p.OPERATION='FULL'
 
 
SELECT p.* FROM v$sql_plan p
WHERE p.hash_value IN (SELECT sql_hash_value FROM v$session  
WHERE 1=1
AND username='KKM_USER' 
AND sql_hash_value != 0
--AND module='CrdServer.exe'
)
UNION ALL
SELECT p.* FROM v$sql_plan p
WHERE p.hash_value IN (SELECT prev_hash_value FROM v$session  
WHERE 1=1
AND username='KKM_USER' 
AND prev_hash_value != 0
--AND module='CrdServer.exe'
)
