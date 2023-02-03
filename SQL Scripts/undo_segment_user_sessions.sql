SET echo OFF
SET feedback OFF
SET linesize 512

prompt
prompt ROLLBACK SEGMENT Activity IN DATABASE
prompt

SELECT	 A.NAME, B.XACTS,
		 C.SID, C.SERIAL#,
		 C.USERNAME, D.PIECE,D.SQL_TEXT
	FROM V$ROLLNAME A, V$ROLLSTAT B, V$SESSION C, V$SQLTEXT D, V$TRANSACTION E
   WHERE A.USN = B.USN
	 AND B.USN = E.XIDUSN
	 AND C.TADDR = E.ADDR
	 AND C.SQL_ADDRESS = D.ADDRESS
	 AND C.SQL_HASH_VALUE = D.HASH_VALUE
ORDER BY A.NAME, C.SID, D.PIECE;

/* Formatted on 2005/04/29 12:15 (Formatter Plus v4.8.5) */
SELECT   a.tablespace_name, a.segment_name, a.status, SUM (BYTES) / 1024 / 1024 / 1024 sum_gb
    FROM dba_undo_extents a
   WHERE a.segment_name IN (SELECT A.NAME
	FROM V$ROLLNAME A, V$ROLLSTAT B, V$SESSION C, V$SQLTEXT D, V$TRANSACTION E
   WHERE A.USN = B.USN
	 AND B.USN = E.XIDUSN
	 AND C.TADDR = E.ADDR
	 AND C.SQL_ADDRESS = D.ADDRESS
	 AND C.SQL_HASH_VALUE = D.HASH_VALUE)
GROUP BY a.tablespace_name, a.segment_name,a.status