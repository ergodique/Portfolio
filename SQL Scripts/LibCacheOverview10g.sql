REM   Run this logged in to user with SYSDBA privs ideal
REM
REM   Runs against 10g Release 2/ 11g
REM   Output spooled to overview.out

set pagesize 999
set lines 70
set verify off
set heading off
set feedback off
set termout off

col start_up format a45 justify right
col sp_size     format          999,999,999 justify right
col x_sp_used   format          999,999,999 justify right
col sp_used_shr format          999,999,999 justify right
col sp_used_per format          999,999,999 justify right
col sp_used_run format          999,999,999 justify right
col sp_avail    format          999,999,999 justify right
col sp_sz_pins format           999,999,999 justify right
col sp_no_pins format           999,999 justify right
col sp_no_obj format            999,999 justify right
col sp_no_stmts format          999,999 justify right
col sp_sz_kept_chks format      999,999,999 justify right
col sp_no_kept_chks format      999,999 justify right
col 1time_sum_pct     format      999 justify right
col 1time_ttl_pct   format        999 justify right
col ltime_ttl     format   999,999,999 justify right
col 1time_sum     format      999,999,999,999 justify right
col tot_lc format  999,999,999,999 justify right
col sp_free format 999,999,999,999 justify right

col val1 new_val x_sgasize noprint
col val2 new_val x_sp_size noprint
col val3 new_val x_lp_size noprint
col val4 new_val x_jp_size noprint
col val5 new_val x_bc_size noprint
col val6 new_val x_other_size noprint
col val7 new_val x_str_size noprint
col val8 new_val x_KGH noprint
select val1, val2, val3, val4, val5, val6, val7, val8
from (select sum(bytes) val1 from v$sgastat) s1,
    (select nvl(sum(bytes),0) val2 from v$sgastat where pool='shared pool') s2,
    (select nvl(sum(bytes),0) val3 from v$sgastat where pool='large pool') s3,
    (select nvl(sum(bytes),0) val4 from v$sgastat where pool='java pool') s4,
    (select nvl(sum(bytes),0) val5 from v$sgastat where name='buffer_cache') s5,
    (select nvl(sum(bytes),0) val6 from v$sgastat where name in ('log_buffer','fixed_sga')) s6,
    (select nvl(sum(bytes),0) val7 from v$sgastat where pool='streams pool') s7,
    (select nvl(sum(bytes),0) val8 from v$sgastat where pool='shared pool' and name='KGH: NO ACCESS') s8;

col val1 new_val x_sp_used noprint
col val2 new_val x_sp_used_shr noprint
col val3 new_val x_sp_used_per noprint
col val4 new_val x_sp_used_run noprint
col val5 new_val x_sp_no_stmts noprint
col val6 new_val x_sp_vers noprint
select sum(sharable_mem+persistent_mem+runtime_mem) val1,
            sum(sharable_mem) val2, sum(runtime_mem) val4, sum(persistent_mem) val3,
            count(*) val5, max(version_count) val6
from   v$sqlarea;

col val1 new_val x_1time_sum noprint
col val2 new_val x_1time_ttl noprint
select sum(sharable_mem+persistent_mem+runtime_mem) val1,
   count(*) val2
from   v$sqlarea
where executions=1;

col val1 new_val x_ra noprint
select round(nvl((used_space+free_space),0),2) val1
from v$shared_pool_reserved;

col val2 new_val x_sp_no_obj noprint
select count(*) val2 from v$db_object_cache; 

col val2 new_val x_sp_no_kept_chks noprint
col val3 new_val x_sp_sz_kept_chks noprint
select decode(count(*),'',0,count(*)) val2,
       decode(sum(sharable_mem),'',0,sum(sharable_mem)) val3
from   v$db_object_cache
where  kept='YES';

col val2 new_val x_sp_free_chks noprint
select sum(bytes) val2 from v$sgastat
where name='free memory' and pool='shared pool';

col val2 new_val x_sp_no_pins noprint
select count(*) val2
from v$session a, v$sqltext b
where a.sql_address||a.sql_hash_value = b.address||b.hash_value;

col val2 new_val x_sp_sz_pins noprint
select sum(sharable_mem+persistent_mem+runtime_mem) val2
from   v$session a,
       v$sqltext b,
       v$sqlarea c
where  a.sql_address||a.sql_hash_value = b.address||b.hash_value and
       b.address||b.hash_value = c.address||c.hash_value;

col val3 new_val x_tot_lc noprint
select nvl(sum(lc_inuse_memory_size)+sum(lc_freeable_memory_size),0) val3 
from v$library_cache_memory;

col val2 new_val x_sp_avail noprint
select &x_sp_size-(&x_tot_lc*1024*1024)-&x_sp_used val2
from   dual;

col val2 new_val x_sp_other noprint
select &x_sp_size-(&x_tot_lc*1024*1024) val2 
from dual;

col val1 new_val x_trend_4031 noprint
col val2 new_val x_trend_size noprint
col val3 new_val x_trend_rS noprint
col val4 new_val x_trend_rs_size noprint
select request_misses val1,
decode(request_misses,0,0,last_Miss_Size) val2,
request_failures val3,
decode(request_failures,0,0,last_failure_size) val4
from v$shared_pool_reserved;

set termout on
set heading off

ttitle -
  center  'SGA/Shared Pool Breakdown'  skip 2
spool overview.out
select  ' *** If database started recently, this data is not as useful ***',
       '                                    ',
        'Database Started:  '||to_char(startup_time, 'Mon/dd/yyyy hh24:mi:ss') start_up,
        'Instance Name/No:     '||instance_name||'-'||instance_number,
       '                                    ',
        'Breakdown of SGA           '||round((&x_sgasize/1024/1024),2)||'M   ',
        '   Shared Pool Size          : '
               ||round((&x_sp_size/1024/1024),2)||'M ('
                  ||round((&x_sp_size/&x_sgasize)*100,0)||'%)  Reserved ' 
                ||round((&x_ra/1024/1024),2)||'M ('
                ||round((&x_ra/&x_sp_size)*100,0)||'%)' sp_size,
        '   Large Pool                       : '||round((&x_lp_size/1024/1024),2)||'M ('
             ||round((&x_lp_size/&x_sgasize)*100,0)||'%)',
        '   Java Pool                        : '||round((&x_jp_size/1024/1024),2)||'M ('
             ||round((&x_jp_size/&x_sgasize)*100,0)||'%)',
        '   Buffer Cache                     : '||round((&x_bc_size/1024/1024),2)||'M ('
             ||round((&x_bc_size/&x_sgasize)*100,0)||'%)',
        '   Streams Pool                     : '||round((&x_str_size/1024/1024),2)||'M ('
             ||round((&x_str_size/&x_sgasize)*100,0)||'%)',
        '   Other Areas in SGA               : '||round((&x_other_size/1024/1024),2)||'M ('
             ||round((&x_other_size/&x_sgasize)*100,0)||'%)',
        '                                    ',
        ' *** High level breakdown of memory ***',
        '                                    ',
        '     sharable                      :  '
                ||round((&x_sp_used_shr/1024/1024),2)||'M' sp_used_shr,
        '     persistent                    :  '
                ||round((&x_sp_used_per/1024/1024),2)||'M' sp_used_per,
        '     runtime                       :  '
                ||round((&x_sp_used_run/1024/1024),2)||'M' sp_used_run,
        '                                    ',
        'SQL Memory Usage (total)                     : '
                ||round((&x_sp_used/1024/1024),2)||'M ('
                ||round((&x_sp_used/&x_sp_size)*100,0)||'%)',
        '                                    ',
        ' *** No guidelines on SQL in Library Cache, but if ***',
        ' *** pinning a lot of code--may need larger Shared Pool ***',
        '                                    ',
       '# of SQL statements                : '
                ||&x_sp_no_stmts sp_no_stmts,
       '# of pinned SQL statements         : '
                ||&x_sp_no_pins sp_no_pins,
       '# of programmatic constructs       : '
                ||&x_sp_no_obj sp_no_obj,
       '# of pinned programmatic construct : '
                ||&x_sp_no_kept_chks sp_no_kept_chks,
        '                                    ',
        'Efficiency Analysis:                     ',
       ' *** High versions (100s) could be bug ***',
        '                                    ',
        '  Max Child Cursors Found                              : '||&x_sp_vers,
        '  Programmatic construct memory size (Kept)            : '
                ||round((&x_sp_sz_kept_chks/1024/1024),2)||'M' sp_sz_kept_chks,
        '  Pinned SQL statements memory size (active sessions)  : '
                ||round((&x_sp_sz_pins/1024/1024),2)||'M' sp_sz_pins,
        '                                    ',
        ' *** LC at 50% or 60% of Shared Pool not uncommon ***',
        '                                    ',
        '  Estimated Total Library Cache Memory Usage  : '||&x_tot_lc||'M ('||
               100*(round(((&x_tot_lc) / (&x_sp_size/1024/1024)),2))||'%)' perc_lc,       
        '  Other Shared Pool Memory                    : '||
                round((&x_sp_other/1024/1024),2)||'M',
        '  Shared Pool Free Memory Chunks              : '||
                round(((&x_sp_free_chks) /1024/1024),2)||'M ('||
                100*(round((&x_sp_free_chks / &x_sp_size),2))||'%)' perc_free,
        '                                    ',
        ' ****Ideal percentages for 1 time executions is 20% or lower****     ',
        '                                    ',
        '  # of objects executed only 1 time           : '||&x_1time_ttl||' ('||
                100*round(((&x_1time_ttl / &x_sp_no_stmts)),2)||'%)',
        '  Memory for 1 time executions:               : '||
                round((&x_1time_sum/1024/1024),2)||'M ('||
                100*round(((&x_1time_sum / &x_sp_used)),2)||'%)',
        '                                    ',
        '  ***If these chunks are growing, SGA_TARGET may be too low***',
        '                                    ',
        '  Current KGH: NO ACCESS Allocations:  '||round((&x_KGH/1024/1024),2)||'M ('
             ||100*round((&x_KGH/&x_sp_size),2)||'%)',
        '                                    ',
        ' ***0 misses is ideal, but if growing value points to memory issues***',
        '                                    ',
        '  # Of Misses for memory                      : '|| &x_trend_rs,
        '  Size of last miss                           : '|| &x_trend_rs_size,
        '  # Of Misses for Reserved Area               : '|| &x_trend_4031,
        '  Size of last miss Reserved Area             : '|| &x_trend_size
from    v$instance;

spool off
ttitle off
set heading on 
set feedback on
clear col
