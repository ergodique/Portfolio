rem -----------------------------------------------------------------------
rem Filename:  ctlimits.sql
rem Purpose:   List control file structures with usage limits
rem Date:      21-Sep-2000
rem Author:    Frank Naude, Oracle FAQ
rem -----------------------------------------------------------------------

SET pages 50000
col PCT_USED format 990.09

-- Controlfile creation parameters:
-- Type DATAFILE    is for MAXDATAFILES
-- Type REDO LOG    is for MAXLOGFILES
-- Type LOG HISTORY is for MAXLOGHISTORY
-- Type REDO THREAD is for MAXINSTANCES
-- No entry for MAXLOGMEMBERS (?)

SELECT TYPE, records_used, records_total,
       records_used/records_total*100 "PCT_USED"
FROM   sys.v_$controlfile_record_section