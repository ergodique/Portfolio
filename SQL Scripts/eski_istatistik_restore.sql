
select 'exec DBMS_STATS.RESTORE_TABLE_STATS (ownname=>''SIM'''||' , '||'tabname=>'''|| table_name||''''||' , '||'as_of_timestamp=>' ||''''||STATS_UPDATE_TIME||''')'||';'
from dba_tab_stats_history where owner='SIM' and partition_name is null and trunc(STATS_UPDATE_TIME)='14.07.2011'

select 'exec DBMS_STATS.RESTORE_TABLE_STATS (ownname=>''SIM'''||' , '||'tabname=>'''|| table_name||''''||' , '||'as_of_timestamp=>' ||''''||'14/07/2011 23:50:22,258634 +03:00'||''',no_invalidate =>FALSE )'||';'
from dba_tab_stats_history where owner='SIM' and partition_name is null and trunc(STATS_UPDATE_TIME)='14.07.2011'

exec DBMS_STATS.RESTORE_TABLE_STATS (ownname=>'SIM' , tabname=>'ACCOUNTTYPE' , as_of_timestamp=>'14/07/2011 09:50:22,258634 +03:00');


--How do I know how many days the statistics are available for ?

select DBMS_STATS.GET_STATS_HISTORY_RETENTION from dual;

   - will return the number of days stats are currently retained for.
        
select DBMS_STATS.GET_STATS_HISTORY_AVAILABILITY from dual;

    - will return the oldest possible date stats can be restored from

How do I find the statistics history for a given table ?

select TABLE_NAME, STATS_UPDATE_TIME from dba_tab_stats_history;

Will show the times statistics were regathered for a given table.

How do I restore the statistics ?

Having decided what date you know the statistics were good for, you can use:-

execute DBMS_STATS.RESTORE_TABLE_STATS ('owner','table',date)
execute DBMS_STATS.RESTORE_DATABASE_STATS(date)
execute DBMS_STATS.RESTORE_DICTIONARY_STATS(date)
execute DBMS_STATS.RESTORE_FIXED_OBJECTS_STATS(date)
execute DBMS_STATS.RESTORE_SCHEMA_STATS('owner',date)
execute DBMS_STATS.RESTORE_SYSTEM_STATS(date)


ie

 execute dbms_stats.restore_table_stats ('SCOTT','EMP','25-JUL-07 12.01.20.766591 PM +02:00');


SIM probleminde aþaðýdakiler kullanýldý


select 'exec DBMS_STATS.RESTORE_TABLE_STATS (ownname=>' ||'''SIM'''||' , tabname=>'||''''||table_name||'''
'||' , as_of_timestamp=>TO_DATE('||''''||STATS_UPDATE_TIME||''''||' , '||''''||'DD-MON-YYYY HH24:MI:SS'||''''||'));' 
from dba_tab_stats_history where owner='SIM' and partition_name is null and trunc(STATS_UPDATE_TIME)='01.07.2011'


exec DBMS_STATS.RESTORE_TABLE_STATS (ownname=>'SIM', tabname=>'PROMISSORYNOTETEMPORARY', as_of_timestamp=>TO_DATE('01-JUL-2011 16:31:52', 'DD-MON-YYYY HH24:MI:SS'));


TIMESTAMP'DEn TO_DATE'e çevirim

select 'exec DBMS_STATS.RESTORE_TABLE_STATS (ownname=>' ||'''SIM'''||' , tabname=>'||''''||table_name||'''
'||' , as_of_timestamp=>TO_DATE(TO_CHAR('||''''||STATS_UPDATE_TIME||''''||' , '||''''||'DD-MON-YYYY HH24:MI:SS'||''''||')'||'''DD-MON-YYYY HH24:MI:SS'''||');' 
from dba_tab_stats_history where owner='SIM' and partition_name is null and trunc(STATS_UPDATE_TIME)='01.07.2011'






TÜM TABLOLAR için Restore iþlemi
En son dynamic sorgu

--- TZ ve millisecond elle silindi

select 'exec DBMS_STATS.RESTORE_TABLE_STATS (ownname=>''SIM'''||' , '||'tabname=>'''|| table_name||'''
'||' , '||'as_of_timestamp=>TO_DATE(' ||''''||STATS_UPDATE_TIME||''''||','||'''DD/MM/YYYY HH24:MI:SS'''||'))'||';'
from dba_tab_stats_history where owner='SIM' and partition_name is null and trunc(STATS_UPDATE_TIME)='01.07.2011'