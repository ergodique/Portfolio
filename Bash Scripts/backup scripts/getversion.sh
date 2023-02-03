. /home/users/oracle/.profile

db_name=$1
password=$PASSWORD

vversion=`sqlplus -S usrdba/$password@DBAPRD <<FINAL
set echo off
set feedback off
set linesize 200
set pagesize 0
set sqlprompt ''
SELECT host_name FROM isbdba.databases WHERE DECODE (rac_enabled, 0, db_name, management_instance_name)='$db_name';
FINAL`

echo $vversion

exit 0
