SELECT PARSING_SCHEMA_NAME,module,substr(sql_text,1,200) SQLT,
        count(*) cnt,
        sum(executions) totexecs
        FROM v$sqlarea
        WHERE executions < 5
        and   upper(sql_text) not like 'BEGIN%'
        and PARSING_SCHEMA_NAME not in ('SYS','SYSTEM','DBSNMP')
        GROUP BY PARSING_SCHEMA_NAME,module,substr(sql_text,1,200)
        HAVING count(*) > 30
        union
        SELECT PARSING_SCHEMA_NAME,module,substr(sql_text,1,instr(sql_text,'(')) ,
        count(*),
        sum(executions)
        FROM v$sqlarea
        WHERE executions < 5
        and   upper(sql_text) like 'BEGIN%'
        and PARSING_SCHEMA_NAME not in ('SYS','SYSTEM','DBSNMP')
        GROUP BY PARSING_SCHEMA_NAME,module,substr(sql_text,1,instr(sql_text,'('))
        HAVING count(*) > 30;