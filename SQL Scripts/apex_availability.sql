delete from isbdba.DBAVAILABILITY_LOGS l where L.DB_NAME like 'AKILPRD%' and l.status ='DOWN' and LAST_UPDATE_DATE > sysdate -30;
commit;


delete from isbdba.DBAVAILABILITY_LOGS l where L.DB_NAME = 'UTF8PRD' and l.status ='DOWN' and trunc(L.LAST_UPDATE_DATE) = to_Date ('17.06.2014','DD.MM.YYYY');
commit;

select * from isbdba.DBAVAILABILITY_LOGS l where L.LAST_UPDATE_DATE > sysdate -30 and L.STATUS = 'DOWN' and db_name like '%PRD%'

--commit;