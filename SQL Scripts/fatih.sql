select last_day(sysdate-30) from dual;

SELECT TO_CHAR (
  NEXT_DAY (
    LAST_DAY (
        ADD_MONTHS (TRUNC(SYSDATE,'Y'),ROWNUM-1))-7,
        TO_CHAR (TO_DATE('29-01-1927', 'DD-MM-YYYY'),'DAY')
  ), 'DD.MM.YYYY') "Last Saturdays in 2004"
 FROM ALL_OBJECTS
WHERE ROWNUM <= 12;

select to_char(trunc(trunc(sysdate, 'MM') - 1, 'MM'),'YYYYMMDD') "First Day of Last Month",
to_char(trunc(sysdate, 'MM') - 1,'YYYYMMDD') "Last Day of Last Month"
from dual ;

select to_char(trunc(trunc(sysdate, 'MM') - 1, 'MM'),'YYYYMMDD') from dual ;

SELECT C.UNIT_ID, C.SERVICE_NAME, SUM(C.TOTAL_NUMBER) AS ADET
FROM ODAK.CMN_SUMMARY_STATP C 
WHERE C.TRX_DATE BETWEEN TO_DATE(to_char(trunc(trunc(sysdate, 'MM') - 1, 'MM'),'YYYYMMDD'),'YYYYMMDD') AND TO_DATE(to_char(trunc(sysdate, 'MM') - 1,'YYYYMMDD'),'YYYYMMDD')
GROUP BY C.UNIT_ID, C.SERVICE_NAME;




SELECT CHANNEL_ID, FUNCTION_CODE,  UNIT_ID, SUM(COUNT) AS ADET
FROM ODAK.CMN_STATDATASUMMARY_CSSTP
WHERE SYSTEM_DATE BETWEEN TO_DATE(to_char(trunc(trunc(sysdate, 'MM') - 1, 'MM'),'YYYYMMDD'),'YYYYMMDD') AND TO_DATE(to_char(trunc(sysdate, 'MM') - 1,'YYYYMMDD'),'YYYYMMDD')
GROUP BY CHANNEL_ID, FUNCTION_CODE,  UNIT_ID ;



SELECT UNIQUE SERVICE_NAME, SUM(TOTAL_NUMBER) AS ADET
FROM ODAK.CMN_SUMMARY_STATP 
WHERE TRX_DATE BETWEEN TO_DATE(to_char(trunc(trunc(sysdate, 'MM') - 1, 'MM'),'YYYYMMDD'),'YYYYMMDD') AND TO_DATE(to_char(trunc(sysdate, 'MM') - 1,'YYYYMMDD'),'YYYYMMDD')
GROUP BY SERVICE_NAME ORDER BY SERVICE_NAME ;




SELECT UNIQUE CHANNEL_ID, FUNCTION_CODE, SUM(COUNT) AS ADET
FROM ODAK.CMN_STATDATASUMMARY_CSSTP
WHERE SYSTEM_DATE BETWEEN TO_DATE(to_char(trunc(trunc(sysdate, 'MM') - 1, 'MM'),'YYYYMMDD'),'YYYYMMDD') AND TO_DATE(to_char(trunc(sysdate, 'MM') - 1,'YYYYMMDD'),'YYYYMMDD')
GROUP BY CHANNEL_ID, FUNCTION_CODE ORDER BY CHANNEL_ID ;
