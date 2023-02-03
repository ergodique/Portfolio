declare
h1   NUMBER;
table_name VARCHAR2(100);
CURSOR table_names IS SELECT tablename,tip FROM so46905.streams2;
 begin
      FOR table_name IN table_names LOOP
  begin 
     h1 := dbms_datapump.open (operation => 'IMPORT', job_mode => 'TABLE', remote_link => 'RACAR.REGRESS.RDBMS.DEV.US.ORACLE.COM', version => 'COMPATIBLE'); 
  end;
  begin 
     dbms_datapump.set_parallel(handle => h1, degree => 1); 
  end;
  begin 
     dbms_datapump.add_file(handle => h1, filename => 'IMPORT.LOG', directory => 'IMPORT_ODAK_DIR', filetype => 3); 
  end;
  begin 
     dbms_datapump.set_parameter(handle => h1, name => 'KEEP_MASTER', value => 0); 
  end;
  begin 
     dbms_datapump.metadata_filter(handle => h1, name => 'SCHEMA_EXPR', value => 'IN(''SO46905'')'); 
  end;
  begin 
     dbms_datapump.metadata_filter(handle => h1, name => 'NAME_EXPR', value => 'IN('''||table_name.tablename||''')'); 
  end;
  begin 
     dbms_datapump.set_parameter(handle => h1, name => 'ESTIMATE', value => 'BLOCKS'); 
  end;
  begin 
     dbms_datapump.set_parameter(handle => h1, name => 'INCLUDE_METADATA', value => 1); 
  end;
  if table_name.tip = 'DDL' then
  begin 
     dbms_datapump.data_filter(handle => h1, name => 'INCLUDE_ROWS', value => 1); 
  end;
  end if; 
  begin 
     dbms_datapump.set_parameter(handle => h1, name => 'TABLE_EXISTS_ACTION', value => 'REPLACE'); 
  end;
  begin 
     dbms_datapump.set_parameter(handle => h1, name => 'SKIP_UNUSABLE_INDEXES', value => 0); 
  end;
  begin 
     dbms_datapump.start_job(handle => h1, skip_current => 0, abort_step => 0); 
  end;
  begin 
     dbms_datapump.detach(handle => h1); 
  end;
  end loop;
end;
/
