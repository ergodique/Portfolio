select CASE METRIC_NAME
WHEN 'SQL Service Response Time' then 'SQL Service Response Time (secs)'
WHEN 'Response Time Per Txn' then 'Response Time Per Txn (secs)'
ELSE METRIC_NAME
END METRIC_NAME,
CASE METRIC_NAME
WHEN 'SQL Service Response Time' then ROUND((MINVAL / 100),2)
WHEN 'Response Time Per Txn' then ROUND((MINVAL / 100),2)
ELSE MINVAL
END MININUM,
CASE METRIC_NAME
WHEN 'SQL Service Response Time' then ROUND((MAXVAL / 100),2)
WHEN 'Response Time Per Txn' then ROUND((MAXVAL / 100),2)
ELSE MAXVAL
END MAXIMUM,
CASE METRIC_NAME
WHEN 'SQL Service Response Time' then ROUND((AVERAGE / 100),2)
WHEN 'Response Time Per Txn' then ROUND((AVERAGE / 100),2)
ELSE AVERAGE
END AVERAGE
from SYS.V_$SYSMETRIC_SUMMARY 
order by 1 desc
