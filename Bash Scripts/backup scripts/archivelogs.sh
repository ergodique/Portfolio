#!/usr/bin/bash

. /home/users/oracle/.profile >> /dev/null

vunique=$1

sqlplus -s usrdba/$PASSWORD@DBAPRD <<FINAL > /dev/null
INSERT INTO BACKUP.ORACLE_BACKUP_LOGS SELECT * FROM BACKUP.ORACLE_BACKUPS WHERE UNID=$vunique;
DELETE FROM BACKUP.ORACLE_BACKUPS WHERE UNID=$vunique;
COMMIT;
FINAL

exit 0
