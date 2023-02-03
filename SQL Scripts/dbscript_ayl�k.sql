SELECT   trunc (entry_date) ,COUNT (*)
    FROM dbscript.scripts ds
   --WHERE ds.cq_request_id IS NOT NULL
GROUP BY trunc(entry_date)
ORDER BY  1 desc;

/* Formatted on 2009/08/28 15:16 (Formatter Plus v4.8.8) */
SELECT   EXTRACT (MONTH FROM entry_date) MONTH,
         EXTRACT (YEAR FROM entry_date) YEAR, COUNT (*)
    FROM dbscript.scripts ds
   WHERE ds.cq_request_id IS NOT NULL --AND ds.state = 'S'
GROUP BY EXTRACT (MONTH FROM entry_date), EXTRACT (YEAR FROM entry_date)
ORDER BY 2, 1;

-- en cok istek girenler
SELECT   entered_by,count(*)
    FROM dbscript.scripts ds
   WHERE ds.cq_request_id IS NOT NULL --AND ds.state = 'S'
and DS.ENTRY_DATE > sysdate -365
group by entered_by
order by 2 desc;


--en cok istek girilen db ler
SELECT   DD.SHORTNAME  ,count(*)
    FROM dbscript.scripts ds, dbscript.databases dd
   WHERE ds.cq_request_id IS NOT NULL --AND ds.state = 'S'
   and DD.ID = DS.DATABASE_ID
and DS.ENTRY_DATE > sysdate -365
group by DD.SHORTNAME
order by 2 desc


--en cok istek girilen db ler ve giren kisiler
SELECT   DS.ENTERED_BY, DD.SHORTNAME,count(*)
    FROM dbscript.scripts ds, dbscript.databases dd
   WHERE ds.cq_request_id IS NOT NULL --AND ds.state = 'S'
   and DD.ID = DS.DATABASE_ID
   --and DD.SHORTNAME =  'TRNPRD'
and DS.ENTRY_DATE > sysdate -31
group by DS.ENTERED_BY,DD.SHORTNAME
order by 3 desc