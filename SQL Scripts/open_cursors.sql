rem -----------------------------------------------------------------------
rem Filename:   cursors.sql
rem Purpose:    Track database cursor usage
rem Date:       29-Nov-2002
rem Author:     Frank Naude, Oracle FAQ
rem -----------------------------------------------------------------------

SET linesize 120

prompt OPEN CURSOR LIMIT
col VALUE format a30 head "Open Cursors Parameter Value"

SELECT VALUE
FROM   sys.v_$parameter
WHERE  NAME = 'open_cursors';

prompt SUMMARY OF CURRENT Curor USAGE
col NAME format a25

SELECT MIN(VALUE) MIN, MAX(VALUE) MAX, AVG(VALUE) AVG
FROM   sys.v_$sesstat
WHERE  statistic# = (SELECT statistic#
                       FROM sys.v_$statname
                      WHERE NAME LIKE 'opened cursors current');

prompt Top 10 Users WITH Most OPEN Cursors
col program  format a15 TRUNC
--col machine a15 TRUNC
col osuser   format a15 TRUNC
col username format a15 TRUNC


SELECT * FROM (
  SELECT s.SID, s.username, s.osuser, s.program, v.VALUE "Open
Cursors"
  FROM   sys.v_$sesstat v,  sys.v_$session s
  WHERE  v.SID        = s.SID
    AND  v.statistic# = (SELECT statistic#
                       FROM sys.v_$statname
                      WHERE NAME LIKE 'opened cursors current')
  ORDER  BY v.VALUE DESC
)
WHERE ROWNUM < 11;