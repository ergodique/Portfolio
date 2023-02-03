set pagesize 0
set markup html on spool on entmap off -
	head '-
	<style type="text/css"> -
	   table { background: #eee; font-size: 80%;} -
	   th { background: #ccc; } -
	   td { padding: 0px; } -
	</style>' -
	body 'text=black bgcolor=fffffff' -
	table 'width=50%; border=1; bordercolor=blue; bgcolor=white; text-align: center;'
set feedback off
SELECT '<center><b>Son iki full backup� hatal� olan Oracle Veritabanlar�</b></center>' FROM DUAL;
WITH data
     AS (SELECT '<center><b>Veritaban�</b></center>',
                '<center><b>Son Ba�ar�l� Full Backup Zaman�</b></center>'
           FROM DUAL
         UNION ALL
         SELECT '<center>' || DB_NAME || '</center>' "Veritaban�",
                   '<center>'
                || TO_CHAR (LAST_SUCCESSFUL, 'dd.mm.rrrr')
                || '</center>'
                   "Son Ba�ar�l� Backup Zaman�"
           FROM TABLE (backup.twotimes_failed_full_bkp('TEST')))
SELECT * FROM data
UNION ALL
SELECT '-', '-'
  FROM DUAL
 WHERE 1 = (SELECT COUNT (*) FROM data);

SELECT '<center><b>Bir haftad�r hi� backup g�nderilmemi� Oracle Veritabanlar�</b></center>' FROM DUAL;

WITH data
     AS  (SELECT '<center>' || db_name || '</center>' as "Veritaban�"
FROM (SELECT DECODE (a.rac_enabled,
             0, a.db_name,
             1, a.management_instance_name
             ) db_name
      FROM isbdba.databases a, isbdba.oracle_control_mapping b
       WHERE a.ID = b.db_id AND b.backup = 1 AND lvl <> 'PROD'
MINUS
   SELECT DISTINCT db_name
   FROM BACKUP.oracle_backup_logs
   WHERE env <> 'PROD' and start_time > SYSDATE - 7)
ORDER BY 1) 
SELECT * FROM data
UNION ALL
SELECT '<center> Backup g�nderilmemi� veritaban� bulunmamaktad�r. </center>'
FROM DUAL
WHERE NOT EXISTS (SELECT NULL FROM data);


SELECT '<center><b>�ki g�nd�r ARCHIVELOG backup� ba�ar�l� bitmemi� Oracle Veritabanlar�</b></center>' FROM DUAL;

WITH data
     AS (SELECT '<center>' || db_name || '</center>' AS "Veritaban�"
           FROM (SELECT decode(a.rac_enabled,0,a.db_name,1,a.management_instance_name) db_name
                   FROM ISBDBA.DATABASES a, isbdba.oracle_control_mapping b
         WHERE a.ID = b.db_id
           AND b.backup = 1
	   AND a.LVL <> 'PROD'
                 MINUS
           SELECT DISTINCT db_name
           FROM backup.oracle_backup_logs
           WHERE env <> 'PROD' and backup_type IN ('ARC', 'ARC2')
                        AND START_TIME > TO_DATE (SYSDATE - 2,'dd.mm.rrrr hh24:mi:ss')
                        AND return_code = 0))
SELECT * FROM data
UNION ALL
SELECT '<center> T�m ortamlar�n archivelog backuplar� al�nmaktad�r. </center>'
  FROM DUAL
 WHERE NOT EXISTS (SELECT NULL FROM data);



SELECT '<center><b>Bir ayd�r DO backup� ba�ar�l� bitmemi� Oracle Veritabanlar�</b></center>' FROM DUAL;

WITH data
     AS (SELECT '<center>' || db_name || '</center>' AS "Veritaban�"
           FROM (SELECT decode(a.rac_enabled,0,a.db_name,1,a.management_instance_name) db_name
                   FROM ISBDBA.DATABASES a, isbdba.oracle_control_mapping b
         WHERE a.ID = b.db_id
           AND b.backup = 1
           AND a.LVL <> 'PROD'
                 MINUS
                 SELECT DISTINCT db_name
                   FROM backup.oracle_backup_logs
                  WHERE   env <> 'PROD' and  backup_type IN ('DO', 'CLSADO')
                        AND START_TIME > TO_DATE (SYSDATE - 30,'dd.mm.rrrr hh24:mi:ss')
                        AND return_code = 0))
SELECT * FROM data
UNION ALL
SELECT '<center> T�m ortamlarda delete obsolete backup �al��maktad�r. </center>'
  FROM DUAL
 WHERE NOT EXISTS (SELECT NULL FROM data);


SELECT '<center><b>�� g�nd�r HEADER backup� al�namayan Oracle Veritabanlar�</b></center>' FROM DUAL;

WITH data
     AS (SELECT '<center>' || db_name || '</center>' AS "Veritaban�"
           FROM (SELECT decode(a.rac_enabled,0,a.db_name,1,a.management_instance_name) db_name
                   FROM isbdba.databases a, isbdba.oracle_control_mapping b
         WHERE a.ID = b.db_id
           AND b.headerbackup = 1 and a.lvl <> 'PROD'
                 MINUS
                 SELECT DISTINCT db_name
                   FROM backup.header_backup_logs
                  WHERE env <> 'PROD' and  start_time >
                               TO_DATE (SYSDATE - 3, 'dd.mm.rrrr hh24:mi:ss')
                        AND status = 1))
SELECT * FROM data
UNION ALL
SELECT '<center> T�m ortamlar�n header backuplar� al�nmaktad�r. </center>'
FROM DUAL
WHERE NOT EXISTS (SELECT NULL FROM data);

exit;
