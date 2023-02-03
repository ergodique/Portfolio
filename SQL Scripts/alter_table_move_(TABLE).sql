declare
cursor c1 is  select OWNER,TABLE_NAME from dba_tables where tablespace_name= 'FS_INTRFC' ;
begin       
       FOR STR in c1
         LOOP
              BEGIN
                dbms_output.put_line ('ALTER TABLE '||str.owner||'.'||str.table_name||' MOVE TABLESPACE FS_INTRFC2;');
                declare
                cursor c2 is select owner,index_name from dba_indexes where TABLE_NAME = str.table_name   ;
                begin
                for str2 in c2
                loop 
                begin
                dbms_output.put_line ('ALTER index '||str2.owner||'.'||str2.index_name||' rebuild  TABLESPACE FS_INTRFC2;');
                end;
                end loop;
                end;    
              END;     
       END LOOP;
end;