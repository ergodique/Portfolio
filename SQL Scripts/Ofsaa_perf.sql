SELECT 
/*+PARALLEL(8)*/
         SAW_SRC_PATH,
         FIZIKSEL_LOG_TABLOSU.TIME_SEC,
           FIZIKSEL_LOG_TABLOSU.START_TS as db_baslangic_saati, 
              FIZIKSEL_LOG_TABLOSU.END_TS as db_bitis_saati
              --FIZIKSEL_LOG_TABLOSU.*
         --trunc(avg(FIZIKSEL_LOG_TABLOSU.TIME_SEC)) AS AVG_DB_SORGU_SURESI,
           --     max(FIZIKSEL_LOG_TABLOSU.TIME_SEC) AS MAX_DB_SORGU_SURESI,
             --   count(*) AS CAGRILMA_SAYISI
    FROM /* OBIEE_BIPLATFORM.S_NQ_ACCT TABLOSU LOJÝK SORGULARIN LOGLARINI TUTMAKTADIR */
        OBIEE_BIPLATFORM.S_NQ_ACCT LOJIK_LOG_TABLOSU 
        INNER JOIN /* OBIEE_BIPLATFORM.S_NQ_DB_ACCT TABLOSU FÝZÝKSEL SORGULARIN LOGLARINI TUTMAKTADIR */
          OBIEE_BIPLATFORM.S_NQ_DB_ACCT FIZIKSEL_LOG_TABLOSU
       ON LOJIK_LOG_TABLOSU.ID = FIZIKSEL_LOG_TABLOSU.LOGICAL_QUERY_ID
   WHERE     LOJIK_LOG_TABLOSU.START_DT =to_date( '10.08.2015','DD.MM.YYYY')
         AND LOJIK_LOG_TABLOSU.START_TS BETWEEN TO_DATE ('10.08.2015 09:00:00',
                                       'DD.MM.YYYY HH24:MI:SS')
                          AND TO_DATE ('10.08.2015 11:00:00',
                                       'DD.MM.YYYY HH24:MI:SS')
                                       and FIZIKSEL_LOG_TABLOSU.TIME_SEC>=300
         AND LOJIK_LOG_TABLOSU.QUERY_SRC_CD = 'Report'
         --and    SAW_SRC_PATH like '%Bireysel HYO Tarihsel Geliþim%'
                  AND    (   
        LOJIK_LOG_TABLOSU.SAW_DASHBOARD IN ( '/shared/02 Branch Reports/_portal/01 Branch Dashboard','/shared/01-2 Branch Users/_portal/01 Branch Dashboard' )
)
--GROUP BY LOJIK_LOG_TABLOSU.SAW_SRC_PATH
ORDER BY 3
