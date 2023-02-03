select tablespace_name,'USED' space_type,sum(bytes) from dba_segments 
where tablespace_name in ('TSAUDIT_DATA','TSAUDIT_INDEX')
group by tablespace_name,'USED'
union
select tablespace_name,'FREE' space_type,sum(bytes) from dba_free_space
where tablespace_name in ('TSAUDIT_DATA','TSAUDIT_INDEX')
group by tablespace_name,'FREE'

 

union

select tablespace_name,'EXT' space_type,sum(bytes) from dba_extents
where tablespace_name in ('TSAUDIT_DATA','TSAUDIT_INDEX')
group by tablespace_name,'EXT'

select a.TABLESPACE_NAME, a.file_name, sum(TOTAL), sum(FREE) from 
(select fs.TABLESPACE_NAME,df.FILE_NAME,df.BYTES TOTAL, fs.BYTES FREE from dba_free_space fs, dba_data_files df
where fs.FILE_ID = df.FILE_ID
and fs.TABLESPACE_NAME in ('TSAUDIT_DATA','TSAUDIT_INDEX') ) a
group by a.TABLESPACE_NAME,a.FILE_NAME

TABLESPACE_NAME|SPACE_TYPE|SUM(BYTES)
TSAUDIT_DATA|FREE|45809664
TSAUDIT_DATA|USED|1946419200
TSAUDIT_INDEX|FREE|268369920
TSAUDIT_INDEX|USED|570425344
