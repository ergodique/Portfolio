select 'AUTH' tablo,MAX(transactiondate) from FRAUDSTAR.authorizations
union
select 'INTRFC' ,MAX(transactiondate) from FRAUDSTAR.intrfc_authorizations
union
select 'SYSDATE' ,sysdate from dual;

select ruleno,count(8) from fraudstar.a_testzaman
where startdate > sysdate - 5/24
  and diff > 5
  group by ruleno
  order by count(8) desc;

select sid,substr(a.CLIENT_INFO,27,3) from v$session a where username='FRAUDSTAR' and a.client_info is not null and INstr(a.client_info,'rule no:') > 0 and status='ACTIVE'
order by 2 desc,1 desc;

select 'ALTER SYSTEM KILL SESSION '''||sid||','||serial#||''' immediate ;' from v$session a where username='FRAUDSTAR' and a.client_info is not null and INstr(a.client_info,'rule no:') > 0 and status='ACTIVE';


SELECT * FROM fraudstar.fraudstartime
where startdate > sysdate -1 
--and count > 4000
ORDER BY 5 DESC;

select count(*) from FRAUDSTAR.AUTHORIZATIONS a where A.TRANSACTIONDATE between to_date ('20141117 00:00','YYYYMMDD HH24:MI') and to_date ('20141117 23:59','YYYYMMDD HH24:MI')
union all
select count(*) from FRAUDSTAR.AUTHORIZATIONS a where A.TRANSACTIONDATE between to_date ('20141114 00:00','YYYYMMDD HH24:MI') and to_date ('20141114 23:59','YYYYMMDD HH24:MI');

select sid,sql_id,a.CLIENT_INFO,a.* from v$session a where username='FRAUDSTAR'
and status='ACTIVE';



select table_owner,table_name,partition_name,last_analyzed,NUM_ROWS from dba_tab_partitions where table_owner = 'FRAUDSTAR' and table_name = 'AUTHORIZATIONS'
order by last_analyzed desc
 --and partition_name = 'P'||substr(to_char(sysdate,'YYYYMMDD'),1,8);

alter session set current_schema = FRAUDSTAR;

select * from fraudstar.v_testzaman
order by 2 desc;

select * from fraudstar.testzaman
order by 1 desc;

select count(*) from INTRFC_AUTH_BATCH where state =  'N';

select * from INTRFC_AUTH_BATCH where state <> 'P';

select * from authorizations 
where transactiondate >= TO_DATE('20061218','YYYYMMDD')
AND CARDNO = 'SSS';


select * from FRAUDSTAR.FRAUDSTARPRM; 

--select * from fraudstar.fraudstartime order by 1 desc

SELECT * FROM fraudstar.fraudstartime 
where refno > (select max(refno) from fraudstar.fraudstartime)*0.9975
ORDER BY 1 DESC;


select * from FRAUDSTAR.v_testzamanadet;



select 'AUTH', round((sysdate - MAX(transactiondate))*1440,2) from FRAUDSTAR.authorizations
union
select 'INTRFC', round((sysdate - MAX(transactiondate))*1440,2) from FRAUDSTAR.intrfc_authorizations;


SELECT  to_char (startdate,'YYYYMMDD'), round(avg(ANALYSISTIME),2) FROM fraudstar.fraudstartime
where analysistime > 0
group by  to_char (startdate,'YYYYMMDD') 
order by 1 desc


-- Paketleri kaç saniyede bitiriyor
select fn_datediff('SE', startdate, finishdate) diff, a.* from FRAUDSTARTIME a  
where startdate between trunc(sysdate-1/24,'HH24') and sysdate
-- to_date('07052015 1823', 'ddmmyyyy hh24mi') and to_date('07052015 1853', 'ddmmyyyy hh24mi')
  --and fn_datediff('SE', startdate, finishdate) > 39
--  and analysistime > 0.5
  order by refno desc

-- Bekleyen toplam iþlem sayýsý
select sum(batchsize) from INTRFC_AUTH_BATCH  where state = 'N'
 
-- Interface ile Authorization arasýndaki fark 
select max(transactiondate) "Interface" 
from intrfc_authorizations
union
select max(transactiondate) "Authorizations" 
from authorizations

--Dakikada gelen iþlemler
select trunc(batchdate, 'MI'), max(to_char(sysdate, 'SS')) SS, sum(batchsize) 
from INTRFC_AUTH_BATCH 
where batchdate between trunc(sysdate-1/24,'HH24') and sysdate
--to_date('24022015 1350', 'ddmmyyyy hh24mi') and to_date('24022015 1859', 'ddmmyyyy hh24mi') 
group by trunc(batchdate, 'MI') order by 1 desc

-- Gunluk islem adetleri
select trunc(batchdate, 'DD'), sum(batchsize) 
from INTRFC_AUTH_BATCH 
where batchdate between trunc(sysdate-1/24,'HH24') and sysdate
--to_date('17022015 1350', 'ddmmyyyy hh24mi') and to_date('17022015 1859', 'ddmmyyyy hh24mi') 
group by trunc(batchdate, 'DD') order by 1 desc

select * from A_TESTZAMAN
where startdate > sysdate-5/24
and diff>3
order by enddate desc


select ruleno,count(8) from a_testzaman
where startdate > sysdate - 5/24
  and diff > 5
  group by ruleno
  order by count(8) desc
