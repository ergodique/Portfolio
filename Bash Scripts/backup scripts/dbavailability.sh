. /home/users/oracle/.profile >> /dev/null

dbname=$1

sqlplus -S monitor/monpass@$dbname <<FINAL
select 'CALISIYOR' as DURUM from dual;
FINAL

exit $?
