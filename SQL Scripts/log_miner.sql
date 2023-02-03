rem -----------------------------------------------------------------------
rem Filename:   logmgr.sql
rem Purpose:    Log Miner: extract undo statements from online and archived
rem             redo log files based on selection criteria.
rem Date:       21-Sep-2000
rem Author:     Frank Naude, Oracle FAQ
rem -----------------------------------------------------------------------

-- Create a dictionary file 
--   (init.ora parameter utl_file_dir must be set)
EXEC dbms_logmnr_d.BUILD('mydictfile', '/tmp');

-- Register log files, can be from a different db
--   (NEWFILE=start new list/ ADDFILE=add next file)
EXEC dbms_logmnr.add_logfile(
	LogFileName =>
'/app/oracle/arch/oradba/log_1_0000000027.oradba', 
	Options     => dbms_logmnr.NEW);
EXEC dbms_logmnr.add_logfile(
	LogFileName =>
'/app/oracle/arch/oradba/log_1_0000000028.oradba', 
	Options     => dbms_logmnr.ADDFILE);

-- Start the logminer session
EXEC dbms_logmnr.start_logmnr(DictFileName => '/tmp/mydictfile');

-- Query v_$logmnr_contents view to extract required info
SELECT TIMESTAMP, sql_undo
FROM   sys.v_$logmnr_contents
WHERE  seg_name = 'EMPLOYEES';

-- Stop the logminer session
exec dbms_logmnr.end_logmnr;