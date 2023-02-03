rem -----------------------------------------------------------------------
rem Filename:   uptime.sql
rem Purpose:    Display database uptime in days and hours
rem             to SYS or SYSTEM
rem Date:       12-Jan-2000
rem Author:     Frank Naude, Oracle FAQ
rem -----------------------------------------------------------------------

SELECT SYSDATE-logon_time "Days", (SYSDATE-logon_time)*24 "Hours"
FROM   sys.v_$session
WHERE  program LIKE '%(PMON)'
