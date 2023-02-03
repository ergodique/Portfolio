-- pos_trnx_info
select P.error_msg msg,sys_entry_time, p.source_fui,p.f37,p.orig_f37, p.f39,f39_auth, p.INT_RES_CODE INT_RC,
p.* 
from posmrc.pos_trnx_info p
where 1=1 
and process_date =:pi_trnx_date
and sys_entry_time > 040000
order by p.process_date desc, p.sys_entry_time desc;

-- pos_trnx_info
select P.error_msg msg,sys_entry_time, p.source_fui,p.f37,p.orig_f37, p.f39,f39_auth, p.INT_RES_CODE INT_RC,
p.* 
from posmrc.pos_trnx_declined_info p
where 1=1 
and process_date =:pi_trnx_date
and sys_entry_time > 040000
order by p.process_date desc, p.sys_entry_time desc;


select a.f39, a.f2, a.MTI, a.* from host.host_trnx a
where process_date=:pi_trnx_date
and sys_time > 040000
order by sys_time desc;
