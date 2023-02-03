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
SELECT '<center><b>Son iki full backupý hatalý olan Oracle Veritabanlarý</b></center>' FROM DUAL;
WITH data
     AS (SELECT '<center><b>Veritabaný</b></center>',
                '<center><b>Son Baþarýlý Full Backup Zamaný</b></center>'
           FROM DUAL
         UNION ALL
         SELECT '<center>' || DB_NAME || '</center>' "Veritabaný",
                   '<center>'
                || TO_CHAR (LAST_SUCCESSFUL, 'dd.mm.rrrr')
                || '</center>'
                   "Son Baþarýlý Backup Zamaný"
           FROM TABLE (backup.twotimes_failed_full_bkp('PROD')))
SELECT * FROM data
UNION ALL
SELECT '-', '-'
  FROM DUAL
 WHERE 1 = (SELECT COUNT (*) FROM data);

SELECT '<center><b>Bir haftadýr hiç backup gönderilmemiþ Oracle Veritabanlarý</b></center>' FROM DUAL;

WITH data
     AS (  SELECT '<center>' || db_name || '</center>' AS "Veritabaný"
             FROM (SELECT CASE
                             WHEN a.dg_node = 1
                             THEN
                                  a.dg_node_name 
                             ELSE
                                a.db_name
                          END
                             db_name
                     FROM isbdba.databases a, isbdba.oracle_control_mapping b
                    WHERE a.ID = b.db_id AND b.backup = 1 AND lvl = 'PROD'
                   MINUS
                   SELECT DISTINCT db_name
                     FROM BACKUP.oracle_backup_logs
                    WHERE env = 'PROD' AND start_time > SYSDATE - 7)
         ORDER BY 1)
SELECT * FROM data
UNION ALL
SELECT '<center> Backup gönderilmemiþ veritabaný bulunmamaktadýr. </center>'
  FROM DUAL
 WHERE NOT EXISTS (SELECT NULL FROM data);

SELECT '<center><b>Ýki gündür ARCHIVELOG backupý baþarýlý bitmemiþ Oracle Veritabanlarý</b></center>' FROM DUAL;

WITH data
     AS (SELECT '<center>' || db_name || '</center>' AS "Veritabaný"
           FROM (SELECT CASE
                           WHEN a.dg_node = 1
                           THEN
                               a.dg_node_name 
                           ELSE
                              a.db_name
                        END
                           db_name
                   FROM ISBDBA.DATABASES a, isbdba.oracle_control_mapping b
                  WHERE a.ID = b.db_id AND b.backup = 1 AND a.LVL = 'PROD'
                 MINUS
                 SELECT DISTINCT db_name
                   FROM backup.oracle_backup_logs
                  WHERE     env = 'PROD'
                        AND backup_type IN ('ARC', 'ARC2')
                        AND START_TIME >
                               TO_DATE (SYSDATE - 2, 'dd.mm.rrrr hh24:mi:ss')
                        AND return_code = 0))
SELECT * FROM data
UNION ALL
SELECT '<center> Tüm ortamlarýn archivelog backuplarý alýnmaktadýr. </center>'
  FROM DUAL
 WHERE NOT EXISTS (SELECT NULL FROM data);

SELECT '<center><b>Bir aydýr DO backupý baþarýlý bitmemiþ Oracle Veritabanlarý</b></center>' FROM DUAL;

WITH data
     AS (SELECT '<center>' || db_name || '</center>' AS "Veritabaný"
           FROM (SELECT CASE
                           WHEN a.dg_node = 1
                           THEN
                               a.dg_node_name 
                           ELSE
                              a.db_name
                        END
                           db_name
                   FROM ISBDBA.DATABASES a, isbdba.oracle_control_mapping b
                  WHERE a.ID = b.db_id AND b.backup = 1 AND a.LVL = 'PROD'
                 MINUS
                 SELECT DISTINCT db_name
                   FROM backup.oracle_backup_logs
                  WHERE     env = 'PROD'
                        AND backup_type IN ('DO', 'CLSADO')
                        AND START_TIME >
                               TO_DATE (SYSDATE - 30,
                                        'dd.mm.rrrr hh24:mi:ss')
                        AND return_code = 0))
SELECT * FROM data
UNION ALL
SELECT '<center> Tüm ortamlarda delete obsolete backup çalýþmaktadýr. </center>'
  FROM DUAL
 WHERE NOT EXISTS (SELECT NULL FROM data);

SELECT '<center><b>Üç gündür HEADER backupý alýnamayan Oracle Veritabanlarý</b></center>' FROM DUAL;

WITH data
     AS (SELECT '<center>' || db_name || '</center>' AS "Veritabaný"
           FROM (SELECT CASE
                           WHEN a.dg_node = 1 THEN a.dg_node_name
                           ELSE a.db_name
                        END
                           db_name
                   FROM isbdba.databases a, isbdba.oracle_control_mapping b
                  WHERE     a.ID = b.db_id
                        AND b.headerbackup = 1
                        AND a.lvl = 'PROD'
                 MINUS
                 SELECT DISTINCT db_name
                   FROM backup.header_backup_logs
                  WHERE     env = 'PROD'
                        AND start_time >
                               TO_DATE (SYSDATE - 3, 'dd.mm.rrrr hh24:mi:ss')
                        AND status = 1))
SELECT * FROM data
UNION ALL
SELECT '<center> Tüm ortamlarýn header backuplarý alýnmaktadýr. </center>'
  FROM DUAL
 WHERE NOT EXISTS (SELECT NULL FROM data);

exit;
