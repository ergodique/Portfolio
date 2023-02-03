
##############################################################################################################################################
##############################################################################################################################################

=====================================
== SPM: FIX GOOD PLAN FROM MEMORY
=====================================

-------------------------------------------
-- Duzgun planin oldugu node:
-------------------------------------------
declare
result number;
begin
result := dbms_spm.load_plans_from_cursor_cache (sql_id =>'gj15httjj4qfz',PLAN_HASH_VALUE=>3184971025);
end;
/

-------------------------------------------
-- Check baseline:
-------------------------------------------
select sql_handle, plan_name, enabled, accepted, fixed, created, sql_text from dba_sql_plan_baselines order by created desc

-------------------------------------------
-- Fix
-------------------------------------------
var my_var number
exec :my_var := dbms_spm.alter_sql_plan_baseline (sql_handle => 'SYS_SQL_a3d66bbeeb5cc997', plan_name => 'SYS_SQL_PLAN_eb5cc997c6f5e473', attribute_name => 'FIXED', attribute_value => 'YES');

-------------------------------------------
-- Auto-purge = NO
-------------------------------------------
SET SERVEROUTPUT ON
DECLARE
  l_plans_altered  PLS_INTEGER;
BEGIN
  l_plans_altered := DBMS_SPM.alter_sql_plan_baseline(
    sql_handle      => 'SYS_SQL_a3d66bbeeb5cc997',
    plan_name       => 'SYS_SQL_PLAN_eb5cc997c6f5e473',
    attribute_name  => 'autopurge',
    attribute_value => 'NO');

  DBMS_OUTPUT.put_line('Plans Altered: ' || l_plans_altered);
END;
/

----------------------------------------    
-- Drop auto-capture plans (if any)
----------------------------------------
    DECLARE
    my_plans pls_integer;
    BEGIN
    my_plans := DBMS_SPM.DROP_SQL_PLAN_BASELINE (sql_handle => 'SYS_SQL_e4ac28b2dc8937bc',plan_name=>'SYS_SQL_PLAN_dc8937bce421725d');
    END;
    /    

##############################################################################################################################################
##############################################################################################################################################

=====================================
== SPM: FIX GOOD PLAN FROM AWR
=====================================

---------------------------
-- Check AWR
---------------------------
column ela_pexec format 999,999,999.99
column gets_perexec format 999,999,999.99
column rows_pexec format 999,999,999.99

select PLAN_HASH_VALUE, sum(BUFFER_GETS_DELTA)/sum(EXECUTIONS_DELTA) gets_perexec,
       sum(ELAPSED_TIME_DELTA)/sum(EXECUTIONS_DELTA) / 1000000 ela_pexec,
       sum(ROWS_PROCESSED_DELTA)/sum(EXECUTIONS_DELTA) rows_pexec
from dba_hist_sqlstat
where sql_id= '7nvpugctdak68'
and EXECUTIONS_DELTA>0
group by plan_hash_value;

    => find good plan_hash_value

----------------------------------------------------    
-- Find SNAP_ID of good plan in AWR:
----------------------------------------------------
select SNAP_ID from dba_hist_sqlstat where plan_hash_Value=3701613856;

   SNAP_ID
----------
     34434
     34434
     34433
     34433

-----------------------------------------------     
-- Create SQL Tuning Set From AWR:
-----------------------------------------------

7nvpugctdak68 3701613856

SnapId: 34433 - 34434

exec DBMS_SQLTUNE.CREATE_SQLSET('test4');

declare
 baseline_ref_cursor DBMS_SQLTUNE.SQLSET_CURSOR;
 begin
 open baseline_ref_cursor for
 select VALUE(p) from table(DBMS_SQLTUNE.SELECT_WORKLOAD_REPOSITORY(34433, 34434,
 'sql_id='||CHR(39)||'7nvpugctdak68'||CHR(39)||' and plan_hash_value=3701613856',NULL,NULL,NULL,NULL,NULL,NULL,'ALL')) p;
 DBMS_SQLTUNE.LOAD_SQLSET('test4', baseline_ref_cursor);
end;
/

-------------------------------------
-- Check STS
-------------------------------------

-- Verify how many sqls got loaded in the STS.

SELECT NAME,OWNER,CREATED,STATEMENT_COUNT FROM DBA_SQLSET where name='test4';

-- Verify the sql statements and its sql_d in the STS

select sql_id, substr(sql_text,1, 15) text
 from dba_sqlset_statements
 where sqlset_name = 'test4'
 order by sql_id;

-- Verify the execution Plan of a SQL_ID in the STS for a user sql.

SELECT * FROM table (
 DBMS_XPLAN.DISPLAY_SQLSET(
 'test4','7nvpugctdak68'));

-- Verify the Plan baseline to check how many plans before.

select count(*) from dba_sql_plan_baselines;

------------------------------------------
-- Load Execution Plan From The STS:
------------------------------------------

set serveroutput on
declare
 my_integer pls_integer;
begin
 my_integer := dbms_spm.load_plans_from_sqlset (
 sqlset_name => 'test4',
 sqlset_owner => 'SYS',
 fixed => 'NO',
 enabled => 'YES');
 DBMS_OUTPUT.PUT_line(my_integer);
end;
/

-------------------------------------------
-- Check SQL Plan Baseline:
-------------------------------------------

select sql_handle, plan_name, enabled, accepted, fixed, created, sql_text from dba_sql_plan_baselines order by created desc

---------------------
-- Fix
---------------------
var my_var number
exec :my_var := dbms_spm.alter_sql_plan_baseline (sql_handle => 'SYS_SQL_a3d66bbeeb5cc997', plan_name => 'SYS_SQL_PLAN_eb5cc997c6f5e473', attribute_name => 'FIXED', attribute_value => 'YES');

---------------------
-- Auto-purge = NO
---------------------
SET SERVEROUTPUT ON
DECLARE
  l_plans_altered  PLS_INTEGER;
BEGIN
  l_plans_altered := DBMS_SPM.alter_sql_plan_baseline(
    sql_handle      => 'SYS_SQL_a3d66bbeeb5cc997',
    plan_name       => 'SYS_SQL_PLAN_eb5cc997c6f5e473',
    attribute_name  => 'autopurge',
    attribute_value => 'NO');

  DBMS_OUTPUT.put_line('Plans Altered: ' || l_plans_altered);
END;
/

----------------------------------------    
-- Drop auto-capture plans (if any)
----------------------------------------
    DECLARE
    my_plans pls_integer;
    BEGIN
    my_plans := DBMS_SPM.DROP_SQL_PLAN_BASELINE (sql_handle => 'SYS_SQL_e4ac28b2dc8937bc',plan_name=>'SYS_SQL_PLAN_dc8937bce421725d');
    END;
    /    
    
##############################################################################################################################################
##############################################################################################################################################

=================================
== SPM: FIX HINTED
=================================

---------------------------------------
-- Load original plan
---------------------------------------
var v_num number;
exec :v_num:=dbms_spm.load_plans_from_cursor_cache(sql_id => 'ORIG_SQLID',plan_hash_value => ORIG_PLANHASH );

---------------------------------------
-- Check Baseline
---------------------------------------
select sql_handle, plan_name, enabled, accepted, fixed, created, sql_text from dba_sql_plan_baselines order by created desc

    SYS_SQL_50969e88fdd635aa       SQL_PLAN_515nyj3yxcddada00620d YES YES

---------------------------------------    
-- Link: Hinted - Orig:
---------------------------------------
    dbms_spm.load_plans_from_cursor_cache(sql_id => 'HINTED_SQLID',plan_hash_value=>HINTED_PLANHASH,sql_handle=>'SQL_HANDLE_ORIG')

---------------------------------------    
-- Check Baseline
---------------------------------------
    
    select sql_handle, plan_name, enabled, accepted, fixed, created, sql_text from dba_sql_plan_baselines order by created desc

        ORJINAL_SQL_TEXT         SYS_SQL_50969e88fdd635aa       SQL_PLAN_515nyj3yxcddada00620d YES YES
        ORJINAL_SQL_TEXT         SYS_SQL_50969e88fdd635aa       SQL_PLAN_515nyj3yxcdda041dae64 YES YES ==>> istedigimiz connection...

----------------------------------------        
-- Fix (hinted plan)
----------------------------------------
    var my_var number
    exec :my_var := dbms_spm.alter_sql_plan_baseline (sql_handle => 'SYS_SQL_50969e88fdd635aa', plan_name => 'SQL_PLAN_515nyj3yxcdda041dae64', attribute_name => 'FIXED', attribute_value => 'YES');
    
----------------------------------------    
-- Set AUTO PURGE = NO (hinted plan)
----------------------------------------
    var my_var number
    exec :my_var := dbms_spm.alter_sql_plan_baseline (sql_handle => 'SYS_SQL_50969e88fdd635aa', plan_name => 'SQL_PLAN_515nyj3yxcdda041dae64', attribute_name => 'autopurge', attribute_value => 'NO');

----------------------------------------    
-- Drop original plan from SPM:
----------------------------------------

    DECLARE
    my_plans pls_integer;
    BEGIN
    my_plans := DBMS_SPM.DROP_SQL_PLAN_BASELINE (sql_handle => 'SYS_SQL_50969e88fdd635aa',plan_name=>'SQL_PLAN_515nyj3yxcddada00620d');
    END;
    /

----------------------------------------    
-- Drop auto-capture plans (if any)
----------------------------------------
    DECLARE
    my_plans pls_integer;
    BEGIN
    my_plans := DBMS_SPM.DROP_SQL_PLAN_BASELINE (sql_handle => 'SYS_SQL_e4ac28b2dc8937bc',plan_name=>'SYS_SQL_PLAN_dc8937bce421725d');
    END;
    /    

##############################################################################################################################################
##############################################################################################################################################    