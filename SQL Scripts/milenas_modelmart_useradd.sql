select * from mmadmin.mmuser where servername like 'SE%' or servername like 'IS9%'

SELECT    'INSERT INTO MMADMIN.MMPROFILEASSIGNMENT VALUES (65539,'  -- MODELER
       || a.USERID
       || ',296547);'  -- UYGULAMALAR TEST -> MILENAS
  FROM mmadmin.mmuser a
 WHERE a.servername LIKE 'Se%' OR a.servername LIKE 'IS9%'
UNION ALL
SELECT    'INSERT INTO MMADMIN.MMPROFILEASSIGNMENT VALUES (65539,' -- MODELER
       || a.USERID
       || ',349796);'  -- UYGULAMALAR PROD -> MILENAS
  FROM mmadmin.mmuser a
 WHERE a.servername LIKE 'Se%' OR a.servername LIKE 'IS9%'
UNION ALL
SELECT    'INSERT INTO MMADMIN.MMPROFILEASSIGNMENT VALUES (65540,' -- VIEWER
       || a.USERID
       || ',0);'  -- TÜM MODELMART
  FROM mmadmin.mmuser a
 WHERE a.servername LIKE 'Se%' OR a.servername LIKE 'IS9%'
 
 
SELECT A.OBJECTID, A.OBJECTNAME FROM MMADMIN.MMLIBRARY A WHERE A.OBJECTNAME LIKE 'Milenas_T%'

SELECT DISTINCT USERID FROM MMADMIN.MMPROFILEASSIGNMENT