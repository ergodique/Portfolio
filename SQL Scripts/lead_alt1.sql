SELECT /*+ NO_CPU_COSTING */ q.ID, 
       u.userid AS mndtryuserreftext, 
       q.statustext, 
       q.queuename, 
       l.partyroleid, 
       l.leadnumber, 
       l.customernumber, 
       l.expirationdate, 
       l.SEGMENT, 
       l.locktokentext, 
       p.NAME AS product, 
       b1.branchdesc AS branch, 
       s.description AS status, 
       t.description AS state, 
       c.firstname || ' ' || c.middlename || ' ' || c.familyname AS customername, 
       n.username AS removedby, 
       b2.branchdesc AS originalbranch 
  FROM ccsowner.queueitem q, 
       ccsowner.LEAD l, 
       ccsowner.branch b1, 
       ccsowner.branch b2, 
       ccsowner.leadproduct p, 
       ccsowner.lookupvalue s, 
       ccsowner.lookupvalue t, 
       ccsowner.person c, 
       ccsowner.partyrole r, 
       (SELECT d.partyroleid, 
               e.fname || ' ' || e.lname AS username 
          FROM ccsowner.LEAD d, 
               ccsowner.userinfo e, 
               ccsowner.leadhistory h, 
               ccsowner.lookupvalue g 
         WHERE h.leadid = d.partyroleid 
           AND h.userid = e.userid 
           AND d.statusid = g.ID 
           AND h.description = g.description 
           AND 'REMOVE' = g.code) n, 
       ccsowner.userinfo u 
 WHERE q.serialpropertytext LIKE '%' || l.partyroleid || '%' 
   AND l.statusid = s.ID (+) 
   AND t.ID = l.stateid 
   AND b1.code = l.branchcode 
   AND p.ID = l.productid 
   AND r.ID = l.partyroleid 
   AND c.partyid = r.partyid 
   AND l.partyroleid = n.partyroleid (+) 
   AND l.origbranchcode = b2.code (+) 
   AND q.mndtryuserreftext = u.NAME (+) 
   AND 'INACTIVE' = q.statustext 
   AND q.serialpropertytext LIKE '%' || r.ID || '%'