select wonum as is_istegi,origrecordid as hizmet_talebi,description as ozet,(select reportdate from maximo1.sr where ticketid=workorder.origrecordid) as bildirim_Tarihi,
reportedby as bildiren,(select displayname from maximo1.person where personid=workorder.reportedby) as bildiren_isim,status as durum, statusdate as durum_tarihi, TARGCOMPDATE as CALISTIGI_TARIH
, isprogresscode as basari_durumu,owner as sahip, (select displayname from maximo1.person where personid=workorder.owner) as sahip_isim
from maximo1.workorder where wol1='ISBT0182' order by durum_tarihi desc;

select wonum as is_istegi,origrecordid as hizmet_talebi,description as ozet,(select reportdate from maximo1.sr where ticketid=workorder.origrecordid) as bildirim_Tarihi,
reportedby as bildiren,(select displayname from maximo1.person where personid=workorder.reportedby) as bildiren_isim,status as durum, statusdate as durum_tarihi,
isprogresscode as basari_durumu,owner as sahip,(select ISSURUMDISIHAVUZ from sr where ticketid=workorder.origrecordid) as surum_disi,isenvironment as ortam, (select displayname from maximo1.person where personid=workorder.owner) as sahip_isim
from maximo1.workorder where wol1='ISBT0182' order by workorderid desc;

--DBADIYLA BIRLIKTE
select wonum as is_istegi,origrecordid as hizmet_talebi,description as ozet,(select reportdate from maximo1.sr where ticketid=workorder.origrecordid) as bildirim_Tarihi,
reportedby as bildiren,(select displayname from maximo1.person where personid=workorder.reportedby) as bildiren_isim,status as durum, statusdate as durum_tarihi,
isprogresscode as basari_durumu,owner as sahip,(select tablevalue from maximo1.workorderspec where wonum=workorder.wonum and siteid='TR' and assetattrid='IS_DBNAME') as db_name,
(select ISSURUMDISIHAVUZ from sr where ticketid=workorder.origrecordid and siteid='TR') as surum_disi,isenvironment as ortam, (select displayname from maximo1.person where personid=workorder.owner) as sahip_isim
from maximo1.workorder where wol1='ISBT0182' order by workorderid desc;


select (select to_date(reportdate,'DD.MM.YYYY') from maximo1.sr where ticketid=workorder.origrecordid) as bildirim_Tarihi,
(select displayname from maximo1.person where personid=workorder.reportedby) as bildiren_isim, 
(select ISSURUMDISIHAVUZ from sr where ticketid=workorder.origrecordid) as surum_disi
from maximo1.workorder where wol1='ISBT0182' and isenvironment ='Production' and 
(select to_date(reportdate,'DD.MM.YYYY') from maximo1.sr where ticketid=workorder.origrecordid) > '01.01.2012'
order by workorderid desc;

--ENCOK ISTEK GIREN
select  p.displayname,
count(*)  
from maximo1.workorder w ,  maximo1.person p , maximo1.sr s where  P.PERSONID= W.REPORTEDBY and S.TICKETID = W.ORIGRECORDID                and  w.wol1='ISBT0182' and w.isenvironment ='Production' and 
(to_date(s.reportdate,'DD.MM.YYYY') ) > '01.01.2012'
and (s.ISSURUMDISIHAVUZ ) is not null
group by P.DISPLAYNAME
having count(*) > 10
order by 2 desc;

--AYLARA GORE ISTEK SAYILARI
select  extract(month from statusdate) as durum_tarihi,
count(*)  
from maximo1.workorder where wol1='ISBT0182' and isenvironment ='Production' and
status not  in ('CANCEL') and 
(select to_date(reportdate,'DD.MM.YYYY') from maximo1.sr where ticketid=workorder.origrecordid) > '01.01.2012'
--and (select ISSURUMDISIHAVUZ from maximo1.sr where ticketid=workorder.origrecordid) is not null
group by extract(month from statusdate) 
order by 1 desc;

--DBADINA GORE SAYILAR
select tablevalue ,
count(*)  
from maximo1.workorder w, maximo1.workorderspec ws 
where 
ws.wonum = w.wonum and
ws.siteid='TR' and ws.assetattrid='IS_DBNAME'
and wol1='ISBT0182' and isenvironment ='Production' and 
(select to_date(reportdate,'DD.MM.YYYY') from maximo1.sr where ticketid=w.origrecordid) > '01.01.2012'
and (select ISSURUMDISIHAVUZ from sr where ticketid=w.origrecordid) is not null
group by tablevalue 
order by 2 desc;

--DBADINA GORE SAYILAR
SELECT wsp.tablevalue AS DB_ADI,count(*)
    FROM maximo1.wostatus ws, maximo1.workorder w,maximo1.workorderspec wsp
   WHERE     
   ws.wonum = w.wonum
   and wsp.wonum = w.wonum
   and wsp.siteid='TR' and wsp.assetattrid='IS_DBNAME'
         AND ws.status = 'RESOLVED'
         AND w.wol1 = 'ISBT0182'
         AND w.isenvironment = 'Production'
         --AND W.WONUM = 608852
         AND ws.changedate > '01.09.2012'
         and  to_char(ws.changedate,'YYYYMMDD') not in ('20120908','20120909')
         --AND w.TARGCOMPDATE IS NULL
group by wsp.tablevalue
order by 2 desc;


--GUNLERE GORE SCHEDULE EDILEN ISTEK SAYILARI
SELECT to_char(ws.changedate,'YYYYMMDD') as TARIH, count(*)
    FROM maximo1.wostatus ws, maximo1.workorder w
   WHERE     ws.wonum = w.wonum
         AND ws.status = 'RESOLVED'
         AND w.wol1 = 'ISBT0182'
         AND w.isenvironment = 'Production'
         --AND W.WONUM = 608852
         AND ws.changedate > '01.09.2012'
         --AND w.TARGCOMPDATE IS NULL
group by to_char(ws.changedate,'YYYYMMDD')
ORDER BY 1 DESC


--istek detay
SELECT ws.changedate, ws.status, W.WONUM,W.STATUS,W.STATUSDATE,W.CHANGEBY,W.CHANGEDATE,W.TARGCOMPDATE,W.REPORTDATE,W.ACTSTART,W.OWNER,W.ISCURRENTQUEUE,W.DESCRIPTION
    FROM maximo1.wostatus ws, maximo1.workorder w
   WHERE     ws.wonum = w.wonum
         AND ws.status = 'RESOLVED'
         AND w.wol1 = 'ISBT0182'
         AND w.isenvironment = 'Production'
         --AND W.WONUM = 608852
         AND ws.changedate > '01.09.2012'
         --AND w.TARGCOMPDATE IS NULL
ORDER BY 1 DESC
