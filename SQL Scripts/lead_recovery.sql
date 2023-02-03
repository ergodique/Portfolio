alter session set current_schema=CCSOWNER;

update pduser.queueitem T3 set T3.STATUSTEXT='INACTIVE'
where T3.ID IN
(
select T2.id
from
(select l.leadnumber from pduser.lead l inner join
(
select 
distinct(d.leadnumber) 
from
(
select  (substr(a.SERIALPROPERTYTEXT,b.instring,6))as leadnumber from pduser.queueitem a ,
(select id,(instr(SERIALPROPERTYTEXT,'LeadNumber',1,1)+ 24) as instring
from pduser.queueitem) b where a.id= b.id and statustext like  'ACTIVE'
) d
where
d.leadnumber not in (select (substr(m.SERIALPROPERTYTEXT,n.instring,6))as leadnumber from pduser.queueitem m ,
(select id,(instr(SERIALPROPERTYTEXT,'LeadNumber',1,1)+ 24) as instring
from pduser.queueitem) n where m.id= n.id and m.statustext like  'INACTIVE' )
) fqueue on l.leadnumber = fqueue.leadnumber where (stateid = 3 or stateid = 1 or stateid = 2) and EXPIRATIONDATE >= sysdate) T1
inner join
(select x.id, y.leadnumber
from
(
select d.leadnumber, d.id, d.LASTMODTIMSNUM
from 
(
select (substr(m.SERIALPROPERTYTEXT,n.instring,6))as leadnumber, m.LASTMODTIMSNUM, m.id from pduser.queueitem m ,
(select id,(instr(SERIALPROPERTYTEXT,'LeadNumber',1,1)+ 24) as instring
from queueitem) n where m.id= n.id and m.statustext like  'ACTIVE') d
where
d.leadnumber not in (
select (substr(m.SERIALPROPERTYTEXT,n.instring,6))as leadnumber from pduser.queueitem m ,
(select id,(instr(SERIALPROPERTYTEXT,'LeadNumber',1,1)+ 24) as instring
from pduser.queueitem) n where m.id= n.id and m.statustext like  'INACTIVE')) x
inner join
(
select f.leadnumber, max(f.LASTMODTIMSNUM) as LASTMODTIMSNUM
from 
(
select (substr(a.SERIALPROPERTYTEXT,b.instring,6))as leadnumber, a.LASTMODTIMSNUM, a.id from pduser.queueitem a ,
(select id,(instr(SERIALPROPERTYTEXT,'LeadNumber',1,1)+ 24) as instring
from pduser.queueitem) b where a.id= b.id and a.statustext like  'ACTIVE') f
where
f.leadnumber not in (
select (substr(a.SERIALPROPERTYTEXT,b.instring,6))as leadnumber from pduser.queueitem a ,
(select id,(instr(SERIALPROPERTYTEXT,'LeadNumber',1,1)+ 24) as instring
from pduser.queueitem) b where a.id= b.id and a.statustext like  'INACTIVE') group by f.leadnumber) y 
on 
(x.leadnumber=y.leadnumber and x.LASTMODTIMSNUM=y.LASTMODTIMSNUM) ) T2
on T1.leadnumber = T2.leadnumber
);
commit;