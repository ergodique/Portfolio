declare

cursor c1 is  select owner,segment_name,partition_name from dba_extents
where file_id = 12
and segment_type in ('TABLE PARTITION');

begin       
       FOR STR in c1
         LOOP
              BEGIN
                      dbms_output.put_line ('ALTER TABLE '||str.owner||'.'||str.segment_name||' MOVE PARTITION '||str.partition_name||'  TABLESPACE ARCHIVE;');
                declare
                cursor c2 is select index_owner,index_name,partition_name from dba_ind_partitions where tablespace_name = 'ARCHIVE_NEW' and partition_name = str.partition_name ;
                begin
                for str2 in c2
                loop 
                begin
                dbms_output.put_line ('ALTER index '||str2.index_owner||'.'||str2.index_name||' rebuild partition '||str2.partition_name||' TABLESPACE ARCHIVE;');
                end;
                end loop;
                end;    
           END;   
       END LOOP;
end;