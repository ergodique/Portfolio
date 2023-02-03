select * from sysman.mgmt_targets where
target_guid in ( select assoc_target_guid from sysman.mgmt_target_assocs where source_target_guid in (select target_guid from sysman.mgmt_targets
where target_type='composite' and target_name='Oracle Prod Sistemleri'))
and target_type like '%database';

select target_guid from sysman.mgmt_targets where
target_guid in ( select assoc_target_guid from sysman.mgmt_target_assocs where source_target_guid in (select target_guid from sysman.mgmt_targets
where target_type='composite' and target_name='Oracle Prod Sistemleri'))
and target_type like '%database';


SELECT TARGET_NAME,sum(Avail) OVERALL_AVAILABILITY_PER_ID , sum(T_Uptime) TOTAL_UPTIME_HRS_ID , sum(T_Downtime) TOTAL_DOWNTIME_HRS_ID , sum(T_Blackouttime) TOTAL_BLACKOUT_TIME_HRS_ID, sum(T_Unmonitoredtime) TOTAL_UNMONITORED_TIME_HRS_ID 
from(
      SELECT TARGET_NAME,round( st_dur.tgt_up/(decode(st_dur.tgt_up+st_dur.agent_down+st_dur.tgt_down,0,1,st_dur.tgt_up+st_dur.agent_down+st_dur.tgt_down))*100,2) Avail
      ,round((st_dur.tgt_up*24),2) T_Uptime, round((st_dur.tgt_down*24),2) T_Downtime, round((st_dur.blackout*24),2) T_Blackouttime, round(((st_dur.agent_down+st_dur.metric_error+st_dur.pend_unknown+st_dur.unreach)*24),2) T_Unmonitoredtime
      FROM (
        SELECT TARGET_NAME,SUM( decode(AVAI_STATUS,'agent down',DURATION,0)) agent_down,
    SUM(decode(AVAI_STATUS,'blackout',DURATION,0)) blackout,
    SUM(decode(AVAI_STATUS,'metric error',DURATION,0)) metric_error,
    SUM(decode(AVAI_STATUS,'pending/unknown',DURATION,0)) pend_unknown,
    SUM(decode(AVAI_STATUS,'target down',DURATION,0)) tgt_down,
    SUM(decode(AVAI_STATUS,'target up',DURATION,0)) tgt_up,
    SUM(decode(AVAI_STATUS,'unreachable',DURATION,0)) unreach FROM(
        SELECT A.TARGET_NAME,LOWER(A.AVAILABILITY_STATUS) AVAI_STATUS
        ,ROUND(least(nvl(A.end_timestamp,(CAST(systimestamp at time zone B.TIMEZONE_REGION AS DATE))), MGMT_VIEW_UTIL.ADJUST_TZ(??EMIP_BIND_END_DATE??,??EMIP_BIND_TIMEZONE_REGION??,B.TIMEZONE_REGION) )
        -greatest(A.start_timestamp,MGMT_VIEW_UTIL.ADJUST_TZ(??EMIP_BIND_START_DATE??,??EMIP_BIND_TIMEZONE_REGION??,B.TIMEZONE_REGION) ),4) DURATION
        FROM mgmt$availability_history A,MGMT$TARGET B WHERE A.TARGET_GUID=B.TARGET_GUID AND A.TARGET_GUID IN (select target_guid from sysman.mgmt_targets where
target_guid in ( select assoc_target_guid from sysman.mgmt_target_assocs where source_target_guid in (select target_guid from sysman.mgmt_targets
where target_type='composite' and target_name='Oracle Prod Sistemleri'))
and target_type like '%database')
          and A.start_timestamp>=(select min(NVL(end_timestamp,(CAST(systimestamp at time zone B.TIMEZONE_REGION AS DATE)))) from mgmt$availability_history where target_guid IN (select target_guid from sysman.mgmt_targets where
target_guid in ( select assoc_target_guid from sysman.mgmt_target_assocs where source_target_guid in (select target_guid from sysman.mgmt_targets
where target_type='composite' and target_name='Oracle Prod Sistemleri'))
and target_type like '%database') )
          and ((A.start_timestamp>MGMT_VIEW_UTIL.ADJUST_TZ(??EMIP_BIND_START_DATE??,??EMIP_BIND_TIMEZONE_REGION??,B.TIMEZONE_REGION) AND NVL(A.end_timestamp,(CAST(systimestamp at time zone B.TIMEZONE_REGION AS DATE)))<MGMT_VIEW_UTIL.ADJUST_TZ(??EMIP_BIND_END_DATE??,??EMIP_BIND_TIMEZONE_REGION??,B.TIMEZONE_REGION))
           OR(MGMT_VIEW_UTIL.ADJUST_TZ(??EMIP_BIND_START_DATE??,??EMIP_BIND_TIMEZONE_REGION??,B.TIMEZONE_REGION) between A.start_timestamp AND NVL(A.end_timestamp,(CAST(systimestamp at time zone B.TIMEZONE_REGION AS DATE))))OR
           (MGMT_VIEW_UTIL.ADJUST_TZ(??EMIP_BIND_END_DATE??,??EMIP_BIND_TIMEZONE_REGION??,B.TIMEZONE_REGION) between A.start_timestamp and NVL(A.end_timestamp,(CAST(systimestamp at time zone B.TIMEZONE_REGION AS DATE)))))
     ) GROUP BY TARGET_NAME
        )  st_dur ) GROUP BY TARGET_NAME

SELECT TARGET_NAME,sum(Avail) OVERALL_AVAILABILITY_PER_ID , sum(T_Uptime) TOTAL_UPTIME_HRS_ID , sum(T_Downtime) TOTAL_DOWNTIME_HRS_ID , sum(T_Blackouttime) TOTAL_BLACKOUT_TIME_HRS_ID, sum(T_Unmonitoredtime) TOTAL_UNMONITORED_TIME_HRS_ID 
from(
      select 'TARGET' TARGET_NAME,0 Avail, 0 T_Uptime, 0 T_Downtime, 0 T_Blackouttime, 0 T_Unmonitoredtime from dual   
      UNION ALL
      SELECT TARGET_NAME,round( st_dur.tgt_up/(decode(st_dur.tgt_up+st_dur.agent_down+st_dur.tgt_down,0,1,st_dur.tgt_up+st_dur.agent_down+st_dur.tgt_down))*100,2) Avail
      ,round((st_dur.tgt_up*24),2) T_Uptime, round((st_dur.tgt_down*24),2) T_Downtime, round((st_dur.blackout*24),2) T_Blackouttime, round(((st_dur.agent_down+st_dur.metric_error+st_dur.pend_unknown+st_dur.unreach)*24),2) T_Unmonitoredtime
      FROM (
        SELECT TARGET_NAME,SUM( decode(AVAI_STATUS,'agent down',DURATION,0)) agent_down,
    SUM(decode(AVAI_STATUS,'blackout',DURATION,0)) blackout,
    SUM(decode(AVAI_STATUS,'metric error',DURATION,0)) metric_error,
    SUM(decode(AVAI_STATUS,'pending/unknown',DURATION,0)) pend_unknown,
    SUM(decode(AVAI_STATUS,'target down',DURATION,0)) tgt_down,
    SUM(decode(AVAI_STATUS,'target up',DURATION,0)) tgt_up,
    SUM(decode(AVAI_STATUS,'unreachable',DURATION,0)) unreach FROM(
        SELECT A.TARGET_NAME,LOWER(A.AVAILABILITY_STATUS) AVAI_STATUS
        ,ROUND(least(nvl(A.end_timestamp,(CAST(systimestamp at time zone B.TIMEZONE_REGION AS DATE))), MGMT_VIEW_UTIL.ADJUST_TZ(??EMIP_BIND_END_DATE??,??EMIP_BIND_TIMEZONE_REGION??,B.TIMEZONE_REGION) )
        -greatest(A.start_timestamp,MGMT_VIEW_UTIL.ADJUST_TZ(??EMIP_BIND_START_DATE??,??EMIP_BIND_TIMEZONE_REGION??,B.TIMEZONE_REGION) ),4) DURATION
        FROM mgmt$availability_history A,MGMT$TARGET B WHERE A.TARGET_GUID=B.TARGET_GUID AND A.TARGET_GUID IN (select target_guid from sysman.mgmt_targets where
target_guid in ( select assoc_target_guid from sysman.mgmt_target_assocs where source_target_guid in (select target_guid from sysman.mgmt_targets
where target_type='composite' and target_name='Oracle Prod Sistemleri'))
and target_type like '%database')
          and A.start_timestamp>=(select min(NVL(end_timestamp,(CAST(systimestamp at time zone B.TIMEZONE_REGION AS DATE)))) from mgmt$availability_history where target_guid IN (select target_guid from sysman.mgmt_targets where
target_guid in ( select assoc_target_guid from sysman.mgmt_target_assocs where source_target_guid in (select target_guid from sysman.mgmt_targets
where target_type='composite' and target_name='Oracle Prod Sistemleri'))
and target_type like '%database') )
          and ((A.start_timestamp>MGMT_VIEW_UTIL.ADJUST_TZ(??EMIP_BIND_START_DATE??,??EMIP_BIND_TIMEZONE_REGION??,B.TIMEZONE_REGION) AND NVL(A.end_timestamp,(CAST(systimestamp at time zone B.TIMEZONE_REGION AS DATE)))<MGMT_VIEW_UTIL.ADJUST_TZ(??EMIP_BIND_END_DATE??,??EMIP_BIND_TIMEZONE_REGION??,B.TIMEZONE_REGION))
           OR(MGMT_VIEW_UTIL.ADJUST_TZ(??EMIP_BIND_START_DATE??,??EMIP_BIND_TIMEZONE_REGION??,B.TIMEZONE_REGION) between A.start_timestamp AND NVL(A.end_timestamp,(CAST(systimestamp at time zone B.TIMEZONE_REGION AS DATE))))OR
           (MGMT_VIEW_UTIL.ADJUST_TZ(??EMIP_BIND_END_DATE??,??EMIP_BIND_TIMEZONE_REGION??,B.TIMEZONE_REGION) between A.start_timestamp and NVL(A.end_timestamp,(CAST(systimestamp at time zone B.TIMEZONE_REGION AS DATE)))))
     ) GROUP BY TARGET_NAME
        )  st_dur ) GROUP BY TARGET_NAME