ORA-24247 ACL Permission Error

--How to check given permissions

SELECT acl,
                               principal,
                               privilege,
                               is_grant,
                               TO_CHAR (start_date, 'DD-MON-YYYY') AS start_date,
                               TO_CHAR (end_date, 'DD-MON-YYYY') AS end_date
  FROM dba_network_acl_privileges;

--How to create new acl

BEGIN
  DBMS_NETWORK_ACL_ADMIN.CREATE_ACL(acl         => 'OracleEBS.xml',
                                    description => 'EBS ACL',
                                    principal   => 'APPS',
                                    is_grant    => true,
                                    privilege   => 'connect');
END;
/
COMMIT;

--How to assign ACL
BEGIN
  DBMS_NETWORK_ACL_ADMIN.ASSIGN_ACL(acl  => 'OracleEBS.xml',
                                    host => '*');
END;
/
COMMIT;


--How to assign new privilege

BEGIN
  DBMS_NETWORK_ACL_ADMIN.ADD_PRIVILEGE(acl       => 'OracleEBS.xml',
                                       principal => 'APPS',
                                       is_grant  => true,
                                       privilege => 'resolve');
END;
/
COMMIT;
