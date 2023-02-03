#!/bin/bash
. /home/users/oracle/.profile >> /dev/null
. /oracle/BACKUP/ORACLE/METADATA/environments.env >> /dev/null

DB_NAME=`echo $1 | tr -d ' '` 
BACKUP_TYPE=`echo $2 | tr -d ' '`
SCRIPT_TYPE=`echo $3 | tr -d ' '`
CATALOG=q`echo $4 | tr -d ' '`

echo $BACKUP_TYPE | grep FORCE > /dev/null

if [ $? = 0 ]
then
	BACKUP_TYPE=`echo $BACKUP_TYPE | sed 's/FORCE//'`
	vforce=1
else
	vforce=0
fi

export NLS_DATE_FORMAT="DD/MM/YYYY HH24:MI:SS"
export TIMESTAMP=`date +%Y.%m.%d_%H%M%S`
export LOG=$BACKUP_LOG_HOME/${DB_NAME}_${BACKUP_TYPE}_${TIMESTAMP}.log

touch $LOG
chmod 755 $LOG


#Eger Script type bilgisi girilmediyse normal db backup alinacagi bilgisi

if [ ! -n "$SCRIPT_TYPE" ]
then
	SCRIPT_TYPE=NORMAL
	VHOSTNAME=x
fi


start=$(date '+%d.%m.%Y %H:%M')
vunique=`date '+%Y%m%d%H%M%S'`$$

echo "Start time: "$start
echo "Log file: "$LOG


####################################
#Identify the level and set parms
####################################
vinfo=`$BACKUP_SCRIPT_HOME/getenv.sh $DB_NAME`
vlvl=`echo $vinfo | cut -d';' -f1`
vver=`echo $vinfo | cut -d';' -f2`

. /home/users/oracle/profile"$vver"g.db


if [ $vlvl = "PROD" ]
then
	export CAT=EMPRD
	export password=$PASSWORD
else
	export CAT=EMINT
	export password=$PASSTEST
fi	

####################################
#Check the availability of CATALOG
####################################

if [ $CATALOG = "q" ]
then
	rmanscript="rman catalog rman/"$password"@"$CAT" target usrdba/"$password"@"$DB_NAME

elif [ $CATALOG = "qNOCATALOG" ]
then
	rmanscript="rman target usrdba/"$password"@"$DB_NAME
fi
	

####################################
#Log to DB at initial
####################################

echo "Backup operation is initialized and logged into DBAPRD"
sh $BACKUP_SCRIPT_HOME/logtodatabase.sh INIT $vunique $vlvl $DB_NAME $BACKUP_TYPE $LOG 0


####################################
#Check DB whether BACKUP is running
####################################

visrunning=`sh $BACKUP_SCRIPT_HOME/backupcontrol.sh $DB_NAME $BACKUP_TYPE $vlvl`

if [ $vforce = 1 ]
then
	echo "$BACKUP_TYPE is forced to run."	
	visrunning=0
fi

if [ $visrunning = 0 ]
then
	echo "$BACKUP_TYPE backup is started now."
	sh $BACKUP_SCRIPT_HOME/logtodatabase.sh START $vunique x x x 1 0

elif [ $visrunning = 1 ]
then
	sh $BACKUP_SCRIPT_HOME/logtodatabase.sh FINISHWA $vunique x x x 1 2
	sh $BACKUP_SCRIPT_HOME/loadlog.sh $vunique $LOG
	echo "$BACKUP_TYPE is already running on $DB_NAME database."
	sh $BACKUP_SCRIPT_HOME/archivelogs.sh $vunique
	echo "Exiting with status 2"
	exit 0 
else
        sh $BACKUP_SCRIPT_HOME/logtodatabase.sh FINISHWF $vunique x x x 1 1
        sh $BACKUP_SCRIPT_HOME/loadlog.sh $vunique $LOG
	sh $BACKUP_SCRIPT_HOME/archivelogs.sh $vunique
        echo "$BACKUP_TYPE backup failed."
        echo "DB is unreachable."
	echo "Exiting with status 2"
	exit 0	
fi

export ORACLE_SID=$DB_NAME

if [ "$SCRIPT_TYPE" = "1-UNX" ]
then
	export RTAG="'$DB_NAME""_IMG_LVL0'"
	export VTAG="'$DB_NAME""_TAPE_LVL0'"

	if [ "$BACKUP_TYPE" = "MERGE" ]
	then

$rmanscript log=$LOG <<EOF1 > /dev/null
RUN { EXECUTE SCRIPT CLASS_A_MERGE_LVL0_BACKUP USING $RTAG; }
exit
EOF1
lrc=$?

	elif [ "$BACKUP_TYPE" = "MERGERECOVER" ]
	then

$rmanscript log=$LOG <<EOF1 > /dev/null
RUN { EXECUTE SCRIPT CLASS_A_MERGE_LVL0_RECOVER USING $RTAG; }
exit
EOF1
lrc=$?

	elif [ "$BACKUP_TYPE" = "BACKUPFRATOVTL" ]
	then

$rmanscript log=$LOG <<EOF1 > /dev/null
RUN { EXECUTE SCRIPT CLASS_A_INC0_TOTAPE USING $VTAG; }
exit
EOF1
lrc=$?

	elif [ "$BACKUP_TYPE" = "ARC2" ]
	then

$rmanscript log=$LOG <<EOF1 > /dev/null 
RUN { EXECUTE SCRIPT GLOBAL_ARC2_BACKUP; }
exit
EOF1
lrc=$?

	elif [ "$BACKUP_TYPE" = "ARC" ]
	then

$rmanscript log=$LOG <<EOF1 > /dev/null
RUN { EXECUTE SCRIPT GLOBAL_ARC_BACKUP; }
exit
EOF1
lrc=$?

	elif [ "$BACKUP_TYPE" = "CLSADO" ]
	then

$rmanscript <<EOF1 > $LOG
RUN { EXECUTE SCRIPT GLOBAL_CROSSCHECK; }
exit
EOF1
lrc1=$?

$rmanscript <<EOF2 >> $LOG
RUN { EXECUTE SCRIPT GLOBAL_DO_DISK; }
exit
EOF2
lrc2=$?

$rmanscript <<EOF3 >> $LOG
RUN { EXECUTE SCRIPT GLOBAL_DO_TAPE; }
exit
EOF3
lrc3=$?

		lrc=$(($lrc1 + $lrc2 + $lrc3))

	else
		echo "Unhandled exception"
		echo "Unexpected input parameter taken: "$BACKUP_TYPE
		lrc=1
	fi

elif [ "$SCRIPT_TYPE" = "EXA" ] || [ "$DB_NAME" = "TDSPRD" ]   ##TDSPRD icin yonlendirme -- 17.03.2014
then
	SCRIPT=$BACKUP_RMAN_HOME/backup-oracle-$DB_NAME-$BACKUP_TYPE.rman 
	
	echo "Script: "$SCRIPT

	$rmanscript @$SCRIPT log=$LOG > /dev/null
	lrc=$?

elif [ "$SCRIPT_TYPE" = "2-UNX" ] || [ "$SCRIPT_TYPE" = "3-UNX" ] || [ "$SCRIPT_TYPE" = "4-UNX" ]
then
	if [ "$BACKUP_TYPE" = "INC0" ] || [ "$BACKUP_TYPE" = "INC1" ] || [ "$BACKUP_TYPE" = "ARC" ]
	then
		SCRIPT=$BACKUP_RMAN_HOME/backup-oracle-$BACKUP_TYPE.rman

		echo "Script: "$SCRIPT

		$rmanscript @$SCRIPT log=$LOG > /dev/null
		lrc=$?

	elif [ "$BACKUP_TYPE" = "DO" ]
	then
		SCRIPT1=$BACKUP_RMAN_HOME/backup-oracle-CROSSCHECK.rman
		SCRIPT2=$BACKUP_RMAN_HOME/backup-oracle-DODISK.rman
		SCRIPT3=$BACKUP_RMAN_HOME/backup-oracle-DOTAPE.rman

		$rmanscript @$SCRIPT1 > $LOG
		lrc1=$?
		$rmanscript @$SCRIPT2 >> $LOG
		lrc2=$?
		$rmanscript @$SCRIPT3 >> $LOG
		lrc3=$?

		lrc=$(($lrc1 + $lrc2 + $lrc3))

	else
		echo "Unhandled exception"
		echo "Unexpected input parameter taken: "$BACKUP_TYPE
		lrc=1
	fi
else
	echo "Unhandled exceltion"
	echo "Unexpected SCRIPT_TYPE parameter: "$SCRIPT_TYPE
	lrc=1
fi


echo " "
echo "ExitCode:"$lrc >> $LOG

finish=$(date '+%d.%m.%Y %H:%M')

if [ $lrc = 0 ]
then
	if [ "$BACKUP_TYPE" = "MERGERECOVER" ]
	then
		unset MAILCHECK
		VHOSTNAME=`sh $BACKUP_SCRIPT_HOME/gethostname.sh $DB_NAME`
		echo "After a succesfull MERGERECOVER backup, cleaning operation is sent." | tee -a $LOG

		sh $BACKUP_SCRIPT_HOME/FRAclean.sh $VHOSTNAME $DB_NAME &
	fi

	sh $BACKUP_SCRIPT_HOME/logtodatabase.sh FINISHWS $vunique x x x 1 0
	sh $BACKUP_SCRIPT_HOME/loadlog.sh $vunique $LOG
	echo "$BACKUP_TYPE backup finished successfully."

else
	voraerrcontrol=`cat $LOG | grep "Resync not needed" | wc -l`

	if [ $voraerrcontrol -gt 0 ]
	then
		if [ "$BACKUP_TYPE" = "MERGERECOVER" ]
		then
			unset MAILCHECK
			VHOSTNAME=`sh $BACKUP_SCRIPT_HOME/gethostname.sh $DB_NAME`
			echo "After a succesfull MERGERECOVER backup, cleaning operation is sent." | tee -a $LOG

			sh $BACKUP_SCRIPT_HOME/FRAclean.sh $VHOSTNAME $DB_NAME &
		fi

		sh $BACKUP_SCRIPT_HOME/logtodatabase.sh FINISHWS $vunique x x x 1 0
		sh $BACKUP_SCRIPT_HOME/loadlog.sh $vunique $LOG
		echo "$BACKUP_TYPE backup finished successfully."

	else
		if [ "$BACKUP_TYPE" = "MERGERECOVER" ]
		then
			echo "MERGERECOVER backup did not completed succesfully, so clean operation did not start." | tee -a $LOG
		fi

		sh $BACKUP_SCRIPT_HOME/logtodatabase.sh FINISHWF $vunique x x x 1 1
		sh $BACKUP_SCRIPT_HOME/loadlog.sh $vunique $LOG
		echo "$BACKUP_TYPE backup failed."
		echo "Check the logfile."
	fi
fi

sh $BACKUP_SCRIPT_HOME/archivelogs.sh $vunique
echo "Backup log is successfully archived to log table."
echo " "
echo "Finish time: "$finish

vfinal=`sh $BACKUP_SCRIPT_HOME/bringduration.sh $vunique`

echo "Backup Duration: "$vfinal
echo "Exit Code: "$lrc

exit 0

