declare
h1   NUMBER;
table_name VARCHAR2(100);
CURSOR table_names IS SELECT tablename,tip FROM creditdb.tables_to_import;
 begin
  FOR table_name IN table_names LOOP
     h1 := sys.dbms_datapump.open (operation => 'IMPORT', job_mode => 'SCHEMA', remote_link => 'DBKYPTS.REGRESS.RDBMS.DEV.US.ORACLE.COM', version => 'COMPATIBLE'); 
     sys.dbms_datapump.set_parallel(handle => h1, degree => 1); 
     sys.dbms_datapump.add_file(handle => h1, filename => 'IMPORT.LOG', directory => 'IMPORT_ODAK_DIR', filetype => 3); 
     sys.dbms_datapump.set_parameter(handle => h1, name => 'KEEP_MASTER', value => 0); 
     sys.dbms_datapump.metadata_filter(handle => h1, name => 'SCHEMA_EXPR', value => 'IN(''SMODEL'')'); 
	 sys.dbms_datapump.metadata_filter(handle => h1, name => 'NAME_EXPR', value => 'IN('''||table_name.tablename||''')', object_type => 'TABLE'); 
	 SYS.dbms_datapump.metadata_filter(handle => h1, name => 'INCLUDE_PATH_EXPR', value => 'IN(''TABLE'')');
	 sys.dbms_datapump.metadata_filter(handle => h1, name => 'NAME_EXPR', value => 'IN('''||table_name.tablename||''')', object_type => 'SEQUENCE'); 
	 SYS.dbms_datapump.metadata_filter(handle => h1, name => 'INCLUDE_PATH_EXPR', value => 'IN(''SEQUENCE'')');
     sys.dbms_datapump.set_parameter(handle => h1, name => 'ESTIMATE', value => 'BLOCKS');  
     sys.dbms_datapump.set_parameter(handle => h1, name => 'INCLUDE_METADATA', value => 1); 
  if table_name.tip = 'DDL' then
     sys.dbms_datapump.data_filter(handle => h1, name => 'INCLUDE_ROWS', value => 1); 
  end if; 
     sys.dbms_datapump.set_parameter(handle => h1, name => 'TABLE_EXISTS_ACTION', value => 'REPLACE'); 
     sys.dbms_datapump.set_parameter(handle => h1, name => 'SKIP_UNUSABLE_INDEXES', value => 0); 
     sys.dbms_datapump.start_job(handle => h1, skip_current => 0, abort_step => 0); 
     sys.dbms_datapump.detach(handle => h1); 
  end loop;
  end;
/
