. ~/.profile

vbackuptype=$2
db_name=$1
password=$PASSWORD

if [ "$vbackuptype" = "INC0" ]
then

sqlplus -S usrdba/$password@$db_name <<FINAL
alter database force logging;
FINAL

fi

exit 0
