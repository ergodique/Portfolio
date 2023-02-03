
REM  AnalyzeNonShared.sql
REM  Single use SQL (nonshared)
REM  
REM  The goal in the Library Cache is to reuse SQL
REM  The code listed here may need further investigation
REM
REM  

REM  
REM Pointer:   The total memory for non-shared SQL statements should not exceed
REM                20% of the Shared Pool.   If this percentage is much larger than that
REM                then efforts should be made to decrease the non-shared code in the
REM                application.



set serveroutput on

declare
   SHPSIZE number;
   SV number;
   IV number;
   NUM_SQL number;
   NUM_EX1 number;
   TTLBYTES number;
   EX1_MEMORY number;

   cursor c1 is select bytes/1024/1024 from v$sgainfo where name='Shared Pool Size';
   cursor c2 is select to_number(b.ksppstvl)/1024/1024, to_number(c.ksppstvl)/1024/1024
      from x$ksppi a, x$ksppcv b, x$ksppsv c
      where a.indx = b.indx and a.indx = c.indx and a.ksppinm in ('__shared_pool_size')
      order by 1;
   cursor c3 is select count(1), sum(decode(executions,1,1,0)),
      round(sum(sharable_mem)/1024/1024,0), round(sum(decode(executions, 1, sharable_mem/1024/1024)),0)
      from v$sqlarea where sharable_mem > 0;

begin 

   open c1;
     fetch c1 into SHPSIZE;
     dbms_output.put_line('Explicit/Minimum Setting:  '||SHPSIZE);
   close c1;

   open c2;
     fetch c2 into SV, IV;
     dbms_output.put_line('Auto-tuned Setting Currently:  '||SV);
   close c2;

   open c3;
     fetch c3 into NUM_SQL, NUM_EX1, TTLBYTES, EX1_MEMORY;
     dbms_output.put_line('   ---   Analysis: (Memory Shown in MBytes)');
     dbms_output.put_line('   =======================================');
     dbms_output.put_line('  ............... Stored Objects:  '||NUM_SQL);
     dbms_output.put_line('  ....................... Memory for All Objects:  '||TTLBYTES);
     dbms_output.put_line('  ............... Run Only Once:   '||NUM_EX1);
     dbms_output.put_line('  ....................... Memory for Non-Shared Code: '||EX1_MEMORY);
   close c3;
     dbms_output.put_line(' ');
     dbms_output.put_line('   ...Ideal < 20% .... Actual: '||round(100*(EX1_MEMORY / TTLBYTES), 0));
end;
/

spool off
