BEGIN
  SYS.DBMS_STATS.GATHER_SCHEMA_STATS (
     OwnName           => 'FRAUDSTAR'
    ,Granularity       => 'ALL'
    ,Options           => 'GATHER'
    ,Estimate_Percent  => 1
    ,Method_Opt        => 'FOR ALL INDEXED COLUMNS SIZE AUTO'
    ,Degree            => 4
    ,Cascade           => TRUE
    ,No_Invalidate     => FALSE);
END;
/

