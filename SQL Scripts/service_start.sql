DECLARE
 PRAGMA AUTONOMOUS_TRANSACTION;
 CURSOR service_names IS select name from dba_services where name like 'SRV%';
BEGIN 
 INSERT INTO ISBDBA.INSTANCE_COLLECT (SELECT 'STARTUP',SYSDATE,A.* FROM V$INSTANCE A);
 COMMIT;
 FOR servicename IN service_names LOOP
     sys.dbms_service.start_service(''||servicename.name||'');
  end loop;
 execute immediate 'begin isbdba.pin_OBJECTS_on_startup; end;';
 execute immediate 'begin isbdba.SET_LIMITS_on_startup; end;';
 execute immediate 'alter system register;';
 exception when others then null;
END;