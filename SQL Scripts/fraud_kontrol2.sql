SELECT NVL (COUNT (*), 0)
  FROM fraudstar.authorizations
 WHERE cardno = :b4
   AND suppcardcode = :b3
   AND transactiondate BETWEEN :b2 AND :b1
   AND domestic = '0'
   AND trackreadflag = 'Y';


select count(*) from fraudstar.authorizations partition (P20061227);