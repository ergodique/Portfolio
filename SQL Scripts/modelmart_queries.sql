/* Formatted on 2006/03/23 16:13 (Formatter Plus v4.8.6) */
SELECT   classid, ispersistenceunit
    FROM mmclass
   WHERE iscontainer <> 0 AND clientid = 1
ORDER BY ispersistenceunit DESC

/* Formatted on 2006/03/23 16:13 (Formatter Plus v4.8.6) */
-- list modelmart libraries
SELECT   o.objectid "Object Id", l.objectname "Object Name",
         o.classid "Class Id", o.containerid "Container Id",
         l.createdby "Created By", l.created "Created",
         l.updatedby "Updated By", l.updated "Updated",
         l.specialobjectcount "Entity Count", l.objectcount "Object Count",
         TO_NUMBER (NULL) "Model Type", l.isarchive "Is Archive",
         o.originid "Origin Id", TO_NUMBER (NULL) "Is Template",
         TO_NUMBER (NULL) "Model Group", 1 "depth", TO_NUMBER (NULL) "owner",
         NULL "Model Group Name", TO_NUMBER (NULL) "Lock Type",
         TO_NUMBER (NULL) "Session Id", TO_NUMBER (NULL) "Description"
    FROM mmobject o, mmlibrary l
   WHERE o.classid = 2 AND l.objectid = o.objectid
ORDER BY 17, 2

/* Formatted on 2006/03/23 16:13 (Formatter Plus v4.8.6) */
SELECT DISTINCT o.objectid "Object Id", l.objectname "Object Name",
                o.classid "Class Id", o.containerid "Container Id",
                l.createdby "Created By", l.created "Created",
                l.updatedby "Updated By", l.updated "Updated",
                l.specialobjectcount "Entity Count",
                l.objectcount "Object Count", p.intvalue "Model Type",
                l.isarchive "Is Archive", o.originid "Origin Id",
                DECODE (ff.intvalue, 4016, 1, 0) "Is Template",
                DECODE (o.classid,
                        21, o.objectid,
                        o.containerid
                       ) "Model Group",
                2 "depth", TO_NUMBER (NULL) "owner",
                DECODE (o.classid,
                        21, l.objectname,
                        NVL (l2.objectname, ' ')
                       ) "Model Group Name",
                lck.locktype "Lock Type",
                DECODE (lck.locktype,
                        'E', -1,
                        'S', -1,
                        lck.sessionid
                       ) "Session Id",
                dsc.stringvalue "Description"
           FROM mmobject o,
                mmvmodelobject l,
                mmvmodelobject l2,
                mmobjectproperty p,
                mmobjectproperty ff,
                mmobjectproperty dsc,
                mmlock lck
          WHERE o.containerid IN (
                               SELECT objectid
                                 FROM mmobject
                                WHERE containerid = 130887
                                      OR objectid = 130887)
            AND o.classid IN (21, 57)
            AND l.objectid = o.objectid
            AND l2.objectid(+) = o.containerid
            AND o.masterid = o.objectid
            AND p.objectid(+) = o.objectid
            AND p.propertyid(+) = 2
            AND ff.propertyid(+) = 522
            AND ff.objectid(+) = o.objectid
            AND lck.objectid(+) = o.objectid
            AND dsc.propertyid(+) = -1
            AND dsc.objectid(+) = o.objectid
            AND (   (lck.locktype IS NULL)
                 OR (lck.locktype = (SELECT MAX (locktype)
                                       FROM mmlock
                                      WHERE objectid = o.objectid))
                )
       ORDER BY 18, 3, 2
	   
---------------------------------------------------------------------------------
	   
/* list libraries */	   
SELECT   o.objectid "Object Id", l.objectname "Object Name"
    FROM mmobject o, mmlibrary l
   WHERE o.classid = 2 AND l.objectid = o.objectid
ORDER BY 1, 2
	   

/* Get the full list of libarary, model, and subject areas */
SELECT DISTINCT  l.objectname "Subject Area Name",
                DECODE (o.classid,
                        21, l.objectname,
                        NVL (l2.objectname, ' ')
                       ) "Model Group Name"
	                   ,DECODE (o.classid,21, o.objectid,o.containerid) "Model Group Id"
					   ,o.containerid ,o.classid
           FROM mmobject o,
                mmvmodelobject l,
                mmvmodelobject l2,
                mmobjectproperty p,
                mmobjectproperty ff,
                mmobjectproperty dsc,
                mmlock lck
          WHERE o.containerid IN (
                               SELECT objectid
                                 FROM mmobject
                                WHERE containerid in 
									(SELECT   distinct o.objectid "Object Id"
								     FROM mmobject o, mmlibrary l
									 WHERE o.classid = 2 AND l.objectid = o.objectid)
                                 OR objectid in 
									(SELECT   distinct o.objectid "Object Id"
									 FROM mmobject o, mmlibrary l
									 WHERE o.classid = 2 AND l.objectid = o.objectid))
            AND o.classid IN (21,57)
            AND l.objectid = o.objectid
            AND l2.objectid(+) = o.containerid
            AND o.masterid = o.objectid
            AND p.objectid(+) = o.objectid
            AND p.propertyid(+) = 2
            AND ff.propertyid(+) = 522
            AND ff.objectid(+) = o.objectid
            AND lck.objectid(+) = o.objectid
            AND dsc.propertyid(+) = -1
            AND dsc.objectid(+) = o.objectid
            AND (   (lck.locktype IS NULL)
                 OR (lck.locktype = (SELECT MAX (locktype)
                                       FROM mmlock
                                      WHERE objectid = o.objectid))
                )
				order by 2,1
   
   


/* Get the full list of libarary, model, and subject areas */
select lib.* ,o.* from (SELECT DISTINCT  l.objectname "Subject Area Name",
                o.classid ,DECODE (o.classid,
                        21, l.objectname,
                        NVL (l2.objectname, ' ')
                       ) "Model Group Name"
					   ,o.containerid 
           FROM mmobject o,
                mmvmodelobject l,
                mmvmodelobject l2,
                mmobjectproperty p,
                mmobjectproperty ff,
                mmobjectproperty dsc,
                mmlock lck
          WHERE o.containerid IN (
                               SELECT objectid
                                 FROM mmobject
                                WHERE containerid in 
									(SELECT   distinct o.objectid "Object Id"
								     FROM mmobject o, mmlibrary l
									 WHERE o.classid = 2 AND l.objectid = o.objectid)
                                 OR objectid in 
									(SELECT   distinct o.objectid "Object Id"
									 FROM mmobject o, mmlibrary l
									 WHERE o.classid = 2 AND l.objectid = o.objectid))
            AND o.classid IN (21,57)
            AND l.objectid = o.objectid
            AND l2.objectid(+) = o.containerid
            AND o.masterid = o.objectid
            AND p.objectid(+) = o.objectid
            AND p.propertyid(+) = 2
            AND ff.propertyid(+) = 522
            AND ff.objectid(+) = o.objectid
            AND lck.objectid(+) = o.objectid
            AND dsc.propertyid(+) = -1
            AND dsc.objectid(+) = o.objectid
            AND (   (lck.locktype IS NULL)
                 OR (lck.locktype = (SELECT MAX (locktype)
                                       FROM mmlock
                                      WHERE objectid = o.objectid))
                )
) o,(SELECT   o.objectid , l.objectname 
    FROM mmobject o, mmlibrary l
   WHERE o.classid = 2 AND l.objectid = o.objectid) lib 
   WHERE lib.objectid(+)=o.CONTAINERID
   order by 1,2,3
   
