select sysdate from dual;

select to_char(sysdate, 'DD/MM/YYYY HH24:MI:SS'), to_char(systimestamp, 'DD/MM/YYYY HH24:MI:SS TZR') from dual;

SELECT dbtimezone FROM DUAL;

select sessiontimezone from dual;

select * from nls_database_parameters

select * from nls_session_parameters