#!/usr/bin/bash

. /home/users/oracle/.profile > /dev/null


vop=$1
vunique=$2
venv=$3
vdbname=$4
vbackuptype=$5
vlog=$6
vrc=$7

if [ "$vop" = "INIT" ]
then
	vsql="INSERT INTO BACKUP.ORACLE_BACKUPS VALUES ($vunique,'$venv','$vdbname','$vbackuptype',SYSDATE,NULL,NULL,NULL,-1,'BACKUP INITIALIZED',NULL,'$vlog',NULL);"
	vsql2="COMMIT;"
elif [ "$vop" = "START" ]
then
	vsql="UPDATE BACKUP.ORACLE_BACKUPS SET DESCRIPTION='BACKUP STARTED',STATUS=0 WHERE UNID=$vunique;"
	vsql2="COMMIT;"
elif [ "$vop" = "FINISHWS" ]
then
	vsql="UPDATE BACKUP.ORACLE_BACKUPS SET FINISH_TIME=SYSDATE, DESCRIPTION='BACKUP COMPLETED SUCCESSFULLY',RETURN_CODE=0 WHERE UNID=$vunique;"
	vsql2="UPDATE BACKUP.ORACLE_BACKUPS SET STATUS=1 WHERE UNID=$vunique;"
elif [ "$vop" = "FINISHWF" ]
then
	vsql="UPDATE BACKUP.ORACLE_BACKUPS SET FINISH_TIME=SYSDATE, DESCRIPTION='BACKUP FAILED',RETURN_CODE=$vrc WHERE UNID=$vunique;"
	vsql2="UPDATE BACKUP.ORACLE_BACKUPS SET STATUS=3 WHERE UNID=$vunique;"
elif [ "$vop" = "FINISHWA" ]
then
	vsql="UPDATE BACKUP.ORACLE_BACKUPS SET FINISH_TIME=SYSDATE, DESCRIPTION='BACKUP ALREADY RUNNING',RETURN_CODE=$vrc WHERE UNID=$vunique;"
	vsql2="UPDATE BACKUP.ORACLE_BACKUPS SET STATUS=4 WHERE UNID=$vunique;"
elif [ "$vop" = "CANCEL" ]
then
	vsql="UPDATE BACKUP.ORACLE_BACKUPS SET FINISH_TIME=SYSDATE, DESCRIPTION='BACKUP CANCELLED',RETURN_CODE=5 WHERE UNID=$vunique;"
	vsql2="UPDATE BACKUP.ORACLE_BACKUPS SET STATUS=5 WHERE UNID=$vunique;"
fi

11g

sqlplus -s usrdba/$PASSWORD@DBAPRD <<FINAL > /dev/null
$vsql
commit;
$vsql2
commit;
FINAL

exit 0
