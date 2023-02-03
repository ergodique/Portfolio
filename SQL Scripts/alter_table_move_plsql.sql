declare

cursor c1 is  select owner,segment_name,max(block_id) from dba_extents
where tablespace_name= 'SWITCH'
and segment_type in ('TABLE')
group by owner,segment_name
order by max(block_id) desc;

begin       
       FOR STR in c1
         LOOP
              BEGIN
                      dbms_output.put_line ('ALTER TABLE '||str.owner||'.'||str.segment_name||' MOVE TABLESPACE SWITCH_NEW;');
                declare
                cursor c2 is select owner,index_name from dba_indexes where tablespace_name = 'SWITCH' and table_name = str.segment_name ;
                begin
                for str2 in c2
                loop 
                begin
                dbms_output.put_line ('ALTER index '||str2.owner||'.'||str2.index_name||' rebuild TABLESPACE SWITCH_NEW ONLINE;');
                end;
                end loop;
                end;
           END;   
       END LOOP;
end;