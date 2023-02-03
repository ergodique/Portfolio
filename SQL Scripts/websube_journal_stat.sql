DECLARE
  dummy CHAR(9);
BEGIN
  SELECT 'P'||TO_CHAR(SYSDATE,'YYYYMMDD') INTO dummy FROM dual;
  SYS.DBMS_STATS.GATHER_TABLE_STATS (
      OwnName        => 'WEBSUBE'
     ,TabName        => 'JOURNAL'
     ,PartName       => dummy
    ,Granularity       => 'PARTITION'
    ,Estimate_Percent  => 1
    ,Method_Opt        => 'FOR ALL INDEXED COLUMNS SIZE AUTO '
    ,DEGREE            => 1
    ,CASCADE           => TRUE
    ,No_Invalidate     => FALSE);
END;
/

