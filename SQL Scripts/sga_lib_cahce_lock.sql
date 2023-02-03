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
REM 	s_sga_lib_cache_lock.sql
REM
REM <SQLDIR_GRP>SGA LOCK MOST</SQLDIR_GRP>
REM 
REM Author:
REM 	Vitaliy Mogilevskiy 
REM	VMOGILEV
REM	(vit100gain@earthlink.net)
REM 
REM Purpose:
REM	<SQLDIR_TXT>
REM	Reports library cache locks.  Many times in heavy development
REM	environment PL/SQL code get's compiled while someone else is 
REM	using it.  This creates locks in library cache which can be 
REM	very hard to trace.   I would typically check v$session_wait 
REM	to see if there	are any waits for "enque", most of the time it's 
REM	library	cache lock especially when other locks are not present.
REM	--
REM	The next step would be to find out which package waiting
REM	session was trying to compile or execute and run this script
REM	supplying this package name.  When you get the output of this
REM	script you can kill sessions that are causing library cache lock.
REM	</SQLDIR_TXT>
REM	
REM Usage:
REM	s_sga_lib_cache_lock.sql
REM 
REM Example:
REM	s_sga_lib_cache_lock.sql
REM
REM
REM History:
REM	08-01-2001	VMOGILEV	Created (based on Metalink's article)
REM
REM

SELECT a.KGLPNMOD, a.KGLPNREQ, b.sid, b.serial#, b.username, c.KGLNAOBJ, c.KGLOBTYP
 FROM 
      sys.x$kglpn a,
     v$session b,
      sys.x$kglob c
 WHERE
  a.KGLPNUSE = b.saddr and
  upper(c.KGLNAOBJ)  like upper('%&package_that_is_locked%') and
  a.KGLPNHDL = c.KGLHDADR;
