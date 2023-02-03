
/* undo istatistikleri */
select * from gv$undostat

select * from gv$sql where sql_id='5jb3tzwkgs50q'

select * from gv$sql where sql_id in (select distinct maxqueryid from gv$undostat where maxqueryid is not null)

/* aktif undo bloklarýna ait özet bilgiler */
select TABLESPACE_NAME,OWNER,SEGMENT_NAME,sum(bytes)/(1024*1024*1024) GB from dba_undo_extents 
where status ='ACTIVE'
group by TABLESPACE_NAME,OWNER,SEGMENT_NAME


/* undo kullanan sql'lere ait bilgiler */
SELECT	 A.NAME,
		 C.SID, C.SERIAL#,
		 C.USERNAME, d.sql_id,d.executions,round(d.ELAPSED_TIME/d.executions,2) et_per_ex, round((d.ROWS_PROCESSED/d.executions),2) rows_per_ex, D.SQL_TEXT
	FROM V$ROLLNAME A, V$SESSION C, v$sqlarea /*V$SQLTEXT*/ D, V$TRANSACTION E
   WHERE A.USN =  E.XIDUSN
	 AND C.TADDR = E.ADDR
	 AND C.SQL_ADDRESS = D.ADDRESS
	 AND C.SQL_HASH_VALUE = D.HASH_VALUE
--	 AND A.NAME = '_SYSSMU30$'
--	 and lower(d.sql_text) not like 'select %'
ORDER BY A.NAME, C.SID,d.sql_id;

v$sqlarea