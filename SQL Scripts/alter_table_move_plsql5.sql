declare
cursor c1 is  select TABLE_OWNER,TABLE_NAME,PARTITION_NAME  from dba_tab_partitions where tablespace_name= 'NSW';
begin       
       FOR STR in c1
         LOOP
              BEGIN
                dbms_output.put_line ('ALTER TABLE '||str.table_owner||'.'||str.table_name||' MOVE PARTITION '||str.partition_name||'  TABLESPACE NSW_NEW;');
                declare
                cursor c2 is select index_owner,index_name,partition_name from dba_ind_partitions where partition_name = str.partition_name and tablespace_name = 'NSW' ;
                begin
                for str2 in c2
                loop 
                begin
                dbms_output.put_line ('ALTER index '||str2.index_owner||'.'||str2.index_name||' rebuild partition '||str2.partition_name||' TABLESPACE NSW_NEW;');
                end;
                end loop;
                end;    
              END;     
       END LOOP;
end;