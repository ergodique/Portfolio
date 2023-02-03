SELECT username, sum(value)/1024/1024 MB
FROM v$session sess, v$sesstat sstat, v$statname sname
WHERE sess.sid = sstat.sid
AND sstat.statistic# = sname.statistic#
AND sname.name = 'session uga memory'
group by username
order by 2 desc;


SELECT sum(value)/1024/1024 MB
FROM v$session sess, v$sesstat sstat, v$statname sname
WHERE sess.sid = sstat.sid
AND sstat.statistic# = sname.statistic#
AND sname.name = 'session uga memory'

SELECT sum(value)/1024/1024 MB
FROM v$session sess, v$sesstat sstat, v$statname sname
WHERE sess.sid = sstat.sid
AND sstat.statistic# = sname.statistic#
AND sname.name = 'session pga memory'


select * from v$statname where name like '%memory%'



