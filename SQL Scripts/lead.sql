SELECT q.ID, u.userid AS mndtryuserreftext, q.statustext, q.queuename,
          l.partyroleid, l.leadnumber, l.customernumber, l.expirationdate,
          l.SEGMENT, l.locktokentext, p.NAME AS product,
          b1.branchdesc AS branch, s.description AS status,
          t.description AS state,
          (c.firstname || ' ' || c.middlename || ' ' || c.familyname
          ) AS customername,
          n.username AS removedby, b2.branchdesc AS originalbranch
     FROM ccsowner.queueitem q,
          ccsowner.LEAD l,
          ccsowner.branch b1,
          ccsowner.branch b2,
          ccsowner.leadproduct p,
          ccsowner.lookupvalue s,
          ccsowner.lookupvalue t,
          ccsowner.person c,
          ccsowner.partyrole r,
          (SELECT d.partyroleid, (e.fname || ' ' || e.lname) AS username
             FROM ccsowner.LEAD d, ccsowner.userinfo e, ccsowner.leadhistory h, ccsowner.lookupvalue g
            WHERE d.partyroleid = h.leadid
              AND e.userid = h.userid
              AND g.ID = d.statusid
              AND g.description = h.description
              AND g.code = 'REMOVE') n,
          ccsowner.userinfo u
    WHERE q.informationtext = l.partyroleid
      AND l.statusid = s.ID(+)
      AND l.stateid = t.ID
      AND l.branchcode = b1.code
      AND l.productid = p.ID
      AND l.partyroleid = r.ID
      AND r.partyid = c.partyid
      AND l.partyroleid = n.partyroleid(+)
      AND l.origbranchcode = b2.code(+)
      AND q.mndtryuserreftext = u.NAME(+)
      AND q.statustext = 'INACTIVE';