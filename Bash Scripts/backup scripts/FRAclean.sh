#!/bin/bash

. /home/users/oracle/.profile >> /dev/null
. /oracle/BACKUP/ORACLE/METADATA/environments.env >> /dev/null

vhostname=$1
vdbname=$2

scp $BACKUP_SCRIPT_HOME/asmcmd.del grid@$vhostname:/usr/tmp/. > /dev/null
scp $BACKUP_SCRIPT_HOME/FRA.clean grid@$vhostname:/usr/tmp/. > /dev/null

ssh grid@$vhostname "chmod 777 /usr/tmp/asmcmd.del"
ssh grid@$vhostname "chmod 777 /usr/tmp/FRA.clean"

ssh grid@$vhostname "sh /usr/tmp/FRA.clean $vdbname"


exit 0
