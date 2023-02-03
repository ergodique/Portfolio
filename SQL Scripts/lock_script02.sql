select i.instance_name db_instance,
	   osuser,
	   p.spid server_pid,
	   s.username username,
	   s.sid sid,
	   s.serial# serial#,
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
		s.machine,
	' ' object_name,
	decode(lmode,1,Null,2,'Row Share',3,'Row Excl',4,'Share',
		5,'Sh Row Ex',6,'Exclusive',' ') held,
	decode(request,1,Null,2,'Row Share',3,'Row Excl',4,'Share',
		5,'Sh Row Ex',6,'Exclusive',' ') request
	from v$lock l, v$session s, v$process p,v$instance i
	where s.sid = l.sid and
		s.username <> ' ' and
		s.paddr = p.addr and
		l.type <> 'TM'
		and (l.type <> 'TX' or l.type = 'TX' and l.lmode <> 6)
union all
select i.instance_name db_instance,
	    osuser,
	   p.spid server_pid,
	   s.username username,
	   s.sid sid,
	   s.serial# serial#,
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
		s.machine,
	owner||'.'||object_name object_name,
	decode(lmode,1,NULL,2,'Row Share',3,'Row Excl',4,'Share',
		5,'Sh Row Ex',6,'Exclusive',NULL) held,
	decode(request,1,NULL,2,'Row Share',3,'Row Excl',4,'Share',
		5,'Sh Row Ex',6,'Exclusive',NULL) request
	from v$lock l, v$session s, v$process p, sys.dba_objects o,v$instance i
	where s.sid = l.sid and
		o.object_id = l.id1 and
		l.type = 'TM' and
		s.username <> ' ' and
		s.paddr = p.addr
union all
select i.instance_name db_instance,
	   osuser,
	   p.spid server_pid,
	   s.username username,
	   s.sid sid,
	   s.serial# serial#,
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
		s.machine,
	'(Rollback='||rtrim(r.name)||')' object_name,
	decode(lmode,1,NULL,2,'Row Share',3,'Row Excl',4,'Share',
		5,'Sh Row Ex',6,'Exclusive',NULL) held,
	decode(request,1,NULL,2,'Row Share',3,'Row Excl',4,'Share',
		5,'Sh Row Ex',6,'Exclusive',NULL) request
	from v$lock l, v$session s, v$process p, v$rollname r,v$instance i
	where s.sid = l.sid and
		l.type = 'TX' and
		l.lmode = 6 and
		trunc(l.id1/65536) = r.usn and
		s.username <> ' ' and
		s.paddr = p.addr
	order by 5, 6; 