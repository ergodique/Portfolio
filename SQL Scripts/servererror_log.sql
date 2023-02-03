SELECT Login_User,Server_Error,COUNT(*) FROM isbdba.servererror_log
WHERE 1=1
AND TIMESTAMP > SYSDATE - 75/1440 
AND program NOT IN ('OMS')
GROUP BY Login_User,Server_Error

SELECT * FROM isbdba.servererror_log 
WHERE
--AND login_user='OZLRAC' 
--AND TIMESTAMP > SYSDATE - 5/144
trunc(timestamp) = trunc(sysdate-4)  
and login_user='OWBRUNACC'
AND Server_Error=1031
ORDER BY TIMESTAMP DESC


delete from isbdba.servererror_log 
where trunc(timestamp) = trunc(sysdate-4)  
and login_user='OWBRUNACC'
AND Server_Error=1031
and rownum < 40001

commit
