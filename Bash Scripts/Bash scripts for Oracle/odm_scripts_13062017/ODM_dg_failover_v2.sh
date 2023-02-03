. /home/users/oracle/.profile > /dev/null
fred=`echo "\033[31m"`
fgreen='\033[01;32m'
fnone='\033[00m'
fbold='\033[1m'
funderline='\033[4m'
fsize="\033#6"
echo ""
echo "######################################################################################"
echo "#                     Veritabani Adi : ${fgreen}$ORACLE_SID${fnone}                                      #"
echo "######################################################################################"
echo ""
echo ""
echo ""
echo ""
echo ""
echo ""
START=$(date +%s)
echo "1. Adim - Veritabani primary moda aliniyor. "
###################
sqlplus \/  as sysdba <<FINAL > /dev/null
set feedback off
set pagesize 0
set sqlprompt ''
set trimspool on
set heading off
spool /home/users/oracle/ODM_SCRIPTS/dbmode.txt
shutdown immediate;
startup mount;
alter system set db_recovery_file_dest_size=600G;
alter system set log_archive_config='' scope=BOTH;
alter system set log_archive_dest_state_3=DEFER scope=BOTH;
alter system set log_archive_dest_state_4=DEFER scope=BOTH;
alter system set log_archive_dest_3='' scope=BOTH;
alter system set log_archive_dest_4='' scope=BOTH;
alter system set fal_client='' scope=both;
alter system set fal_server='' scope=both;
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE FINISH;
ALTER DATABASE ACTIVATE PHYSICAL STANDBY DATABASE;
alter database open;
spool off
echo ""
FINAL




sqlplus \/  as sysdba <<FINAL > /dev/null
set feedback off
set pagesize 0
set sqlprompt ''
set trimspool on
set heading off
spool /home/users/oracle/ODM_SCRIPTS/dbinfo.txt
select open_mode, database_role,name from v\$database;
spool off
FINAL

dbinfo=`cat /home/users/oracle/ODM_SCRIPTS/dbinfo.txt |grep -v select | grep -v spool | awk '{print $1} {print $2} {print $3}'`
dbinfo1=`cat /home/users/oracle/ODM_SCRIPTS/dbinfo.txt |grep -v select | grep -v spool | awk '{print $1}'`
dbinfo2=`cat /home/users/oracle/ODM_SCRIPTS/dbinfo.txt |grep -v select | grep -v spool | awk '{print $2}'`
dbinfo3=`cat /home/users/oracle/ODM_SCRIPTS/dbinfo.txt |grep -v select | grep -v spool | awk '{print $3}'`
dbinfo4=`cat /home/users/oracle/ODM_SCRIPTS/dbinfo.txt |grep -v select | grep -v spool | awk '{print $4}'`

sqlplus \/  as sysdba <<FINAL > /dev/null
select open_mode, database_role,name from v\$database;
exec dbms_service.start_service('$dbinfo4');
spool off
FINAL

echo "2. Adim - Veritabani mode ve role kontrol yapiliyor."

if ( [ "$dbinfo1" = "READ"  ]  && [ "$dbinfo2" = "WRITE"  ]  && [ "$dbinfo3" = "PRIMARY" ] )
then
echo "    Veritabani Durumu : "$dbinfo
echo "    Her sey yolunda. "
else
echo "    Veritabani duzgun mode veya rolede acilamamistir!!!"
echo "    Veritabani Durumu : "$dbinfo
echo "    Ya islem kesilmistir, ya da /home/users/oracle/ODM_SCRIPTS/dg_failover.log dosyasini kontrol ediniz."
fi


exit


#####################
#
##sqlplus \/  as sysdba <<FINAL > /dev/null
##set feedback off
##set pagesize 0
##set sqlprompt ''
##set trimspool on
##set heading off
##spool /home/users/oracle/ODM_SCRIPTS/dbmode.txt
##select open_mode from v\$database;
##spool off
##echo ""
##FINAL
##
##dbmode=`cat /home/users/oracle/ODM_SCRIPTS/dbmode.txt | awk "NR==2{print;}" `
##
##
##if ( [ "$dbmode" != "OPEN" ] )
##then
##echo "    Veritabani mount modda degildir."
##echo "    Veritabani parametreleri degistirildi. "
##echo "    Veritabani mount modda aciliyor."
##sqlplus \/  as sysdba <<FINAL > /dev/null
##shutdown immediate;
##startup mount;
##alter system set db_recovery_file_dest_size=600G;
##alter system set log_archive_config='' scope=BOTH;
##alter system set log_archive_dest_state_3=DEFER scope=BOTH;
##alter system set log_archive_dest_state_4=DEFER scope=BOTH;
##alter system set log_archive_dest_3='' scope=BOTH;
##alter system set log_archive_dest_4='' scope=BOTH;
##FINAL
##echo "    Veritabani mount modda acildi."
##echo ""
##else
##echo "    Veritabani mount moddadir."
##echo ""
##fi
#
#END=$(date +%s)
#DIFF=$(( $END - $START ))
#echo "It took $DIFF seconds. Mount mode'a alindi. "
#
#
#START=$(date +%s)
#echo "2. Adim - Veritabani Primary mi? Stanby mi? kontrolu yapiliyor. "
#
#
#sqlplus \/  as sysdba <<FINAL > /dev/null
#set feedback off
#set pagesize 0
#set sqlprompt ''
#set trimspool on
#set heading off
#spool /home/users/oracle/ODM_SCRIPTS/dbrole.txt
#select database_role from v\$database;
#spool off
#echo ""
#FINAL
#
#dbrole=`cat /home/users/oracle/ODM_SCRIPTS/dbrole.txt | awk "NR==2{print;}" `
#
#if [ "$dbrole" = "PRIMARY"  ]
#then
#echo "    Veritabani standby veritabani degildir!!!"
#echo "  Veritabani acilacaktir."
#sqlplus \/  as sysdba <<FINAL > /dev/null
#set feedback off
#set pagesize 0
#set sqlprompt ''
#set trimspool on
#set heading off
#spool /home/users/oracle/ODM_SCRIPTS/dg_mounted_primary.log
#alter database open;
#spool off
#FINAL
#
#sqlplus \/  as sysdba <<FINAL > /dev/null
#set feedback off
#set pagesize 0
#set sqlprompt ''
#set trimspool on
#set heading off
#
#
#Declare
#
#
#cursor c is select * from dba_services where name not in (select name from v$active_services);
#v_sql varchar2(1000);
#
#begin
#
#   FOR x IN c
#   LOOP
#      BEGIN
#	  
#	  DBMS_OUTPUT.put_line (x.name||' Kapalý');
#		dbms_service.start_service(''||x.name||'');
#  
#		
#        DBMS_OUTPUT.put_line (x.name||' Acildi');
#		
#		
#      EXCEPTION
#         WHEN OTHERS
#         THEN
#            DBMS_OUTPUT.put_line ('Servis hatali');
#            CONTINUE;
#      END;
#   END LOOP;
#DBMS_OUTPUT.put_line ('Servisler acildi.');
#end;
#/
#
#
#declare 
#v_scn varchar2(50);
#begin
#select SCN_TO_TIMESTAMP((SELECT CURRENT_SCN FROM V$DATABASE)) into v_scn from dual;
#dbms_output.put_line('System SCN''si:'||v_scn);
#end;
#/
#
#FINAL
#
##veritabaný servisleri gerçekten açýldý mý kontrol edildikten sonra output vermeli
#echo " Veritabani servisleri acilmistir."
#
#END=$(date +%s)
#DIFF=$(( $END - $START ))
#echo "It took $DIFF seconds.Primary oldugu icin acilmistir."
#
#else
#echo "    Veritabani standby veritabanidir."
#echo ""
#fi
#
#
########3.ADIM########
#
#if [ "$dbrole" != "PRIMARY"  ]
#then
#echo "3. Adim - $ORACLE_SID  standby veritabani icin failover islemi baslatilacaktir."
#echo "    Dataguard failover adimlarinin tamamlanmasi birkac dakika surecektir."
#sqlplus \/  as sysdba <<FINAL > /dev/null
#set feedback off
#set pagesize 0
#set sqlprompt ''
#set trimspool on
#set heading off
#set time on
#set timing on
#spool /home/users/oracle/ODM_SCRIPTS/dg_failover.log
#ALTER DATABASE RECOVER MANAGED STANDBY DATABASE FINISH;
#ALTER DATABASE ACTIVATE PHYSICAL STANDBY DATABASE;
#alter database open;
#spool off
#FINAL
#
#
#sqlplus \/  as sysdba <<FINAL > /dev/null
#set feedback off
#set pagesize 0
#set sqlprompt ''
#set trimspool on
#set heading off
#
#
#Declare
#
#
#cursor c is select * from dba_services where name not in (select name from v$active_services);
#v_sql varchar2(1000);
#
#begin
#
#   FOR x IN c
#   LOOP
#      BEGIN
#
#          DBMS_OUTPUT.put_line (x.name||' Kapalý');
#                dbms_service.start_service(''||x.name||'');
#
#
#        DBMS_OUTPUT.put_line (x.name||' Acildi');
#
#
#      EXCEPTION
#         WHEN OTHERS
#         THEN
#            DBMS_OUTPUT.put_line ('Servis hatali');
#            CONTINUE;
#      END;
#   END LOOP;
#DBMS_OUTPUT.put_line ('Servisler acildi.');
#end;
#/
#
#
#
#
#declare 
#v_scn varchar2(50);
#begin
#select SCN_TO_TIMESTAMP((SELECT CURRENT_SCN FROM V$DATABASE)) into v_scn from dual;
#dbms_output.put_line('System SCN''si:'||v_scn);
#end;
#/
#
#
#FINAL
#
#echo " Veritabani servisleri acilmistir."
#
#
#END=$(date +%s)
#DIFF=$(( $END - $START ))
#echo "It took $DIFF seconds.Primary olmadigi icin acilmistir."
#echo ""
#echo "    Veritabaninda dataguard failover adimlari tamamlanmistir."
#echo ""
#else
#echo "    ***Islem yapilamadi!!! Ya islem kesilmistir, ya da /home/users/oracle/ODM_SCRIPTS/dg_failover.log dosyasini kontrol ediniz."
#echo ""
#fi
#
#
#sqlplus \/  as sysdba <<FINAL > /dev/null
#set feedback off
#set pagesize 0
#set sqlprompt ''
#set trimspool on
#set heading off
#spool /home/users/oracle/ODM_SCRIPTS/dbinfo.txt
#select open_mode, database_role,name from v\$database;
#spool off
#FINAL
#
#dbinfo=`cat /home/users/oracle/ODM_SCRIPTS/dbinfo.txt |grep -v select | grep -v spool | awk '{print $1} {print $2} {print $3}'`
#dbinfo1=`cat /home/users/oracle/ODM_SCRIPTS/dbinfo.txt |grep -v select | grep -v spool | awk '{print $1}'`
#dbinfo2=`cat /home/users/oracle/ODM_SCRIPTS/dbinfo.txt |grep -v select | grep -v spool | awk '{print $2}'`
#dbinfo3=`cat /home/users/oracle/ODM_SCRIPTS/dbinfo.txt |grep -v select | grep -v spool | awk '{print $3}'`
#dbinfo4=`cat /home/users/oracle/ODM_SCRIPTS/dbinfo.txt |grep -v select | grep -v spool | awk '{print $4}'`
#
#sqlplus \/  as sysdba <<FINAL > /dev/null
#select open_mode, database_role,name from v\$database;
#exec dbms_service.start_service('$dbinfo4');
#spool off
#FINAL
#
#echo "4. Adim - Veritabani mode ve role kontrol yapiliyor."
#
#if ( [ "$dbinfo1" = "READ"  ]  && [ "$dbinfo2" = "WRITE"  ]  && [ "$dbinfo3" = "PRIMARY" ] )
#then
#echo "    Veritabani Durumu : "$dbinfo
#echo "    Her sey yolunda. "
#else
#echo "    Veritabani duzgun mode veya rolede acilamamistir!!!"
#echo "    Veritabani Durumu : "$dbinfo
#echo "    Ya islem kesilmistir, ya da /home/users/oracle/ODM_SCRIPTS/dg_failover.log dosyasini kontrol ediniz."
#fi
#
#
#exit








