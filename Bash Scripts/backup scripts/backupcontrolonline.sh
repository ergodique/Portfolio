#!/usr/bin/bash

. /home/users/oracle/.profile > /dev/null
. /oracle/BACKUP/ORACLE/METADATA/environments.env > /dev/null

vdbname=$1
vbackuptype=$2
vtime=$3
venv=$4

if [ $venv = "PROD" ]
then
	pass=$PASSWORD
else
	pass=$PASSTEST
fi

if  [[ $vbackuptype = INC* ]]
then
        vcontrol="SELECT count(1) FROM gv\$session WHERE (inst_id,sid) IN (SELECT DISTINCT ro.inst_id,ro.sid FROM V\$RMAN_BACKUP_JOB_DETAILS rs, gv\$rman_output ro WHERE rs.session_recid = ro.session_recid and rs.session_stamp = ro.session_stamp and rs.status LIKE 'RUNNING%' AND rs.input_type='DB INCR' and to_char(start_time,'ddmmrrrrhh24')='$vtime') AND UPPER (program) LIKE 'RMAN%';"
elif [[ $vbackuptype = ARC* ]]
then
        vcontrol="SELECT count(1) FROM gv\$session WHERE (inst_id,sid) IN (SELECT DISTINCT ro.inst_id,ro.sid FROM V\$RMAN_BACKUP_JOB_DETAILS rs, gv\$rman_output ro WHERE rs.session_recid = ro.session_recid AND rs.session_stamp = ro.session_stamp AND rs.status LIKE 'RUNNING%' AND rs.input_type = 'ARCHIVELOG' and to_char(start_time,'ddmmrrrrhh24')='$vtime') AND UPPER (program) LIKE 'RMAN%';"
elif [[ $vbackuptype = *DO* ]]
then
	vcontrol="SELECT COUNT(1) FROM gv\$session WHERE (inst_id, SID) IN (SELECT DISTINCT ro.inst_id x, ro.SID FROM v\$rman_status rs, gv\$rman_output ro WHERE rs.recid = ro.session_recid AND rs.stamp = ro.session_stamp AND rs.status LIKE 'RUNNING%' AND (UPPER (ro.output) LIKE '%GLOBAL\_CROSSCHECK%' ESCAPE '\' OR UPPER (ro.output) LIKE '%GLOBAL\_DO\_DISK%' ESCAPE '\' OR UPPER (ro.output) LIKE '%GLOBAL\_DO\_TAPE%' ESCAPE '\')) AND UPPER (PROGRAM) LIKE 'RMAN%';"
elif [[ $vbackuptype = MERGE* ]]
then
        vcontrol="SELECT count(1) FROM gv\$session WHERE (inst_id,sid) IN (SELECT DISTINCT ro.inst_id,ro.sid FROM V\$rman_backup_job_details rs, gv\$rman_output ro WHERE rs.session_recid = ro.session_recid AND rs.session_stamp = ro.session_stamp and rs.status like 'RUNNING%' AND (upper(ro.output) like '%MERGE%' or upper(ro.output) like '%IMG_LVL0%') and to_char(rs.start_time,'ddmmrrrrhh24')='$vtime') AND UPPER (program) LIKE 'RMAN%';"
elif [ $vbackuptype = "BACKUPFRATOVTL" ]
then
        vcontrol="SELECT count(1) FROM gv\$session WHERE (inst_id,sid) IN (SELECT DISTINCT ro.inst_id,ro.sid FROM V\$rman_backup_job_details rs, gv\$rman_output ro WHERE rs.session_recid = ro.session_recid AND rs.session_stamp = ro.session_stamp and rs.status like 'RUNNING%' AND (upper(ro.output) like '%BACKUPFRATOVTL%' or upper(ro.output) like '%FRA_LVL0%') and to_char(rs.start_time,'ddmmrrrrhh24')='$vtime') AND UPPER (program) LIKE 'RMAN%';"
fi

sh $BACKUP_SCRIPT_HOME/dbavailability.sh $vdbname > $BACKUP_OUT_HOME/$vdbname.status 2>&1

cat $BACKUP_OUT_HOME/$vdbname.status | grep CALISIYOR > /dev/null

if [ $? -ne 0 ]
then
        echo 2
        exit 1
fi

vres=`sqlplus -s usrdba/$pass@$vdbname << FINAL
set echo off
set feedback off
set pagesize 0
set sqlprompt ''
set trimspool on
ALTER SESSION SET optimizer_mode=RULE;
$vcontrol
FINAL`

if [ $vres = 0 ]
then
	echo 0
else
	echo 1
fi

exit 0
