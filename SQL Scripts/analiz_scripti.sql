DECLARE
  dummy char(9);
begin
  SELECT '_'||TO_CHAR(SYSDATE,'YYYYMMDD') INTO dummy FROM dual;
  declare
  cursor c1 is  select TABLE_OWNER,TABLE_NAME,PARTITION_NAME  from dba_tab_partitions where PARTITION_NAME like '%'||dummy||'' and table_owner <> 'ARCHIVE';

BEGIN
FOR STR in c1
         LOOP
              BEGIN
  
  SYS.DBMS_STATS.GATHER_TABLE_STATS (
      OwnName        => str.table_owner
     ,TabName        => str.table_name
     ,PartName       => str.partition_name
    ,Granularity       => 'PARTITION'
    ,Estimate_Percent  => SYS.DBMS_STATS.AUTO_SAMPLE_SIZE
    ,Method_Opt        => 'FOR ALL INDEXED COLUMNS SIZE AUTO '
    ,DEGREE            => 4
    ,CASCADE           => TRUE
    ,No_Invalidate     => FALSE);
    
  END;     
       END LOOP;
END;
end;
/