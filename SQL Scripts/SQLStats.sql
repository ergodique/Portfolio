
REM  Filename:  SQLStats.sql
REM
REM  SQL Area Statistics
REM
REM   runs on 8i/9i/9.2/10g/11g

set serveroutput on;
declare
   MaxInv   number(15);
   MaxVers  number(11);
   MaxVCNT  number(15);
   MaxShare number(15);

   cursor code is select max(invalidations), max(loaded_versions), max(version_count), 
                         max(sharable_mem) from v$sqlarea;

begin
   open code;
   fetch code into MaxInv, MaxVers, MaxVCNT, MaxShare;

   dbms_output.put_line('====================================');
   dbms_output.put_line('HWM Information:');
   dbms_output.put_line('----- Max Invalidations:      '||to_char(MaxInv,'999,999,999,999'));
   dbms_output.put_line('----- Max Versions Loaded:        '||to_char(MaxVers,'999,999,999'));
   dbms_output.put_line('----- Versions HWM:           '||to_char(MaxVCNT,'999,999,999,999'));
   dbms_output.put_line('----- Largest Memory object:  '||to_char(MaxShare,'999,999,999,999'));
   dbms_output.put_line('====================================');
end;
/
