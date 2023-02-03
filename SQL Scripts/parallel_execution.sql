WITH px_session AS (SELECT qcsid, qcserial#, MAX (degree) degree,
MAX (req_degree) req_degree,
COUNT ( * ) no_of_processes
FROM gv$px_session p
  GROUP BY qcsid, qcserial#)
 SELECT s.inst_id,s.sid, s.username, degree, req_degree, no_of_processes,
  sql.sql_id,sql_text
 FROM gv$session s JOIN px_session p
   ON (s.sid = p.qcsid AND s.serial# = p.qcserial#)
  JOIN gv$sql sql
   ON (sql.sql_id = s.sql_id
   AND sql.child_number = s.sql_child_number)
   order by 5 desc;

SELECT inst_id,dfo_number, tq_id, server_Type, MIN (num_rows),
  MAX (num_rows),count(*) dop
   FROM gv$pq_tqstat
 GROUP BY inst_id,dfo_number, tq_id, server_Type
 ORDER BY dfo_number, tq_id, server_type DESC;
   
   
 SELECT name,value, round(value*100/sum(value) over(),2) pct
 FROM v$sysstat
 WHERE name LIKE 'Parallel operations%downgraded%';