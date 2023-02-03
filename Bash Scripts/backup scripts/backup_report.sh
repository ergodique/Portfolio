. /home/users/oracle/.profile > /dev/null
. /oracle/BACKUP/ORACLE/METADATA/environments.env > /dev/null

vtime=`date '+%Y%m%d%H%M'`

. /home/users/oracle/profile11g.db

cd $REPORT_SCRIPT_HOME

sqlplus -S -M "HTML ON" usrdba/$PASSWORD@DBAPRD @backup_report.sql > $BACKUP_REPORT_HOME/backup_report.html
sqlplus -S -M "HTML ON" usrdba/$PASSWORD@DBAPRD @backup_report_test.sql > $BACKUP_REPORT_HOME/backup_report_test.html

cd $BACKUP_REPORT_HOME

uuencode backup_report.html backup_report.html | mail -s "ASVT Grubu ORACLE Backup Raporu" -r asvt@isbank.com.tr BTSHYASVTeknisyen@isbank.com.tr,asvt@isbank.com.tr,btuhy-sdsy@isbank.com.tr,btsistemisletimmerkezi@isbank.com.tr
uuencode backup_report_test.html backup_report_test.html | mail -s "ASVT Grubu TEST Ortam ORACLE Backup Raporu" -r asvt@isbank.com.tr ender.koca@is.net.tr,hazal.unal@is.net.tr

mv backup_report.html backup_report.html_$vtime
mv backup_report_test.html backup_report_test.html_$vtime

exit 0
