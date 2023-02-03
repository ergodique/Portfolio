select tablespace_name, 
case when tablespace_name ='TSCSDMP01' then 'OCAK'
     when tablespace_name ='TSCSDMP02' then 'SUBAT'
     when tablespace_name ='TSCSDMP03' then 'MART'
     when tablespace_name ='TSCSDMP04' then 'NISAN'
     when tablespace_name ='TSCSDMP05' then 'MAYIS'
     when tablespace_name ='TSCSDMP06' then 'HAZIRAN'
     when tablespace_name ='TSCSDMP07' then 'TEMMUZ'
     when tablespace_name ='TSCSDMP08' then 'AGUSTOS'
     when tablespace_name ='TSCSDMP09' then 'EYLUL'
     when tablespace_name ='TSCSDMP10' then 'EKIM'
     when tablespace_name ='TSCSDMP11' then 'KASIM'
     when tablespace_name ='TSCSDMP12' then 'ARALIK'
     when tablespace_name ='TSCSDTP01' then 'PAZARTESI'
     when tablespace_name ='TSCSDTP02' then 'SALI'
     when tablespace_name ='TSCSDTP03' then 'CARSAMBA'
     when tablespace_name ='TSCSDTP04' then 'PERSEMBE'
     when tablespace_name ='TSCSDTP05' then 'CUMA'
     when tablespace_name ='TSCSDTP06' then 'CUMARTESI'
     when tablespace_name ='TSCSDTP07' then 'PAZAR'
end "AY_veya_GUN"
,round(sum(bytes)/(1024*1024*1024),0) GB
from dba_segments
where tablespace_name like 'TSCSD%'
group by tablespace_name
order by 1
;