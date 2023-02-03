declare

cursor c1 is  select owner,segment_name,partition_name,segment_type,max(block_id) from dba_extents
where tablespace_name= 'NSW'
and segment_type in ('TABLE','TABLE PARTITION')
group by owner,segment_name,partition_name,segment_type
order by max(block_id) desc;

begin       
       FOR STR in c1
         LOOP
              BEGIN
              if str.segment_type = 'TABLE' then
                      dbms_output.put_line ('ALTER TABLE '||str.owner||'.'||str.segment_name||' MOVE TABLESPACE NSW_NEW;');
                declare
                cursor c2 is select owner,index_name from dba_indexes where table_name = str.segment_name ;
                begin
                for str2 in c2
                loop 
                begin
                dbms_output.put_line ('ALTER index '||str2.owner||'.'||str2.index_name||' rebuild TABLESPACE NSW_NEW ONLINE;');
                end;
                end loop;
                end;
           else
                        dbms_output.put_line ('ALTER TABLE '||str.owner||'.'||str.segment_name||' MOVE '||str.partition_name||'  TABLESPACE NSW_NEW;');
                declare
                cursor c2 is select index_owner,index_name,partition_name from dba_ind_partitions where partition_name = str.partition_name ;
                begin
                for str2 in c2
                loop 
                begin
                dbms_output.put_line ('ALTER index '||str2.index_owner||'.'||str2.index_name||' rebuild partition '||str2.partition_name||' TABLESPACE NSW_NEW ONLINE;');
                end;
                end loop;
                end;    
            end if;
             END;     
       END LOOP;
end;