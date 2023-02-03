select count(*) as BRANCH_COUNT from websube.branches b;
select count(*)  as USER_COUNT from websube.userlar u;
select count(*)  as TELLER_COUNT from websube.teller t;


/* Formatted on 2010/01/07 09:26 (Formatter Plus v4.8.8) */
SELECT (SELECT COUNT (*) 
          FROM websube.branches b) AS branch_count, (SELECT COUNT (*) 
                                       FROM websube.userlar u) AS user_count,
       (SELECT COUNT (*) 
          FROM websube.teller t) AS teller_count
  FROM DUAL;