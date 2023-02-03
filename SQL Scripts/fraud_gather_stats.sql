DECLARE
  dummy CHAR(9);
BEGIN
  SELECT 'P'||TO_CHAR(SYSDATE,'YYYYMMDD') INTO dummy FROM dual;
  SYS.DBMS_STATS.GATHER_TABLE_STATS (
      OwnName        => 'FRAUDSTAR'
     ,TabName        => 'AUTHORIZATIONS'
     ,PartName       => dummy
    ,Granularity       => 'PARTITION'
    ,Estimate_Percent  => SYS.DBMS_STATS.AUTO_SAMPLE_SIZE
    ,Method_Opt        => 'FOR ALL INDEXED COLUMNS SIZE AUTO '
    ,DEGREE            => 1
    ,CASCADE           => TRUE
    ,No_Invalidate     => FALSE);
END;
/



exec DBMS_STATS.GATHER_TABLE_STATS (
      OwnName        => 'FRAUDSTAR'
     ,TabName        => 'AUTHORIZATIONS'
     ,PartName       => 'P200607'
    ,Granularity       => 'GLOBAL'
    ,Estimate_Percent  => SYS.DBMS_STATS.AUTO_SAMPLE_SIZE
    ,Method_Opt        => 'FOR ALL INDEXED COLUMNS SIZE AUTO '
    ,DEGREE            => 4
    ,CASCADE           => TRUE
    ,No_Invalidate     => FALSE)
	
exec DBMS_STATS.GATHER_TABLE_STATS (
      OwnName        => 'FRAUDSTAR'
     ,TabName        => 'AUTHORIZATIONS'
    ,Granularity       => 'GLOBAL'
    ,Estimate_Percent  => SYS.DBMS_STATS.AUTO_SAMPLE_SIZE
    ,Method_Opt        => 'FOR ALL INDEXED COLUMNS SIZE AUTO '
    ,DEGREE            => 4
    ,CASCADE           => TRUE
    ,No_Invalidate     => FALSE)
	
DECLARE
  dummy CHAR(7);
BEGIN
  SELECT 'P'||TO_CHAR(SYSDATE,'YYYYMM') INTO dummy FROM dual;
  SYS.DBMS_STATS.GATHER_TABLE_STATS (
      OwnName        => 'FRAUDSTAR'
     ,TabName        => 'AUTHORIZATIONS'
     ,PartName       => dummy
    ,Granularity       => 'GLOBAL AND PARTITION'
    ,Estimate_Percent  => SYS.DBMS_STATS.AUTO_SAMPLE_SIZE
    ,Method_Opt        => 'FOR ALL INDEXED COLUMNS SIZE AUTO '
    ,DEGREE            => 4
    ,CASCADE           => TRUE
    ,No_Invalidate     => FALSE);
END;
/