. /home/users/oracle/.profile > /dev/null

unid=$1

sqlplus -s usrdba/$PASSWORD@DBAPRD <<FINAL > /dev/null
delete from backup.oracle_backups where unid=$unid;
commit;
FINAL

exit 0
