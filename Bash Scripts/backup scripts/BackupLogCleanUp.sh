. /home/users/oracle/.profile >> /dev/null
. /oracle/BACKUP/ORACLE/METADATA/environments.env >> /dev/null

#vtreshold=90

#find $BACKUP_LOG_HOME/*.log -mtime +$vtreshold -exec rm -f {} \;

perl -e 'for(glob "/oracle/BACKUP/ORACLE/LOGS/*.log"){system "rm -f $_" if(-M$_>90)};'
