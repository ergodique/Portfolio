rem -----------------------------------------------------------------------
rem Filename:   rsrc.sql
rem Purpose:    Demonstrate resource manager capabilities (limit CPU,
rem             degree and sessions, available from Oracle 8i)
rem Date:       28-Aug-1998
rem Author:     Frank Naude, Oracle FAQ
rem -----------------------------------------------------------------------

---------------------------------------------------------------------------
-- Create plan with consumer groups
---------------------------------------------------------------------------

EXEC dbms_resource_manager.create_pending_area;

EXEC dbms_resource_manager.delete_plan_cascade('night_plan');

EXEC dbms_resource_manager.create_plan('night_plan', 'Plan to use after 6PM');
EXEC dbms_resource_manager.create_consumer_group('batch', 'Group for batch reports');

EXEC dbms_resource_manager.create_plan_directive('night_plan', 'batch', 'Rules for overnight batch jobs', -
                                                 cpu_p1 => 75, parallel_degree_limit_p1 => 20);
EXEC dbms_resource_manager.create_plan_directive('night_plan', 'OTHER_GROUPS', 'Rules for overnight batch jobs', -
                                                 cpu_p1 => 25, parallel_degree_limit_p1 => 0,                    -
                                                 max_active_sess_target_p1 => 1);

EXEC dbms_resource_manager.validate_pending_area;
EXEC dbms_resource_manager.submit_pending_area;

---------------------------------------------------------------------------
-- List plans and consumer groups
---------------------------------------------------------------------------

SET pages 50000
col PLAN  format a12
col status format a7
col cpu_p1 format 999
col cpu_p2 format 999
col cpu_p3 format 999
col group_or_subplan format a17
col parallel_degree_limit_p1 format 999

SELECT PLAN, num_plan_directives, status, mandatory FROM sys.dba_rsrc_plans;

SELECT PLAN, group_or_subplan, cpu_p1, cpu_p2, cpu_p3, parallel_degree_limit_p1 AS PARALLEL, status
FROM   sys.dba_rsrc_plan_directives
ORDER  BY PLAN;

---------------------------------------------------------------------------
-- Switch a user to a new consumer group
---------------------------------------------------------------------------

EXEC dbms_resource_manager_privs.grant_switch_consumer_group('SCOTT', 'batch', FALSE);
EXEC dbms_resource_manager.set_initial_consumer_group('SCOTT', 'batch');

-- exec dbms_resource_manager.switch_consumer_group_for_user('SCOTT', 'batch');   -- Switch on-line users

SELECT username, initial_rsrc_consumer_group FROM sys.dba_users WHERE username = 'SCOTT';

---------------------------------------------------------------------------
-- Enable resource management for this instance
---------------------------------------------------------------------------
ALTER SYSTEM SET resource_manager_plan = 'NIGHT_PLAN';

---------------------------------------------------------------------------
-- Monitor the resource manager
---------------------------------------------------------------------------

col program format a40
SELECT program, resource_consumer_group FROM sys.v_$session WHERE username = 'SCOTT';

-- select * from sys.v_$rsrc_plan;
SELECT * FROM sys.v_$rsrc_consumer_group;
