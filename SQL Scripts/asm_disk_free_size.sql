SELECT db_name,
       2 * daily_redo_generation AS "Two Days Redo Generation (GB)",
       archlog_size as "Archive Log Disk Size"
  FROM (  SELECT a.db_name,
                 ROUND (AVG (a.total_size), 0) AS daily_redo_generation,
                 (SELECT ROUND (
                            AVG (x.disk_size_total - x.disk_size_used) / 1024,
                            0)
                    FROM isbdba.oracle_asm_sizes_daily_mv x
                   WHERE x.db_name = a.db_name AND disk_name LIKE 'ARCH%')
                    AS archlog_size
            FROM ISBDBA.ORACLE_LGSWTCH_DRV a, isbdba.databases b
           WHERE     a.db_name = b.db_name
                 AND b.lvl = 'PROD'
                 AND b.file_system = 'ASM'
                 AND a.record_date > SYSDATE - 7
        GROUP BY a.db_name) q
--WHERE q.archlog_size < q.daily_redo_generation * 2;
