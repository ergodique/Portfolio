SELECT   TO_DATE (TO_CHAR (alloc.TIMESTAMP, 'MON RR'),
                  'MON RR'
                 ) AS calendar_month,
         alloc.TABLESPACE AS TABLESPACE,
         ROUND (AVG (alloc.avg_size_mb), 2) AS size_mb,
         ROUND (AVG (used.avg_used_mb), 2) AS used_mb,
         ROUND (AVG (alloc.avg_size_mb - used.avg_used_mb), 2) AS free_mb,
         ROUND (AVG (  (used.avg_used_mb * 100)
                     / DECODE (alloc.avg_size_mb, 0, 1, alloc.avg_size_mb)
                    ),
                2
               ) AS used_pct,
         ROUND (MAX (alloc.max_size_mb), 2) AS size_mb,
         ROUND (MAX (used.max_used_mb), 2) AS used_mb,
         ROUND (MAX (alloc.avg_size_mb - used.avg_used_mb), 2) AS free_mb,
         ROUND (MAX (  (used.avg_used_mb * 100)
                     / DECODE (alloc.avg_size_mb, 0, 1, alloc.avg_size_mb)
                    ),
                2
               ) AS used_pct,
         ROUND (MIN (alloc.min_size_mb), 2) AS size_mb,
         ROUND (MIN (used.min_used_mb), 2) AS used_mb,
         ROUND (MIN (alloc.avg_size_mb - used.avg_used_mb), 2) AS free_mb,
         ROUND (MIN (  (used.avg_used_mb * 100)
                     / DECODE (alloc.avg_size_mb, 0, 1, alloc.avg_size_mb)
                    ),
                2
               ) AS used_pct
    FROM (SELECT   m.key_value AS TABLESPACE, m.rollup_timestamp AS TIMESTAMP,
                   AVG (m.average) AS avg_size_mb,
                   MIN (m.MINIMUM) AS min_size_mb,
                   MAX (m.maximum) AS max_size_mb
              FROM mgmt$metric_daily m, mgmt$target_type t
             WHERE t.target_guid = HEXTORAW ('5FE241CD23BEDA23BB9FCD72CB88EF99')
               AND (   t.target_type = 'rac_database'
                    OR (    t.target_type = 'oracle_database'
                        AND t.type_qualifier3 != 'RACINST'
                       )
                   )
               AND m.target_guid = t.target_guid
               AND m.metric_guid = t.metric_guid
               AND t.metric_name = 'tbspAllocation'
               AND (t.metric_column = 'spaceAllocated')
               AND m.rollup_timestamp >= sysdate-120
               AND m.rollup_timestamp <= sysdate
          GROUP BY m.rollup_timestamp, m.key_value) alloc,
         (SELECT   m.key_value AS TABLESPACE, m.rollup_timestamp AS TIMESTAMP,
                   AVG (m.average) AS avg_used_mb,
                   MIN (m.MINIMUM) AS min_used_mb,
                   MAX (m.maximum) AS max_used_mb
              FROM mgmt$metric_daily m, mgmt$target_type t
             WHERE t.target_guid = HEXTORAW ('5FE241CD23BEDA23BB9FCD72CB88EF99')
               AND (   t.target_type = 'rac_database'
                    OR (    t.target_type = 'oracle_database'
                        AND t.type_qualifier3 != 'RACINST'
                       )
                   )
               AND m.target_guid = t.target_guid
               AND m.metric_guid = t.metric_guid
               AND t.metric_name = 'tbspAllocation'
               AND (t.metric_column = 'spaceUsed')
               AND m.rollup_timestamp >= sysdate-120
               AND m.rollup_timestamp <= sysdate
          GROUP BY m.rollup_timestamp, m.key_value) used
   WHERE alloc.TIMESTAMP = used.TIMESTAMP
     AND alloc.TABLESPACE = used.TABLESPACE
     and alloc.TABLESPACE = 'TSCREDITDB'
GROUP BY TO_CHAR (alloc.TIMESTAMP, 'MON RR'), alloc.TABLESPACE
order by 1