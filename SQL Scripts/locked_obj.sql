REM
REM DBAToolZ NOTE:
REM	This script was obtained from DBAToolZ.com
REM	It's configured to work with SQL Directory (SQLDIR).
REM	SQLDIR is a utility that allows easy organization and
REM	execution of SQL*Plus scripts using user-friendly menu.
REM	Visit DBAToolZ.com for more details and free SQL scripts.
REM
REM 
REM File:
REM 	s_locked_obj.sql
REM
REM <SQLDIR_GRP>USER LOCK TRACE MOST</SQLDIR_GRP>
REM 
REM Author:
REM 	Vitaliy Mogilevskiy 
REM	VMOGILEV
REM	(vit100gain@earthlink.net)
REM 
REM Purpose:
REM	<SQLDIR_TXT>
REM	            *** QUICK ***
REM	Reports the following:
REM	-  object locks from V$LOCKED_OBJECT
REM	   using PL/SQL loops since join of DBA_OBJECTS
REM	   and V$LOCKED_OBJECT is extremly slow
REM	- blocked objects from V$LOCK and SYS.OBJ$
REM	- blocked sessions from V$LOCK
REM	</SQLDIR_TXT>
REM	
REM Usage:
REM	s_locked_obj.sql
REM 
REM Example:
REM	s_locked_obj.sql
REM
REM
REM History:
REM	08-01-1998	VMOGILEV	Created
REM	12-18-2001	VMOGILEV	added V$LOCK queries to ID blockers
REM
REM

set verify off
set serveroutput on size 1000000   
DECLARE   
   CURSOR lcobj_cur IS
      select session_id
      ,      oracle_username
      ,      os_user_name
      ,      object_id obj_id
      ,      locked_mode
      from   V$LOCKED_OBJECT ;
      
   CURSOR obj_cur(p_obj_id IN NUMBER) IS
      select owner||'.'||object_name object_name
      ,      object_type
      from dba_objects
      where object_id = p_obj_id;
BEGIN
   DBMS_OUTPUT.PUT_LINE(RPAD('Sid',5)||
                        RPAD('O-User',10)||
                        RPAD('OS-User',10)||
                        RPAD('Owner.Object Name',45)||
                        RPAD('Object Type',35));

   DBMS_OUTPUT.PUT_LINE(RPAD('-',1,'-')||
                        RPAD('-',6,'-')||
                        RPAD('-',6,'-')||
                        RPAD('-',41,'-')||
                        RPAD('-',31,'-'));

   FOR lcobj IN lcobj_cur
   LOOP
      FOR obj IN obj_cur(lcobj.obj_id)
      LOOP
         DBMS_OUTPUT.PUT_LINE(RPAD(lcobj.session_id,5)||
                              RPAD(lcobj.oracle_username,10)||
                              RPAD(lcobj.os_user_name,10)||
                              RPAD(obj.object_name,45)||
                              RPAD(obj.object_type,35));
      END LOOP;
   END LOOP;
END;
/

prompt blocked objects from V$LOCK and SYS.OBJ$

set lines 132
col BLOCKED_OBJ format a35 trunc

select /*+ ORDERED */
    l.sid 
,   l.lmode
,   TRUNC(l.ctime/60) min_blocked
,   u.name||'.'||o.NAME blocked_obj 
from (select *
      from v$lock
      where type='TM'
      and sid in (select sid 
                  from v$lock
                  where block!=0)) l
,     sys.obj$ o
,     sys.user$ u  
where o.obj# = l.ID1
and   o.OWNER# = u.user#
/


prompt blocked sessions from V$LOCK

select /*+ ORDERED */
   blocker.sid blocker_sid
,  blocked.sid blocked_sid
,  TRUNC(blocked.ctime/60) min_blocked
,  blocked.request
from (select *
      from v$lock
      where block != 0
      and type = 'TX') blocker
,    v$lock        blocked
where blocked.type='TX' 
and blocked.block = 0
and blocked.id1 = blocker.id1
/

prompt blokers session details from V$SESSION

set lines 132
col username format a10 trunc
col osuser format a12 trunc
col machine format a15 trunc
col process format a15 trunc
col action format a50 trunc

SELECT sid
,      serial#
,      username
,      osuser
,      machine
,      process
,      module||' '||action action
FROM v$session
WHERE sid IN (select sid
      from v$lock
      where block != 0
      and type = 'TX')
