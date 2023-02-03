select distinct db_adi from cqvtis.as_vt_is_talebi
order by 1;

select db_adi,count(*) as BI_COUNT from cqvtis.as_vt_is_talebi a
where a.GIRISTARIHI > sysdate - 365
and a.DB_ADI in (
'ACHTPPRD',
'DWPRD',
'ABMPRD',
'BDWPRD',
'BDWPRDRO',
'TDWPRD',
'SPSSPRD',
'NWLOGPRD',
'ACTPRD',
'ORAHRPRD',
'DBDWH',
'DBMUH',
'ARSIV',
'ETLPRD',
'ETLPRODS1',
'ETLPRODS3'
)
group by db_adi
order by 2 desc;


select db_adi,count(*) as OLTP_COUNT from cqvtis.as_vt_is_talebi a
where a.GIRISTARIHI > sysdate - 365
and a.DB_ADI in (
'OLPRD',
'BFRPRD',
'SAFIRPRD',
'ODAKPRD',
'IBMRPM',
'OCTIGATEPRD',
'CCMDBPRD',
'TADDMPRD',
'BSCPRD',
'CRMPRD',
'EFORMPRD',
'ESAPRD',
'ISSPRD',
'CCCQPRD',
'CHSPRD',
'ALGOPRD',
'KYPPRD',
'FRAUD',
'UTF8PRD',
'RACPR',
'DB2PROD',
'SINERJI',
'SINERJIPRD',
'IsYProd',
'SQLPRD'
)
group by db_adi
order by 2 desc