SELECT GUNCEL_HAL.DB_NAME AS "DB_NAME",
         GUNCEL_HAL.DISK_NAME AS "DISK_NAME",
         ESKI_HAL.RECORD_DATE AS "OLD_CONTROL_DATE",
         ROUND (ESKI_HAL.DST / 1024, 0) AS "OLD_DISK_SIZE_TOTAL",
         ROUND (ESKI_HAL.DSF / 1024, 0) AS "OLD_DISK_SIZE_FREE",
         GUNCEL_HAL.RECORD_DATE AS "NEW_CONTROL_DATE",
         ROUND (GUNCEL_HAL.DST / 1024, 0) AS "NEW_DISK_SIZE_TOTAL",
         ROUND (GUNCEL_HAL.DSF / 1024, 0) AS "NEW_DISK_SIZE_FREE",
         ESKI_HAL.PCT AS "OLD_OCCUPANCY",
         GUNCEL_HAL.PCT AS "NEW_OCCUPANCY",
         (GUNCEL_HAL.RECORD_DATE - ESKI_HAL.RECORD_DATE) AS "TIME_PASSED",
         ROUND (
              (  (GUNCEL_HAL.DST - GUNCEL_HAL.DSF)
               - (ESKI_HAL.DST - ESKI_HAL.DSF))
            / 1024,
            0)
            "CHANGE",
         ROUND (
            (  180
             * (  (GUNCEL_HAL.DST - GUNCEL_HAL.DSF)
                - (ESKI_HAL.DST - ESKI_HAL.DSF))
             / (GUNCEL_HAL.RECORD_DATE - ESKI_HAL.RECORD_DATE))/1024,
            2)
            AS "6MONTH_CHANGE"
    FROM (SELECT a.record_date RECORD_DATE,
                 a.db_name DB_NAME,
                 a.disk_name DISK_NAME,
                 a.disk_size_total DST,
                 (a.disk_size_total - a.disk_size_used) DSF,
                 ROUND ( (a.disk_size_used / a.disk_size_total) * 100, 2) PCT
            FROM isbdba.oracle_asm_sizes_daily_mv a, isbdba.databases b
           WHERE     a.db_name = b.db_name
                 AND b.lvl = 'PROD'
                 AND (disk_name LIKE 'DATA%' OR DISK_NAME IN ('FRA'))
                 AND (a.disk_size_used / a.disk_size_total) * 100 > 70
                 AND (a.disk_size_total - a.disk_size_used) < 204800) GUNCEL_HAL,
         (SELECT a.record_date RECORD_DATE,
                 a.db_name DB_NAME,
                 a.disk_name DISK_NAME,
                 a.disk_size_total DST,
                 (a.disk_size_total - a.disk_size_used) DSF,
                 ROUND ( (a.disk_size_used / a.disk_size_total) * 100, 2) PCT
            FROM isbdba.oracle_asm_sizes a
           WHERE (record_date, db_name, disk_name) IN
                    (  SELECT MIN (x.record_date), x.db_name, x.disk_name
                         FROM isbdba.oracle_asm_sizes x,
                              isbdba.oracle_asm_sizes_daily_mv a,
                              isbdba.databases b
                        WHERE     x.db_name = a.db_name
                              AND x.disk_name = a.disk_name
                              AND a.db_name = b.db_name
                              AND b.lvl = 'PROD'
                              AND (   a.disk_name LIKE 'DATA%'
                                   OR a.DISK_NAME IN ('FRA'))
                              AND (a.disk_size_used / a.disk_size_total) * 100 >
                                     70
                              AND (a.disk_size_total - a.disk_size_used) < 204800
                              AND a.disk_size_total >= x.disk_size_total
                     GROUP BY x.db_name, x.disk_name)) ESKI_HAL
   WHERE     GUNCEL_HAL.DB_NAME = ESKI_HAL.DB_NAME
         AND GUNCEL_HAL.DISK_NAME = ESKI_HAL.DISK_NAME
ORDER BY 13 desc;
