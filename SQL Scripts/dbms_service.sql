execute dbms_service.create_service('SRV_ETL_KYPPRD','SRV_ETL_KYPPRD');

execute dbms_service.delete_service('SRV_ETL_ETLPRD');

exec dbms_service.start_service('SRV_ETL_KYPPRD','KYPPRD');

exec dbms_service.stop_service('SRV_ETL_ETLPRD','KYPPRD');

select * from dba_services
order by 2

select * from gv$services
order by 2
 

