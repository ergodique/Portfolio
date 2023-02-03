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
REM 	s_db_lock.sql
REM
REM <SQLDIR_GRP>LOCK</SQLDIR_GRP>
REM 
REM Author:
REM 	Brian Lomasky 
REM	BLOMASKY
REM 
REM Purpose:
REM	<SQLDIR_TXT>
REM	Displays DECODEd locking information
REM	(WARNING: slow)
REM	</SQLDIR_TXT>
REM	
REM Usage:
REM	s_db_lock.sql
REM 
REM Example:
REM	s_db_lock.sql
REM
REM
REM History:
REM	12-04-1996	BLOMASKY	Created
REM	08-01-1998	VMOGILEV	Added to DBATOOLZ library
REM
REM

rem $TOOLS/locks.sql
rem
rem Displays locking information for the current ORACLE_SID database
rem
rem Last Change 12/04/96 by Brian Lomasky
rem
set termout off
set heading off
col dbname1 new_value dbname noprint
select name dbname1 from v$database;
set termout on
set heading on
set pagesize 9999
column osuser format a14 heading "-----O/S------|Username   Pid"
column username format a17 heading "-----ORACLE-----|Username  ID  Ser"
column locktype format a10 heading "Type"
column held format a9 heading "Lock Held"
column object_name format a15 heading "Object Name" wrap
column request format a9 heading "  Lock|Requested"
column id1 format 999999
column id2 format 9999
spool locks.lis
ttitle center 'Lock report for the ' &&dbname ' database' skip 2
select rpad(osuser, 9)||lpad(p.spid, 5) osuser,
	rpad(s.username,8)||lpad(s.sid, 4)||lpad(s.serial#, 5) username,
	decode(l.type, 
		'MR', 'Media Reco', 
		'RT', 'Redo Thred',
		'UN', 'User Name',
		'TX', 'Trans',
		'TM', 'DML',
		'UL', 'PL/SQL Usr',
		'DX', 'Dist. Tran',
		'CF', 'Cntrl File',
		'IS', 'Inst State',
		'FS', 'File Set',
		'IR', 'Inst Reco',
		'ST', 'Disk Space',
		'TS', 'Temp Seg',
		'IV', 'Cache Inv',
		'LS', 'Log Switch',
		'RW', 'Row Wait',
		'SQ', 'Seq Number',
		'TE', 'Extend Tbl',
		'TT', 'Temp Table',
		l.type) locktype,
	' ' object_name,
	decode(lmode,1,Null,2,'Row Share',3,'Row Excl',4,'Share',
		5,'Sh Row Ex',6,'Exclusive',' ') held,
	decode(request,1,Null,2,'Row Share',3,'Row Excl',4,'Share',
		5,'Sh Row Ex',6,'Exclusive',' ') request
	from v$lock l, v$session s, v$process p
	where s.sid = l.sid and
		s.username <> ' ' and
		s.paddr = p.addr and
		l.type <> 'TM' and
		(l.type <> 'TX' or l.type = 'TX' and l.lmode <> 6)
union
select rpad(osuser, 9)||lpad(p.spid, 5) osuser,
	rpad(s.username,8)||lpad(s.sid, 4)||lpad(s.serial#, 5) username,
	decode(l.type, 
		'MR', 'Media Reco', 
		'RT', 'Redo Thred',
		'UN', 'User Name',
		'TX', 'Trans',
		'TM', 'DML',
		'UL', 'PL/SQL Usr',
		'DX', 'Dist. Tran',
		'CF', 'Cntrl File',
		'IS', 'Inst State',
		'FS', 'File Set',
		'IR', 'Inst Reco',
		'ST', 'Disk Space',
		'TS', 'Temp Seg',
		'IV', 'Cache Inv',
		'LS', 'Log Switch',
		'RW', 'Row Wait',
		'SQ', 'Seq Number',
		'TE', 'Extend Tbl',
		'TT', 'Temp Table',
		l.type) locktype,
	object_name,
	decode(lmode,1,NULL,2,'Row Share',3,'Row Excl',4,'Share',
		5,'Sh Row Ex',6,'Exclusive',NULL) held,
	decode(request,1,NULL,2,'Row Share',3,'Row Excl',4,'Share',
		5,'Sh Row Ex',6,'Exclusive',NULL) request
	from v$lock l, v$session s, v$process p, sys.dba_objects o
	where s.sid = l.sid and
		o.object_id = l.id1 and
		l.type = 'TM' and
		s.username <> ' ' and
		s.paddr = p.addr
union
select rpad(osuser, 9)||lpad(p.spid, 5) osuser,
	rpad(s.username,8)||lpad(s.sid, 4)||lpad(s.serial#, 5) username,
	decode(l.type, 
		'MR', 'Media Reco', 
		'RT', 'Redo Thred',
		'UN', 'User Name',
		'TX', 'Trans',
		'TM', 'DML',
		'UL', 'PL/SQL Usr',
		'DX', 'Dist. Tran',
		'CF', 'Cntrl File',
		'IS', 'Inst State',
		'FS', 'File Set',
		'IR', 'Inst Reco',
		'ST', 'Disk Space',
		'TS', 'Temp Seg',
		'IV', 'Cache Inv',
		'LS', 'Log Switch',
		'RW', 'Row Wait',
		'SQ', 'Seq Number',
		'TE', 'Extend Tbl',
		'TT', 'Temp Table',
		l.type) locktype,
	'(Rollback='||rtrim(r.name)||')' object_name,
	decode(lmode,1,NULL,2,'Row Share',3,'Row Excl',4,'Share',
		5,'Sh Row Ex',6,'Exclusive',NULL) held,
	decode(request,1,NULL,2,'Row Share',3,'Row Excl',4,'Share',
		5,'Sh Row Ex',6,'Exclusive',NULL) request
	from v$lock l, v$session s, v$process p, v$rollname r
	where s.sid = l.sid and
		l.type = 'TX' and
		l.lmode = 6 and
		trunc(l.id1/65536) = r.usn and
		s.username <> ' ' and
		s.paddr = p.addr
	order by 5, 6;
spool off


