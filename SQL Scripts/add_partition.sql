DECLARE
newyear date:=to_date('01/01/2009','DD/MM/YYYY');
i NUMBER :=0;
a varchar2(20);
b varchar2(20);
begin
loop
 select TO_CHAR(newyear+i, 'YYYYMMDD', 'NLS_CALENDAR=GREGORIAN') into a from dual;
 select newyear+i+1 into b from dual;
 dbms_output.put_line('ALTER TABLE ARCHIVE.SRV_LOG_ARCH  ADD PARTITION SRVLOGPART_'||a||' VALUES LESS THAN  ('||b||') TABLESPACE ARCHIVE ;');
 i:=i+1;
 exit when i>365;
 end loop;
end;





set serveroutput on size 1000000
alter session set nls_date_format='YYYYMMDD';




DECLARE
i NUMBER :=7;
a varchar2(20);
b varchar2(20);
begin
loop
 select TO_CHAR(sysdate+i, 'YYYYMMDD', 'NLS_CALENDAR=GREGORIAN') into a from dual;
 select sysdate+i+1 into b from dual;
 dbms_output.put_line('ALTER TABLE FRAUDSTAR.TRANSACTIONS  ADD PARTITION P'||a||' VALUES LESS THAN  (TO_DATE('' '||b||' 00:00:00'', ''SYYYY-MM-DD HH24:MI:SS'', ''NLS_CALENDAR=GREGORIAN'')) TABLESPACE TRANS_07'|| SUBSTR(a,5,2)||' ;');
 i:=i+1;
 exit when i>371;
 end loop;
end;

--günlük partition

DECLARE
i NUMBER :=10;
a varchar2(20);
b varchar2(20);
begin
loop
 select sysdate+i into a from dual;
 select sysdate+i+1 into b from dual;
 dbms_output.put_line('ALTER TABLE CARD.AUTH_ISS_APPROVED SPLIT PARTITION AUTHAPPPART_MAX AT ('||b||') INTO (PARTITION AUTHAPPPART_'||a||', PARTITION AUTHAPPPART_MAX);' );
 i:=i+1;
 exit when i>374;
 end loop;
end;








alter table card.auth_iss_approved add PARTITION AUTHAPPPART_MAX VALUES LESS THAN (maxvalue)



ALTER TABLE SO46905.AUTH SPLIT PARTITION PMAXVALUE AT (20070102) INTO (PARTITION AUTHAPPPART_20070101, PARTITION PMAXVALUE);
       

ALTER TABLE SO46905.AUTH DROP PARTITION PMAXVALUE;
