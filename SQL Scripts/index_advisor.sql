BEGIN
  l_sql := 'SELECT * from CUST.KYP_CBTEEXPOSUREISBANK';

  l_sql_tune_task_id := DBMS_SQLTUNE.create_tuning_task (
                          sql_text    => l_sql,
                          bind_list   => sql_binds(anydata.ConvertNumber(100)),
                          user_name   => 'COMMON',
                          scope       => DBMS_SQLTUNE.scope_comprehensive,
                          time_limit  => 60,
                          task_name   => 'serdar_tuning_task',
                          description => 'serdar_tuning_task query.');
  DBMS_OUTPUT.put_line('l_sql_tune_task_id: ' || l_sql_tune_task_id);
END;
/



SELECT owner, task_name, status,EXECUTION_START,EXECUTION_END FROM dba_advisor_log order by EXECUTION_START desc;


EXEC DBMS_SQLTUNE.execute_tuning_task(task_name => 'serdar_tuning_task');

-- Interrupt and resume a tuning task.
EXEC DBMS_SQLTUNE.interrupt_tuning_task (task_name => 'emp_dept_tuning_task');
EXEC DBMS_SQLTUNE.resume_tuning_task (task_name => 'emp_dept_tuning_task');

-- Cancel a tuning task.
EXEC DBMS_SQLTUNE.cancel_tuning_task (task_name => 'emp_dept_tuning_task');

-- Reset a tuning task allowing it to be re-executed.
EXEC DBMS_SQLTUNE.reset_tuning_task (task_name => 'emp_dept_tuning_task');

SELECT DBMS_SQLTUNE.report_tuning_task('serdar_tuning_task') AS recommendations FROM dual;
