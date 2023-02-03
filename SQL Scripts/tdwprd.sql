/* Formatted on 17.04.2012 14:52:39 (QP5 v5.139.911.3011) */
  SELECT COUNT ("Atomize"),
         "Atomize",
         ITMUSER.DATEFORM (SUBSTR ("Global_Timestamp", 1, 7), 'M') AS Timestamp
    FROM ITMUSER."Status_History"
   WHERE "Situation_Name" LIKE '%_da_is' AND ("Atomize" LIKE '%SQL08%')
GROUP BY ITMUSER.DATEFORM (SUBSTR ("Global_Timestamp", 1, 7), 'M'), "Atomize"
ORDER BY 3 DESC;


  SELECT "Atomize",
         itmuser.dateform (SUBSTR ("Global_Timestamp", 1, 7), 'M') AS TIMESTAMP
    FROM itmuser."Status_History"
   WHERE "Situation_Name" LIKE '%_da_is' AND ("Atomize" LIKE '%SQL08%')
ORDER BY 2 DESC;


/* Formatted on 17.04.2012 14:52:43 (QP5 v5.139.911.3011) */
  SELECT a.*,
         "Atomize",
         ITMUSER.DATEFORM (SUBSTR ("Global_Timestamp", 1, 15), 'H')
            AS Timestamp
    FROM ITMUSER."Status_History" a
   WHERE ("Atomize" LIKE '%wait%')
ORDER BY 2 DESC;


/* Formatted on 17.04.2012 14:52:48 (QP5 v5.139.911.3011) */
  SELECT "Atomize",
         ITMUSER.DATEFORM (SUBSTR ("Global_Timestamp", 1, 15), 'H')
            AS Timestamp
    FROM ITMUSER."Status_History" a
   WHERE "Situation_Name" LIKE '%_da_is'
ORDER BY 2 DESC;