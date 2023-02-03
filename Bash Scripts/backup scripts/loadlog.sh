#!/usr/bin/bash

. /home/users/oracle/.profile

vunique=$1
vfilename=$2

. /home/users/oracle/profile11g.db



scp $vfilename kamanora01:/home/users/oracle/LOGS/. > /dev/null
lrc=$?


vfile=`echo $vfilename | rev | cut -d/ -f1 | rev`

if [ $lrc = 0 ]
then
sqlplus -s usrdba/$PASSWORD@DBAPRD <<FINAL > /dev/null 
exec BACKUP.LOAD_LOGS($vunique,'$vfile');
FINAL

ssh kamanora01 "rm /home/users/oracle/LOGS/$vfile" > /dev/null

fi

exit 0
