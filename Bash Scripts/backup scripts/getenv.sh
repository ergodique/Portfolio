. /home/users/oracle/.profile

db_name=$1
password=$PASSWORD

venv=`sqlplus -S usrdba/$password@DBAPRD <<FINAL
set echo off
set feedback off
set linesize 200
set pagesize 0
set sqlprompt ''
SELECT lvl || ';' || version FROM isbdba.databases WHERE db_name='$db_name';
FINAL`

echo $venv

exit 0
