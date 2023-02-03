
-- Collect general PGA Statistics
select sysdate current_time, p.*
  from gv$pgastat p;

-- Collect PGA Usage info for queries who allocates more than 1GB PGA on an instance
-- MAXMEM is misleading because different processes have their max on different times and maxmem sums all max values
-- PGA_ALLOC_MEM is sum of Workarea + non workarea + freeable 
select sysdate current_time,
       ps.qcsid, nvl(ps.qcinst_id, ps.inst_id) qc_instid, s.sql_id, ps.inst_id "SLAVE INSTANCE", count(*) "PROCESS COUNT",
       round(sum(PGA_ALLOC_MEM)/(1024*1024),2) "ALLOCATED (MB)",
       round(sum(PGA_USED_MEM)/(1024*1024),2) "USED (MB)",
       round(sum(PGA_FREEABLE_MEM)/(1024*1024),2) "FREEABLE (MB)",
       round(sum(PGA_MAX_MEM)/(1024*1024),2) "MAXMEM (MB)",
       sa.sql_text "QUERY TEXT (First 1000 chars)"
  from gv$session s, gv$sqlarea sa, gv$process p, gv$px_session ps
 where ps.sid = s.sid
   and ps.inst_id = s.inst_id
   and s.paddr = p.addr
   and s.inst_id = p.inst_id
   and s.sql_id = sa.sql_id (+)
   and s.inst_id = sa.inst_id (+)
 group by sysdate, ps.qcsid, nvl(ps.qcinst_id, ps.inst_id), s.sql_id, ps.inst_id, sa.sql_text
having sum(PGA_ALLOC_MEM) > 1024 * 1024 * 1024
 order by ps.inst_id, sum(PGA_ALLOC_MEM);

-- Collect PGA Usage categorization info for queries who allocates more than 100MB for a specific category on an instance
select sysdate current_time,
       ps.qcsid, nvl(ps.qcinst_id, ps.inst_id) qc_instid, s.sql_id, ps.inst_id "SLAVE INSTANCE", count(*) "PROCESS COUNT", pm.CATEGORY,
       round(sum(pm.ALLOCATED)/(1024*1024),2) "ALLOCATED (MB)",
       round(sum(pm.USED)/(1024*1024),2) "USED (MB)",
       round(sum(pm.MAX_ALLOCATED)/(1024*1024),2) "MAX ALLOCATED (MB)",
       sa.sql_text "QUERY TEXT (First 1000 chars)"
  from gv$process_memory pm, gv$session s, gv$sqlarea sa, gv$process p, gv$px_session ps
 where ps.sid = s.sid
   and ps.inst_id = s.inst_id
   and s.paddr = p.addr
   and s.inst_id = p.inst_id
   and p.pid = pm.pid
   and p.inst_id = pm.inst_id
   and s.sql_id = sa.sql_id (+)
   and s.inst_id = sa.inst_id (+)
 group by sysdate, ps.qcsid, nvl(ps.qcinst_id, ps.inst_id), s.sql_id, ps.inst_id, pm.CATEGORY, sa.sql_text
having sum(pm.ALLOCATED) > 100 * 1024 * 1024
 order by ps.inst_id, sum(pm.ALLOCATED);

-- Collect SQL Workarea Usage info for quries who allocated more than 50MB workarea for a specific operation on an instance
select sysdate current_time,
       ps.qcsid, nvl(ps.qcinst_id, ps.inst_id) qc_instid,
       s.sid, s.sql_id, ps.inst_id "SLAVE INSTANCE",
       round(swa.WORK_AREA_SIZE/(1024*1024),2) "WORK_AREA_SIZE (MB)",
       round(swa.EXPECTED_SIZE/(1024*1024),2) "EXPECTED_SIZE (MB)",
       round(swa.ACTUAL_MEM_USED/(1024*1024),2) "ACTUAL_MEM_USED (MB)",
       round(swa.MAX_MEM_USED/(1024*1024),2) "MAX_MEM_USED (MB)",
       swa.NUMBER_PASSES,
       round(swa.TEMPSEG_SIZE/(1024*1024),2) "TEMPSEG_SIZE (MB)",
       swa.OPERATION_ID, swa.OPERATION_TYPE, sp.operation || ' ' || sp.options || ' ' || sp.object_name "OPERATION NAME",
       sa.sql_text "QUERY TEXT (First 1000 chars)"
  from gv$sql_workarea_active swa, gv$sqlarea sa, gv$session s, gv$process p, gv$px_session ps, gv$sql_plan sp
 where ps.sid = s.sid
   and ps.inst_id = s.inst_id
   and s.paddr = p.addr
   and s.inst_id = p.inst_id
   and swa.sid = s.sid
   and swa.inst_id = s.inst_id
   and s.sql_id = sa.sql_id (+)
   and s.inst_id = sa.inst_id
   and swa.OPERATION_ID = sp.id
   and swa.inst_id = sp.inst_id
   and s.SQL_CHILD_NUMBER = sp.CHILD_NUMBER
   and s.sql_hash_value = sp.hash_value
   and s.inst_id = sp.inst_id
   and swa.WORK_AREA_SIZE > 50 * 1024 * 1024
 order by ps.inst_id, ps.qcsid, qc_instid, swa.WORK_AREA_SIZE;

