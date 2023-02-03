
REM  Filename:  hardparse10g.sql
REM
REM  You can modify the 'where executions<3' higher 
REM  or lower to increase or decrease the number of
REM  rows back in the query
REM

set pages 10000
set lines 100
set long 500000000
set termout off
set trimout on
set trimspool on

col inst_id format 999999 head "Id"
col hash_value head "Hash"
col module format a15 head "Module"
col sql_fulltext format a30 word_wrapped "SQL"

spool /tmp/literals.out
    
select inst_id,hash_value,module,SQL_FULLTEXT
from gv$sql
where executions<3
order by SQL_TEXT;
spool off
set termout on
set trimout off
set trimspool off

/*---------------------------------------------

Sample Output:

     Id   Hash              Module                SQL
-------  ------------------ ---------------------- --------------------------------------------------------------------------
      1   4126766040 sqlplus@rtcsol1 ALTER SESSION SET TIME_ZONE='+00:00'
                                   (TNS V1-V3)

      1   2219546185                              select action# from trigger$ where obj# = :1
      1   1468360593                              select actionsize from trigger$ where obj# = :1
      1   1052990557                              select
                                                                baseobject,type#,update$,insert$,delete$,refnewnam
                                                                e,refoldname,whenclause,definition,enabled,propert
                                                                y,sys_evts,nttrigcol,nttrigatt,refprtname,rowid
                                                                from trigger$ where obj# =:1

*/
