select * from perf.ORA_CAPACITY_STATS_DAILY a where A.TARIH > sysdate -3 and A.TARGET_NAME = 'SAFIRPRD' and a.metric_name in ('UserTransactionPerSec','UserCommitsPerSec')
order by 1


select * from perf.ORA_CAPACITY_STATS a where A.TARIH > sysdate -3 and A.TARGET_NAME = 'SAFIRPRD' and a.metric_name in ('UserTransactionPerSec')
order by 1