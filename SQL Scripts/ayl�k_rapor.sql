SELECT count(*) as INSTANCE_SAYISI
           FROM sysman.mgmt_targets mt
          WHERE mt.target_type IN ('oracle_database', 'rac_database')
            AND mt.category_prop_3 NOT IN ('RACINST');


SELECT COUNT (*) as TABLESPACE_SAYISI
  FROM sysman.mgmt$db_tablespaces ts, sysman.mgmt_targets mt
 WHERE ts.target_name = mt.target_name
   AND mt.target_type IN ('oracle_database', 'rac_database')
   AND mt.category_prop_3 NOT IN ('RACINST');
   
   
SELECT round(sum(ts.TABLESPACE_SIZE)/1024/1024/1024,2)  as TABLESPACE_BOYUT_GB
  FROM sysman.mgmt$db_tablespaces ts, sysman.mgmt_targets mt
 WHERE ts.target_name = mt.target_name
   AND mt.target_type IN ('oracle_database', 'rac_database')
   AND mt.category_prop_3 NOT IN ('RACINST')
  ;
   
SELECT round(sum(ts.TABLESPACE_USED_SIZE)/1024/1024/1024,2)  as TABLESPACE_KULLANILAN_BOYUT_GB
  FROM sysman.mgmt$db_tablespaces ts, sysman.mgmt_targets mt
 WHERE ts.target_name = mt.target_name
   AND mt.target_type IN ('oracle_database', 'rac_database')
   AND mt.category_prop_3 NOT IN ('RACINST')
   ;

select round(sum(sgasize)/1024,2) as "TOTAL_INSTANCE_MEMORY (GB)" from sysman.mgmt$db_sga where sganame='Total SGA (MB)'; 

select round(sum(mem)/1024,2) as "TOTAL_HOST_MEMORY (GB)" from sysman.mgmt$os_hw_summary;


SELECT d.rollup_timestamp
       ,round(sum(d.AVERAGE),2) SZ
       ,d.COLUMN_LABEL
        FROM mgmt$metric_daily d, mgmt$target_type t
        WHERE d.target_name ='UTF8PRD' AND
              (d.target_type = 'rac_database' OR d.target_type='oracle_database') AND
              t.metric_name = 'tbspAllocation' AND
--              (t.metric_column = 'spaceAllocated' OR t.metric_column = 'spaceUsed') AND
--              (t.metric_column = 'spaceAllocated' ) AND
              ( t.metric_column = 'spaceUsed') AND
              d.KEY_VALUE like 'TSAMLST%' AND 
              d.rollup_timestamp >= sysdate -45  AND
              t.target_guid = d.target_guid AND
              t.metric_guid = d.metric_guid AND
              (t.target_type='rac_database' OR
              (t.target_type='oracle_database' AND t.TYPE_QUALIFIER3 != 'RACINST')) group by d.rollup_timestamp ,d.COLUMN_LABEL order by d.ROLLUP_TIMESTAMP;



