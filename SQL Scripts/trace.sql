conn usrSINERJIWPS/usrwpsprd@dwprd
var PIID varchar2(78);
var MSGTYPE number;
exec :piid := '_PI:90030117.3accfb4e.c2e1adf5.32d3087d';
exec :msgtype := 2;
set autotr trace stat exp
SELECT XMLDATA FROM SINERJIWPS.PROCESSINSTANCEDATA WHERE PIID = :PIID AND MESSAGETYPEID = :MSGTYPE;
set autotr off
alter session set tracefile_identifier='SINERJIWPS'; 
alter session set timed_statistics = true;
alter session set statistics_level=all;
alter session set max_dump_file_size = unlimited;
alter session set events '10046 trace name context forever,level 12';
SELECT XMLDATA FROM SINERJIWPS.PROCESSINSTANCEDATA WHERE PIID = :PIID AND MESSAGETYPEID = :MSGTYPE;
alter session set events '10046 trace name context off';
exit
