#ORTAM VE CLIENT VERSIYONU SECIMI
echo "**********************************************************"
echo "ORACLE LINUX CLIENT KURULUMU BASLIYOR..."
echo "**********************************************************"

v_versiyon=$2

if [ "$v_versiyon" = "12" -o "$v_versiyon" = "11" ]
then
	echo "Gecerli giris."
else
	echo "Gecersiz versiyon girdiniz..."
	exit 11
fi

#Kopyalama dizinini versiyona gore ayarlamak gerekli
if [ "$v_versiyon" = "12" ]
then
	vdizin="client32"
else
	vdizin="client32_11.2"
fi

#Klasor yaratilmasi
echo "Oracle klasoru yaratiliyor"
cd /
mkdir -p /oracle/$vdizin
chown -R oracle:oinstall /oracle
chmod -R 775 /oracle	
echo "/oracle yaratildi, haklari verildi."


#ORACLE KULLANICI KONTROLU  
id oracle
v_kullanici=$? 
cat /etc/group | grep oinstall
v_grup=$?

		if [ "$v_kullanici" = 0 ]
        then
                echo "Kullanici yaratilmis"
        else
                echo "Kullanici yaratilmamis"
				
        fi
		
		
		if [ "$v_grup" = 0 ]
        then
                echo "Grup var"
        else
                echo "Grup yok"
				groupadd oinstall
				cat /etc/group | grep oinstall
				v_grup_kontrol=$?
				if [ "$v_grup_kontrol" = 0 ]
				then
					echo "Grup yaratildi"
							if [ "$v_kullanici" = 1 ]
							then
									useradd -G oinstall oracle
									v_kullanici_grup=$?
									         
											 if [ "$v_kullanici_grup" = 0 ]
											 then
											 		echo "Kullanici grubuyla yaratildi"
											 else
											 		echo "Kullanici grubuyla yaratilirken sorun oldu"
													exit 109
											 fi

									
							fi
					
					
				else
					echo "Grup yaratilamadi"
					exit 108	
					
				fi

				
        fi		
		
		



#/TMP BOS ALAN
v_bos_alan=`(df -m | grep -v "vg" | grep "/tmp" | awk '{print $3}')`

 if [ "$v_bos_alan" >  800 ]
 then
         echo "/tmp klasoru altinda yeterince yer vardir"
 else
         echo "/tmp klasoru altinda yeterince yer yoktur"
		 exit 102
 fi

				
#DOSYA KONTROLU
ls -lrt  /etc/oraInst.loc
v_dosya=$?
if [ "$v_dosya" = 0 ]
  then
          echo "Dosya var"
		  echo "Dosya yaratilmadi"
  else
          echo "Dosya yok"
		  touch /etc/oraInst.loc
		  v_dosya_y=$?	    
				if [ "$v_dosya_y" = 0 ]
				then
						 echo "Dosya yaratildi"
						 chmod 777 /etc/oraInst.loc
				         echo "inventory_loc=/oracle/oraInventory"  >> /etc/oraInst.loc
						 echo "inst_group=oinstall" >>  /etc/oraInst.loc
				else
						 echo "Dosya yaratilirken hata aldi"
						 exit 107
				fi
		  
  fi

#CLIENT KURULUMU	 	

su - oracle "-c whoami;/oracle/setup/runInstaller -noconfig -waitforcompletion -responseFile /oracle/setup/client_install.rsp -silent -ignorePrereq -ignoreSysPrereqs"

echo "**********************************************************"
echo "Successfuly installed yazisini gorene kadar bekleyiniz..."
echo "**********************************************************"

	




