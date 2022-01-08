#!/bin/bash
nowdate=`date +%Y-%m-%d`
nowtime=`date +%s`


cd /root/white420
rm TTNs.txt

whitelsts=`links -dump http://localhost:18082/opt/out | grep ReplyNATTN | awk {'print $1'}`

links -source $whitelsts | sed "s/> */>\n/g" | grep "ttnDate" | awk -F "<ttn:ttnDate>" {'print $1'} | cut -b 1-10 > dateTTN.txt
links -source $whitelsts | sed "s/> */>\n/g" | grep "TTN-" | awk -F "</ttn:WbRegID>" {'print $1'} > TTNs.txt

allTTNS=(`cat TTNs.txt`)
dateTTNS=(`cat dateTTN.txt`)

fsrar=$(curl -X GET http://localhost:18082/diagnosis | grep CN | cut -b 7-18)
sed -e "s/ID_t/$fsrar/g" QueryNATTN.xml.prepare >QueryNATTN.xml


echo "$nowdate $nowtime" >> /linuxcash/logs/current/curls.log
rm info.txt
rm TTN.txt
rm WBRegId.txt
rm ReplyNATTN.txt
rm ReplyWBRegId.txt
rm Reply.txt
rm QueryResendDoc.xml
rm TTN_DATE
touch WBRegId.txt
touch ReplyNATTN.txt

a=`curl -I 127.0.0.1:18082 2>/dev/null | head -n 1 | cut -d$' ' -f2`
while true; do 
	if [[ $a == 200 ]]; then
		break
	else
		echo "УТМ не загружен, попробуйте немного погодя"
		sleep 1
	fi
done

b=`curl -X GET http://localhost:18082/home | grep -c 'Проблемы с RSA'`
while true; do 
	if [ $b == 1 ]; then
		echo "Проблемы с RSA, перезагрузи компьютер"
		sleep 1
	else
		break
	fi
done


links -dump http://localhost:18082/opt/out | grep -v 'refused' > info.txt
fileName=/root/white420/info.txt
links -dump http://localhost:18082/opt/out | grep ReplyNATTN  | awk {'print $1'} >> ReplyNATTN.txt
Replyaddreses=`cat ReplyNATTN.txt`

ReplyDate=$(links -source $Replyaddreses | sed "s/> */>\n/g" | grep "</ttn:ReplyDate>" | sed -e "s/<[^>]*>//g" | sed "s/T.*//")

# Проверяем свежий NaTTN
if [ "$ReplyDate" == "$nowdate" ]; then
	echo "============================="
	echo "============================="
	echo "свежий ReplyNATTN есть на УТМ"
	echo "============================"
	echo "============================"
	echo "$ReplyDate и $nowdate"
else
	echo "============================"
	echo "============================"
	echo "отправляем запрос ReplyNATTN"		
	echo "============================"
	echo "============================"
	echo "$ReplyDate и $nowdate"
	rm ReplyNATTN.txt
	curl -F "xml_file=@QueryNATTN.xml" http://localhost:18082/opt/in/QueryNATTN
fi

#Ждём NaTTN
if [ -f $fileName ] && [ -s $fileName ]; then
    echo "$(date +"%F %X") Запрос списка TTN. Ожидание...."
	while true
	do
	    aaa=`links -dump  http://localhost:18082/opt/out | grep ReplyNATTN | awk {'print $1'} `
	    if [ "$aaa" == "" ]; then
	        echo "Ответ не получен, Ожидание 30сек"
	        sleep 30
	    else
        break
	    fi
	done
fi

#Выводим список всех накладных
tempCount=1
echo "1: Accept all TTN"
for count in "${allTTNS[@]}"
do
	tempCount=$((tempCount + 1))
	echo "$tempCount: "$count " ${dateTTNS[$tempCount-2]}"
	echo "$tempCount: "$count " ${dateTTNS[$tempCount-2]}" >> TTN_DATE
 done

printf "***Можно принимать выборочно TTN***\n"
printf "***Принимает все виды WayBill от 1 до 4***\n"
read -p "Enter line: " line

#Принимаем накладные
if [ $line -eq 1 ] 
then
for ttn in "${allTTNS[@]}"
do
	cd /root/white420
	yearTTN=`cat TTN_DATE | grep $ttn | awk {'print $3'} | cut -b 1-4`
	monthTTN=`cat TTN_DATE | grep $ttn | awk {'print $3'} | cut -b 6-7`
	dayTTN=`cat TTN_DATE | grep $ttn | awk {'print $3'} | cut -b 9-10`
	echo $yearTTN-$monthTTN-$dayTTN  $ttn
	
	if (( $yearTTN >= "2022" )); then # WB_4
		cd /root/white420/WayBillAct_v4
		sed -e "s/ID_t/$fsrar/g" accepted.xml.prepare >accepted.xml.prepare.1
		sed -e "s/TTNREGID/$ttn/g" accepted.xml.prepare.1 > accepted.xml.prepare.2
		sed -e "s/nowdate/$nowdate/g" accepted.xml.prepare.2 > accepted.xml
		curl -F "xml_file=@accepted.xml" http://localhost:18082/opt/in/WayBillAct_v4
		printf "\n-------------------------------\n"
	fi	

	if (( $yearTTN >= "2021" && 10#$monthTTN >= "06" )); then # WB_4
		cd /root/white420/WayBillAct_v4
		sed -e "s/ID_t/$fsrar/g" accepted.xml.prepare >accepted.xml.prepare.1
		sed -e "s/TTNREGID/$ttn/g" accepted.xml.prepare.1 > accepted.xml.prepare.2
		sed -e "s/nowdate/$nowdate/g" accepted.xml.prepare.2 > accepted.xml
		curl -F "xml_file=@accepted.xml" http://localhost:18082/opt/in/WayBillAct_v4
		printf "\n-------------------------------\n"
	fi
		
	if (( $yearTTN == "2021" && 10#$monthTTN <= "05" )); then # WB_3
		cd /root/white420/WayBillAct_v3
		sed -e "s/ID_t/$fsrar/g" accepted.xml.prepare >accepted.xml.prepare.1
		sed -e "s/TTNREGID/$ttn/g" accepted.xml.prepare.1 > accepted.xml.prepare.2
		sed -e "s/nowdate/$nowdate/g" accepted.xml.prepare.2 > accepted.xml
		curl -F "xml_file=@accepted.xml" http://localhost:18082/opt/in/WayBillAct_v3
		printf "\n-------------------------------\n"
	fi
			
	if (( $yearTTN == "2020" )); then # WB_3
		cd /root/white420/WayBillAct_v3
		sed -e "s/ID_t/$fsrar/g" accepted.xml.prepare >accepted.xml.prepare.1
		sed -e "s/TTNREGID/$ttn/g" accepted.xml.prepare.1 > accepted.xml.prepare.2
		sed -e "s/nowdate/$nowdate/g" accepted.xml.prepare.2 > accepted.xml
		curl -F "xml_file=@accepted.xml" http://localhost:18082/opt/in/WayBillAct_v3
		printf "\n-------------------------------\n"
	fi
				
	if (( $yearTTN == "2019" )); then # WB_3
		cd /root/white420/WayBillAct_v3
		sed -e "s/ID_t/$fsrar/g" accepted.xml.prepare >accepted.xml.prepare.1
		sed -e "s/TTNREGID/$ttn/g" accepted.xml.prepare.1 > accepted.xml.prepare.2
		sed -e "s/nowdate/$nowdate/g" accepted.xml.prepare.2 > accepted.xml
		curl -F "xml_file=@accepted.xml" http://localhost:18082/opt/in/WayBillAct_v3
		printf "\n-------------------------------\n"
	fi
					
	if (( $yearTTN == "2018" && 10#$monthTTN >= "04" )); then # WB_3
		cd /root/white420/WayBillAct_v3
		sed -e "s/ID_t/$fsrar/g" accepted.xml.prepare >accepted.xml.prepare.1
		sed -e "s/TTNREGID/$ttn/g" accepted.xml.prepare.1 > accepted.xml.prepare.2
		sed -e "s/nowdate/$nowdate/g" accepted.xml.prepare.2 > accepted.xml
		curl -F "xml_file=@accepted.xml" http://localhost:18082/opt/in/WayBillAct_v3
		printf "\n-------------------------------\n"
	fi
						
	if (( $yearTTN == "2018" && 10#$monthTTN <= "03" && 10#$dayTTN >= "15" )); then # WB_3
		cd /root/white420/WayBillAct_v3
		sed -e "s/ID_t/$fsrar/g" accepted.xml.prepare >accepted.xml.prepare.1
		sed -e "s/TTNREGID/$ttn/g" accepted.xml.prepare.1 > accepted.xml.prepare.2
		sed -e "s/nowdate/$nowdate/g" accepted.xml.prepare.2 > accepted.xml
		curl -F "xml_file=@accepted.xml" http://localhost:18082/opt/in/WayBillAct_v3
		printf "\n-------------------------------\n"
	fi
	
	if (( $yearTTN == "2018" && 10#$monthTTN == "03" && 10#$dayTTN <= "14" )); then # WB_2
		cd /root/white420/WayBillAct_v2
		sed -e "s/ID_t/$fsrar/g" accepted.xml.prepare >accepted.xml.prepare.1
		sed -e "s/TTNREGID/$ttn/g" accepted.xml.prepare.1 > accepted.xml.prepare.2
		sed -e "s/nowdate/$nowdate/g" accepted.xml.prepare.2 > accepted.xml
		curl -F "xml_file=@accepted.xml" http://localhost:18082/opt/in/WayBillAct_v2
		printf "\n-------------------------------\n"
	fi
		
	if (( $yearTTN == "2018" && 10#$monthTTN <= "02" )); then # WB_2
		cd /root/white420/WayBillAct_v2
		sed -e "s/ID_t/$fsrar/g" accepted.xml.prepare >accepted.xml.prepare.1
		sed -e "s/TTNREGID/$ttn/g" accepted.xml.prepare.1 > accepted.xml.prepare.2
		sed -e "s/nowdate/$nowdate/g" accepted.xml.prepare.2 > accepted.xml
		curl -F "xml_file=@accepted.xml" http://localhost:18082/opt/in/WayBillAct_v2
		printf "\n-------------------------------\n"
	fi
		
	if (( $yearTTN == "2017" && 10#$monthTTN >= "07" )); then # WB_2
		cd /root/white420/WayBillAct_v2
		sed -e "s/ID_t/$fsrar/g" accepted.xml.prepare >accepted.xml.prepare.1
		sed -e "s/TTNREGID/$ttn/g" accepted.xml.prepare.1 > accepted.xml.prepare.2
		sed -e "s/nowdate/$nowdate/g" accepted.xml.prepare.2 > accepted.xml
		curl -F "xml_file=@accepted.xml" http://localhost:18082/opt/in/WayBillAct_v2
		printf "\n-------------------------------\n"
	fi
		
	if (( $yearTTN == "2017" && 10#$monthTTN <= "06" )); then # WB_1
		cd /root/white420/WayBillAct
		sed -e "s/ID_t/$fsrar/g" accepted.xml.prepare >accepted.xml.prepare.1
		sed -e "s/TTNREGID/$ttn/g" accepted.xml.prepare.1 > accepted.xml.prepare.2
		sed -e "s/nowdate/$nowdate/g" accepted.xml.prepare.2 > accepted.xml
		curl -F "xml_file=@accepted.xml" http://localhost:18082/opt/in/WayBillAct
		printf "\n-------------------------------\n"
	fi
			
	if (( $yearTTN <= "2016" )); then # WB_1
		cd /root/white420/WayBillAct
		sed -e "s/ID_t/$fsrar/g" accepted.xml.prepare >accepted.xml.prepare.1
		sed -e "s/TTNREGID/$ttn/g" accepted.xml.prepare.1 > accepted.xml.prepare.2
		sed -e "s/nowdate/$nowdate/g" accepted.xml.prepare.2 > accepted.xml
		curl -F "xml_file=@accepted.xml" http://localhost:18082/opt/in/WayBillAct
		printf "\n-------------------------------\n"
	fi
	
done
else
	line=$((line - 2))

	sed -e "s/TTNREGID/${allTTNS[$line]}/g" accepted.xml.prepare.1 > accepted.xml.prepare.2
    sed -e "s/nowdate/$nowdate/g" accepted.xml.prepare.2 > accepted.xml
    curl -F "xml_file=@accepted.xml" http://localhost:18082/opt/in/WayBillAct_v4
	printf "\n-------------------------------\n"
sleep 2
fi
