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
SELECT '<center><b>Son iki full backupı hatalı olan Oracle Veritabanları</b></center>' FROM DUAL;
WITH data
     AS (SELECT '<center><b>Veritabanı</b></center>',
                '<center><b>Son Başarılı Full Backup Zamanı</b></center>'
           FROM DUAL
         UNION ALL
         SELECT '<center>' || DB_NAME || '</center>' "Veritabanı",
                   '<center>'
                || TO_CHAR (LAST_SUCCESSFUL, 'dd.mm.rrrr')
                || '</center>'
                   "Son Başarılı Backup Zamanı"
           FROM TABLE (backup.twotimes_failed_full_bkp('PROD')))
SELECT * FROM data
UNION ALL
SELECT '-', '-'
  FROM DUAL
 WHERE 1 = (SELECT COUNT (*) FROM data);

SELECT '<center><b>Bir haftadır hiç backup gönderilmemiş Oracle Veritabanları</b></center>' FROM DUAL;

WITH data
     AS (  SELECT '<center>' || db_name || '</center>' AS "Veritabanı"
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
SELECT '<center> Backup gönderilmemiş veritabanı bulunmamaktadır. </center>'
  FROM DUAL
 WHERE NOT EXISTS (SELECT NULL FROM data);

SELECT '<center><b>İki gündür ARCHIVELOG backupı başarılı bitmemiş Oracle Veritabanları</b></center>' FROM DUAL;

WITH data
     AS (SELECT '<center>' || db_name || '</center>' AS "Veritabanı"
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
SELECT '<center> Tüm ortamların archivelog backupları alınmaktadır. </center>'
  FROM DUAL
 WHERE NOT EXISTS (SELECT NULL FROM data);

SELECT '<center><b>Bir aydır DO backupı başarılı bitmemiş Oracle Veritabanları</b></center>' FROM DUAL;

WITH data
     AS (SELECT '<center>' || db_name || '</center>' AS "Veritabanı"
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
SELECT '<center> Tüm ortamlarda delete obsolete backup çalışmaktadır. </center>'
  FROM DUAL
 WHERE NOT EXISTS (SELECT NULL FROM data);

SELECT '<center><b>Üç gündür HEADER backupı alınamayan Oracle Veritabanları</b></center>' FROM DUAL;

WITH data
     AS (SELECT '<center>' || db_name || '</center>' AS "Veritabanı"
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
SELECT '<center> Tüm ortamların header backupları alınmaktadır. </center>'
  FROM DUAL
 WHERE NOT EXISTS (SELECT NULL FROM data);

exit;
