#!/bin/bash

fsrar=$(curl -X GET http://localhost:8082/diagnosis | grep CN | cut -b 7-18)
fri=(`links -dump http://localhost:8082/opt/out | grep FORM2REGINFO`)
cashNumber=`uname -n | cut -d '-' -f2,3`
server="/linuxcash/net/server/server"

#---Проверки УТМ---

a=`curl -I 127.0.0.1:8082 2>/dev/null | head -n 1 | cut -d$' ' -f2`
if [[ $a == 200 ]]; then
	echo "" 
else
	echo "УТМ не загружен, попробуйте немного погодя"
	sleep 1
	exit
fi

b=`curl -X GET http://localhost:8082/home | grep -c 'Проблемы с RSA'`
if [ $b == 1 ]; then
	echo "Проблемы с RSA, перезагрузи компьютер"
	sleep 1
	exit
fi

#---------------

cd /root/ttnload/TTN/
listTTN=(`ls -rd */ | cut -d/ -f1`)
x=0

for line in ${listTTN[@]}
do                                                                                                             
	fsrarFRI=`grep "<oref:ClientRegId>" $line/FORM2REGINFO.xml | awk -F">|<" '{print $3}' | tail -n1`
	if [[ $fsrarFRI != $fsrar ]]; then
			echo "FSRAR на утм не равняется FSRAR в FORM2REGINFO"
			break
	fi

	if ! [ -f $line/Ticket.xml ]; then
		
		fri=(`links -dump http://localhost:8082/opt/out | grep FORM2REGINFO`)
		for count in ${fri[@]}
		do
			friTTN=`links -source $count | grep "<wbr:WBRegId>" | cut -d '>' -f2 | cut -d '<' -f1`
			if [ "$friTTN" ==  "$line" ]; then
				echo "Есть ТТН"
				exit
			fi
			
			
		done

		
		cd /root/queryResTTNs
		sed -e "s/ID_t/$fsrar/g" QueryResendDoc.xml.prepare > QueryResendDoc.xml.prepare.1
		sed -e "s/TTNNUMBER/$line/g" QueryResendDoc.xml.prepare.1 > QueryResendDoc.xml
		curl -F "xml_file=@QueryResendDoc.xml" http://localhost:8082/opt/in/QueryResendDoc
		cd /root/ttnload/TTN/
		#---------Logs---------
		printf "`date +"%H:%M %d/%m/%Y"` $line $cashNumber\n" >> $server/ResendTTN.log
		sleep 660
	else
		x=$((x+1))
			if [[ $x == 4 ]]; then
				break
			fi
		echo "/root/ttnload/TTN/$line --- Есть тикет"
		
		whitelsts=(`links -dump http://localhost:8082/opt/out | grep WayBill_v4`)
		
		statusTTN=`grep -c 'подтверждена' /root/ttnload/TTN/$line/Ticket.xml`
		if [ $statusTTN > 0 ]; then
			fri=(`links -dump http://localhost:8082/opt/out | grep FORM2REGINFO`)
			for count in ${fri[@]}
			do
				friTTN=`links -source $count | grep "<wbr:WBRegId>" | cut -d '>' -f2 | cut -d '<' -f1`
				friNumber=`links -source $count | grep "<wbr:WBNUMBER>" |cut -d '>' -f2 | cut -d '<' -f1`
				if [ "$friTTN" ==  "$line" ]; then
					for whiteReg in ${whitelsts[@]}
					do
						WBnumber=`links -source $whiteReg | sed "s/> */>\n/g" | grep "/wb:NUMBER" | sed -e :a -e 's/<[^>]*>//g;/</N;//ba'`
						if [ "$friNumber" == "$WBnumber" ]; then
							curl -X DELETE $count
							curl -X DELETE $whiteReg
							echo Удалил $friTTN
						fi
					done
				fi
			done
		fi
	fi 
done
