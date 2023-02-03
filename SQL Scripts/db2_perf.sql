SELECT snapshot_timestamp,trunc((TOTAL_EXEC_TIME*1000 /num_executions)) as SURE_MS,num_executions,TOTAL_EXEC_TIME
   FROM perf.db2_sql_stats
where dbname = 'ICMNLSDB' 
and NUM_EXECUTIONS > 100 and STMT_TEXT like ('%FORKEYS.SOURCECOMPTYPEID%')
and snapshot_timestamp > sysdate -1/5
 ORDER BY snapshot_timestamp desc;
 
 select max(snapshot_timestamp) from PERF.DB2_SQL_STATS
 
 SELECT snapshot_timestamp,trunc((TOTAL_EXEC_TIME*1000 /num_executions)) as SURE_MS,num_executions,TOTAL_EXEC_TIME
   FROM perf.db2_sql_stats
where dbname = 'ICMNLSDB' 
and NUM_EXECUTIONS > 100 and STMT_TEXT like ('%ICMLOGOFF%')
and snapshot_timestamp > sysdate -1/5
 ORDER BY snapshot_timestamp desc;
 
 
 --PODK1BPE
 SELECT snapshot_timestamp,trunc((TOTAL_EXEC_TIME*1000 /num_executions)) as SURE_MS,num_executions,TOTAL_EXEC_TIME,STMT_TEXT
   FROM perf.db2_sql_stats
where dbname = 'PODK1BPE' 
and NUM_EXECUTIONS > 100 
and STMT_TEXT ='SELECT PI.PTID , TA.TKTID   FROM WORK_ITEM WI, TASK TA, PROCESS_INSTANCE PI, TASK_TEMPL_DESC TTD WHERE (WI.OBJECT_ID = TA.TKIID AND TA.CONTAINMENT_CTX_ID = PI.PIID AND TA.TKTID = TTD.TKTID) AND ((((TA.STATE =? AND WI.REASON =? )OR (TA.STATE =? AND WI.REASON =? ))AND TTD.TKTID =TA.TKTID AND TTD.LOCALE =? AND TA.KIND =? ) AND ( WI.OWNER_ID = ? AND WI.EVERYBODY = 0 AND WI.GROUP_NAME IS NULL OR WI.OWNER_ID IS NULL AND WI.EVERYBODY = 1 AND WI.GROUP_NAME IS NULL OR WI.OWNER_ID IS NULL AND WI.EVERYBODY = 0 AND WI.GROUP_NAME IN (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?))) WITH UR'
and snapshot_timestamp > sysdate -1/5
 ORDER BY snapshot_timestamp desc;
 
 
 