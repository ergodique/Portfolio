. /home/users/oracle/.profile > /dev/null
. /oracle/BACKUP/ORACLE/METADATA/environments.env > /dev/null

vlog=$BACKUP_LOG_HOME/controllist.log

v_log_size=$((`ls -tralg $vlog | awk ' { print $4 } '` / 1024/1024))

if [ $v_log_size -ge 1 ]
then
	mv $vlog $vlog_`date '+%Y%m%d'`
fi


date | tee -a $vlog

sqlplus -s usrdba/$PASSWORD@DBAPRD <<FINAL > /dev/null
set echo off
set feedback off
set linesize 300
set pagesize 0
set sqlprompt ''
set trimspool on
column x format a300
spool $LIST_HOME/runningbackups.list
select db_name|| ';' || backup_type || ';' || to_char(start_time,'ddmmrrrrhh24') || ';' || unid || ';' || logfile as x from backup.oracle_backups;
spool off
FINAL
for line in $(cat $LIST_HOME/runningbackups.list)
do
	db_name=`echo $line | cut -d";" -f1`
	backup_type=`echo $line | cut -d";" -f2`
	start_time=`echo $line | cut -d";" -f3`
	unid=`echo $line | cut -d";" -f4`
	logfile=`echo $line | cut -d";" -f5`

	venv=`$BACKUP_SCRIPT_HOME/getenv.sh $db_name`
	venv=`echo $venv | cut -d";" -f1`

	echo "Kontrol - Env:"$venv | tee -a $vlog
	echo "Kontrol - DB Name:"$db_name | tee -a $vlog
	echo "Kontrol - Backup Type:"$backup_type | tee -a $vlog
	echo "Kontrol - Unid:"$unid | tee -a $vlog
	echo "Kontrol - Logfile:"$logfile | tee -a $vlog

	vcontrol=`sh $BACKUP_SCRIPT_HOME/backupcontrolonline.sh $db_name $backup_type $start_time $venv`

	echo "Kontrol:"$vcontrol | tee -a $vlog

	if [ $vcontrol = 0 ] || [ $vcontrol = 2 ]
	then

		sleep 120

		test -e $logfile

		if [ $? = 0 ]
		then
			cat $logfile | grep ExitCode > /dev/null

			if [ $? = 0 ]
			then
				exitcode=`cat $logfile | grep ExitCode | cut -d: -f2`

				if [ $exitcode = 0 ]
				then
					sh $BACKUP_SCRIPT_HOME/logtodatabase.sh FINISHWS $unid
					echo "Unid:"$unid | tee -a $vlog
					echo "Ended successfully." | tee -a $vlog
				else
					sh $BACKUP_SCRIPT_HOME/logtodatabase.sh FINISHWF $unid x x x 1 1 
					echo "Unid:"$unid | tee -a $vlog
					echo "Backup cancelled." | tee -a $vlog
				fi

				sh $BACKUP_SCRIPT_HOME/loadlog.sh $unid $logfile
				sh $BACKUP_SCRIPT_HOME/archivelogs.sh $unid
			else
				find $logfile -mmin -180 | grep $logfile > /dev/null

				if [ $? = 0 ]
				then
					cat $logfile | grep ORA-19921 > /dev/null

					if [ $? = 0 ]
					then
						echo "Log file was modified within 3 hours." | tee -a $vlog
						echo "ORA-19921 error occurs. Backup can not be logged." | tee -a $vlog
						echo "Backup running." | tee -a $vlog
					else
						echo "Log file was modified within 3 hours." | tee -a $vlog
						echo "So backup will be continue." | tee -a $vlog
						echo "Backup running." | tee -a $vlog
					fi
				else
					cat $logfile | grep -e "ORA-" -e "ANS" > /dev/null

					if [ $? = 0 ]
					then
						echo "Backup is stopped and log file is not mofified within 3 hours." | tee -a $vlog
						echo "But backup contains ORA and ANS errors." | tee -a $vlog
						echo "Backup failed." | tee -a $vlog
						sh $BACKUP_SCRIPT_HOME/logtodatabase.sh FINISHWF $unid x x x 1 1
						sh $BACKUP_SCRIPT_HOME/loadlog.sh $unid $logfile
						sh $BACKUP_SCRIPT_HOME/archivelogs.sh $unid
					else
						echo "Backup is stopped and log file is not mofified within 3 hours." | tee -a $vlog
						echo "Backup cancelled." | tee -a $vlog
						sh $BACKUP_SCRIPT_HOME/logtodatabase.sh CANCEL $unid x 1 1 1 0
						sh $BACKUP_SCRIPT_HOME/loadlog.sh $unid $logfile
						sh $BACKUP_SCRIPT_HOME/archivelogs.sh $unid
					fi
				fi
			fi
		else
			sh $BACKUP_SCRIPT_HOME/deleteentry.sh $unid
			echo "DB Name:"$db_name | tee -a $vlog
			echo "Backup Type:"$backup_type | tee -a $vlog
			echo "Deleted." | tee -a $vlog
		fi
	else
		echo "Backup running." | tee -a $vlog
	fi
echo "------------------------------------------------------------" | tee -a $vlog
done

echo "------------------------------------------------------------" | tee -a $vlog

rm $LIST_HOME/runningbackups.list
exit 0
