--izleme ekraný
select 'Mesaj sayisi',count(*) "a"
from
(
select rrn,
input,output,
substr((to_char(output-input,'DD.MM.YYYY HH24:MI:SS,FF')),18,2)||substr((to_char(output-input,'DD.MM.YYYY HH24:MI:SS,FF')),21,3) sure
from (
select rrn,to_timestamp(input_time,'YYYYMMDDHH24MISSFF') input ,to_timestamp(output_time,'YYYYMMDDHH24MISSFF') output from
(
select grs.rrn rrn,grs.sys_ins_time,grs.sys_ins_msec,cks.sys_ins_time,cks.sys_ins_msec,'20070215'||grs.sys_ins_time||grs.sys_ins_msec input_time,
'20070215'||cks.sys_ins_time||cks.sys_ins_msec output_time
from host.host_conn_trnx_log grs, host.host_conn_trnx_log cks
where grs.rrn=cks.rrn and 
grs.dest='SW' and
cks.source='SW' and
grs.process_date=20070215 and
cks.process_date=20070215 and
--grs.rrn=625711107389 and
grs.sys_ins_time between :BASLANGIC and 183000 and
cks.sys_ins_time between :BASLANGIC and 183000)))
union all
select 'timeout 1 sn den buyuk',sum(say) "a"  from (
select sure,count(*) say
from
(
select rrn,
input,output,
substr((to_char(output-input,'DD.MM.YYYY HH24:MI:SS,FF')),18,2)||substr((to_char(output-input,'DD.MM.YYYY HH24:MI:SS,FF')),21,3) sure
from (
select rrn,to_timestamp(input_time,'YYYYMMDDHH24MISSFF') input ,to_timestamp(output_time,'YYYYMMDDHH24MISSFF') output from
(
select grs.rrn rrn,grs.sys_ins_time,grs.sys_ins_msec,cks.sys_ins_time,cks.sys_ins_msec,'20070215'||grs.sys_ins_time||grs.sys_ins_msec input_time,
'20070215'||cks.sys_ins_time||cks.sys_ins_msec output_time
from host.host_conn_trnx_log grs, host.host_conn_trnx_log cks
where grs.rrn=cks.rrn and 
grs.dest='SW' and
cks.source='SW' and
grs.process_date=20070215 and
cks.process_date=20070215 and
--grs.rrn=625711107389 and
grs.sys_ins_time between :BASLANGIC and 183000 and
cks.sys_ins_time between :BASLANGIC and 183000)))
group by sure
having sure > 1000
)
union all
select 'timeout 2 sn den buyuk',sum(say) "a"  from (
select sure,count(*) say
from
(
select rrn,
input,output,
substr((to_char(output-input,'DD.MM.YYYY HH24:MI:SS,FF')),18,2)||substr((to_char(output-input,'DD.MM.YYYY HH24:MI:SS,FF')),21,3) sure
from (
select rrn,to_timestamp(input_time,'YYYYMMDDHH24MISSFF') input ,to_timestamp(output_time,'YYYYMMDDHH24MISSFF') output from
(
select grs.rrn rrn,grs.sys_ins_time,grs.sys_ins_msec,cks.sys_ins_time,cks.sys_ins_msec,'20070215'||grs.sys_ins_time||grs.sys_ins_msec input_time,
'20070215'||cks.sys_ins_time||cks.sys_ins_msec output_time
from host.host_conn_trnx_log grs, host.host_conn_trnx_log cks
where grs.rrn=cks.rrn and 
grs.dest='SW' and
cks.source='SW' and
grs.process_date=20070215 and
cks.process_date=20070215 and
--grs.rrn=625711107389 and
grs.sys_ins_time between :BASLANGIC and 183000 and
cks.sys_ins_time between :BASLANGIC and 183000)))
group by sure
having sure > 2000
);

select 'süre' ,substr(max(output)-min(input),15,7) "a"
from (
select rrn,to_timestamp(input_time,'YYYYMMDDHH24MISSFF') input ,to_timestamp(output_time,'YYYYMMDDHH24MISSFF') output from
(
select grs.rrn rrn,grs.sys_ins_time,grs.sys_ins_msec,cks.sys_ins_time,cks.sys_ins_msec,'20070215'||grs.sys_ins_time||grs.sys_ins_msec input_time,
'20070215'||cks.sys_ins_time||cks.sys_ins_msec output_time
from host.host_conn_trnx_log grs, host.host_conn_trnx_log cks
where grs.rrn=cks.rrn and 
grs.dest='SW' and
cks.source='SW' and
grs.process_date=20070215 and
cks.process_date=20070215 and
--grs.rrn=625711107389 and
grs.sys_ins_time between :BASLANGIC and 183000 and
cks.sys_ins_time between :BASLANGIC and 183000));






select f39,count(*) from switch.trnx_log where sys_ins_date=20070215 and sys_ins_time > :BASLANGIC
group by f39;


