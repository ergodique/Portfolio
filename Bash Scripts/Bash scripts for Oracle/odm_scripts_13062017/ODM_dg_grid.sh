


. /home/users/grid/.profile > /dev/null
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

#CRS ONLINE MI
START=$(date +%s)

crsctl check has | grep 4638 > crs_status.txt 2>&1
 var=$?
echo $var

END=$(date +%s)
DIFF=$(( $END - $START ))
echo "It took $DIFF seconds. Crs Kontrolu yapildi."



if [ "$var" = '0' ]
        then
        echo "CRS ACIK"
	#CRS DB Resource kapatiliyor
	
	START=$(date +%s)
	x=$(crs_stat -p | grep .db | cut -d'=' -f2)     
	#crsctl modify resource $x -attr AUTO_START=never
        crsctl disable has	
	END=$(date +%s)
	DIFF=$(( $END - $START ))
	echo "It took $DIFF seconds. Crs db resource kapatildi."



else
        echo "CRS ACILACAKTIR"
       	
	START=$(date +%s) 
	crsctl start has > crs_start.txt 2>&1
        crsctl check has  | grep 4638 > crs_status.txt 2>&1
        
	END=$(date +%s)
        DIFF=$(( $END - $START ))
        echo "It took $DIFF seconds. Crs kapaliydi, acildi."
	
	
	var2=$?
        echo $var2
        if [ "$var2" = '0' ]
                then
                echo "CRS ACILDI"
        	
	
		START=$(date +%s)	
		x=$(crs_stat -p | grep .db | cut -d'=' -f2)     
		#crsctl modify resource $x -attr AUTO_START=never	
		crsctl disable has	
	
	        END=$(date +%s)
        	DIFF=$(( $END - $START ))
        	echo "It took $DIFF seconds. Crs kapaliydi, acildi. ve DB res kapatýldý"	
			

	        sleep 240 
        else
                echo "CRS ACILMADI"
        fi
fi

START=$(date +%s)
sqlplus \/  as sysasm <<FINAL > /dev/null
set feedback off
set pagesize 0
set sqlprompt ''
set trimspool on
set heading off
spool /home/users/grid/ODM_SCRIPTS_GRID/asm_status.txt
select status from v\$instance;
spool off
echo ""
FINAL

v_asm=`cat /home/users/grid/ODM_SCRIPTS_GRID/asm_status.txt | grep "STARTED"`

if [ "$v_asm" = "STARTED" ]
        then
        echo "OLDU"
					x=0
					crs_stat -f ora.DATA.dg | grep TARGET | grep ONLINE
					x=`expr $x + $?`
					crs_stat -f ora.LISTENER.lsnr | grep TARGET | grep ONLINE
					x=`expr $x + $?`
					crs_stat -f ora.REDOLOG1.dg | grep TARGET | grep ONLINE
					x=`expr $x + $?`
					crs_stat -f ora.REDOLOG2.dg | grep TARGET | grep ONLINE
					x=`expr $x + $?`
					if [ "$x" = "0" ]
					then 
					echo "ASM basarili acilmistir."
					echo "ASM ACIK"
					exit 0
					else
					echo "ASM daha acilmamistir."
					
					fi
		
		
		
		END=$(date +%s)
                DIFF=$(( $END - $START ))
                echo "It took $DIFF seconds. ASM Acilis kontrolü yapildi"	
        
else
        echo "OLMADI"

		END=$(date +%s)
                DIFF=$(( $END - $START ))
                echo "It took $DIFF seconds. ASM Acilis kontrolu yapildi."





	
	START=$(date +%s)
        
	sqlplus \/  as sysasm <<FINAL > /dev/null
        set feedback off
        set pagesize 0
        set sqlprompt ''
        set trimspool on
        set heading off
        spool /home/users/grid/ODM_SCRIPTS_GRID/asm_startup.txt
        startup;
        spool off
        echo ""
FINAL

	END=$(date +%s)
        DIFF=$(( $END - $START ))
       	echo "It took $DIFF seconds. ASM acik degildi, asm acildi"

        sleep 15;

        sqlplus \/  as sysasm <<FINAL > /dev/null
        set feedback off
        set pagesize 0
        set sqlprompt ''
        set trimspool on
        set heading off
        spool /home/users/grid/ODM_SCRIPTS_GRID/asm_status.txt
        select status from v\$instance;
        spool off
        echo ""
FINAL


        v_asm_start=`cat /home/users/grid/ODM_SCRIPTS_GRID/asm_status.txt | grep "STARTED"`
        if [ "$v_asm_start" = "STARTED" ]
                then
                echo "ASM ACIK"
					x=0
					crs_stat -f ora.DATA.dg | grep TARGET | grep ONLINE
					x=`expr $x + $?`
					
					crs_stat -f ora.LISTENER.lsnr | grep TARGET | grep ONLINE
					x=`expr $x + $?`
					crs_stat -f ora.REDOLOG1.dg | grep TARGET | grep ONLINE
					x=`expr $x + $?`
					crs_stat -f ora.REDOLOG2.dg | grep TARGET | grep ONLINE
					x=`expr $x + $?`
					if [ "$x" = "0" ]
					then 
					echo "ASM basarili acilmistir."
					exit 0
					else
					echo "ASM de sorun var."
					echo "ASM ACILMADI"
					exit 10 
					fi
				
				
                
        else
                echo "ASM ACILMADI"
                exit 20
        fi



exit 10
fi







