/* no of part dbs per ims*/
SELECT ims_id,COUNT(*) FROM sims.dbozet
WHERE db_tip LIKE 'ZINDE%'
--and db_tip like 'Z%' 
AND ims_id IN ('FEPR','PROD')
AND tarih = (SELECT MAX(tarih) FROM sims.dbozet WHERE ims_id IN ('FEPR','PROD'))
GROUP BY ims_id

/* full list of partiioned db's*/
select ims_id,db_adi,db_tip FROM sims.dbozet
WHERE db_tip LIKE 'ZINDE%' 
AND ims_id IN ('FEPR','PROD')
AND tarih = (SELECT MAX(tarih) FROM sims.dbozet WHERE ims_id IN ('FEPR','PROD'))
order by 1,2

/* full list of partiioned db's*/
select ims_id,db_adi,db_tip FROM sims.dbozet
WHERE db_tip LIKE 'ZINDE%' 
AND ims_id IN ('FEPR','PROD')
AND tarih = (SELECT MAX(tarih) FROM sims.dbozet WHERE ims_id IN ('FEPR','PROD'))
order by 1,2


/* no of partitions per part db*/
SELECT db_adi,SUM(dataset_sayi) FROM sims.dbozet
WHERE db_tip LIKE 'Z%' 
AND ims_id IN ('FEPR','PROD')
AND tarih = (SELECT MAX(tarih) FROM sims.dbozet WHERE ims_id IN ('FEPR','PROD'))
GROUP BY db_adi

/* total size of part dbs*/ 
SELECT SUM(b.gb) FROM 
(SELECT db_adi,db_tip FROM sims.dbozet WHERE ims_id in ('PROD','FEPR')
AND tarih = (SELECT MAX(tarih) FROM sims.dbozet WHERE ims_id IN ('PROD')) AND db_tip LIKE 'Z%') a,
(SELECT t.db_adi,t.gb FROM sims.top50db t WHERE t.tarih = (SELECT MAX(tarih) FROM sims.top50db)) b 
WHERE b.db_adi(+)=a.db_adi

/* total size per part db*/
SELECT a.db_adi,a.db_tip, b.gb FROM 
(SELECT db_adi,db_tip FROM sims.dbozet WHERE ims_id in ('PROD','FEPR')
AND tarih = (SELECT MAX(tarih) FROM sims.dbozet WHERE ims_id IN ('PROD')) AND db_tip LIKE 'Z%') a,
(SELECT t.db_adi,t.gb FROM sims.top50db t WHERE t.tarih = (SELECT MAX(tarih) FROM sims.top50db)) b 
WHERE b.db_adi(+)=a.db_adi


/* total size per part db all db view*/
SELECT a.db_adi,a.db_tip,b.gb FROM 
(SELECT db_adi,db_tip FROM sims.dbozet WHERE ims_id in ('PROD','FEPR')
AND tarih = (SELECT MAX(tarih) FROM sims.dbozet WHERE ims_id IN ('PROD')) AND db_tip LIKE 'Z%') a,
(SELECT t.db_adi,t.gb FROM sims.topalldb t WHERE t.tarih = (SELECT MAX(tarih) FROM sims.topalldb)) b 
WHERE b.db_adi(+)=a.db_adi


/* part db sorumlularý*/
SELECT a.*,b.* FROM (SELECT db_adi,db_tip FROM sims.dbozet WHERE ims_id IN ('PROD','FEPR')
AND tarih = (SELECT MAX(tarih) FROM sims.dbozet WHERE ims_id IN ('PROD','FEPR')) AND db_tip LIKE 'Z%') a,
(SELECT db_adi,PROJE,SORUMLU1,SORUMLU2 FROM sims.dbinfo) b
WHERE b.db_adi(+)=a.db_adi
and a.db_tip !='ZINDEX'



