. /home/users/oracle/.profile

vunique=$1
vid=`echo $$`


sqlplus -s usrdba/$PASSWORD@DBAPRD << FINAL > /dev/null
set echo off
set feedback off
set pagesize 0
set sqlprompt ''
set trimspool on
spool /usr/tmp/$vid.txt
SELECT DURATION FROM BACKUP.ORACLE_BACKUP_LOGS WHERE UNID=$vunique;
spool off
FINAL

cat /usr/tmp/$vid.txt

rm /usr/tmp/$vid.txt
