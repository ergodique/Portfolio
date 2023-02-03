SELECT IMSID,putdt,imsdt, (imsdt-putdt)  WIN_TO_IMS,
getdt, (getdt-imsdt) IMS_TO_WIN FROM mqtest.mqtest
WHERE imsid IN ('FEPR','PROD')
AND winid='W1'
AND TRUNC(putdt)=TRUNC(SYSDATE-1)
AND (getdt-putdt) >= TO_DSINTERVAL('00 00:00:02.00')
--AND ((imsdt-putdt) >= TO_DSINTERVAL('00 00:00:02.00')
--  OR (getdt-imsdt) >= TO_DSINTERVAL('00 00:00:02.00'))
ORDER BY putdt ASC,imsid DESC;

/*imsid rapor*/
SELECT TRUNC(putdt),imsid,COUNT(*)
FROM mqtest.mqtest
WHERE TRUNC(putdt) >= TO_DATE('20060206','YYYYMMDD') --<TRUNC(SYSDATE-2) 
AND (getdt-putdt) < TO_DSINTERVAL('00 00:00:00.500')
GROUP BY imsid,TRUNC(putdt)
ORDER BY 1,2

/*saatlik rapor*/
SELECT TO_CHAR(putdt,'DD.MM.YYYY HH24'),imsid,COUNT(*)
FROM mqtest.mqtest
WHERE (getdt-putdt) >= TO_DSINTERVAL('00 00:00:04.00')
GROUP BY TO_CHAR(putdt,'DD.MM.YYYY HH24'),imsid
ORDER BY 1,2

/*günlük rapor*/
SELECT TRUNC(putdt),imsid,COUNT(*)
FROM mqtest.mqtest
WHERE (getdt-putdt) >= TO_DSINTERVAL('00 00:00:02.00')
GROUP BY TRUNC(putdt),imsid 
ORDER BY 1,2


SELECT SYSTIMESTAMP, TRUNC(SYSTIMESTAMP), TRUNC(SYSDATE) FROM dual


