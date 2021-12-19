#!/bin/bash

cd /root/resendTTN


nowdate=`date +%Y-%m-%d`
nowtime=`date +%s`
fsrar=$(curl -X GET http://localhost:8082/diagnosis | grep CN | cut -b 7-18)
server="/linuxcash/net/server/server"



NaTTNS=(`links -dump http://localhost:8082/opt/out | grep ReplyNATTN`)
countNaTTNS=`links -dump http://localhost:8082/opt/out | grep -c ReplyNATTN`

dateReplyNATTN=(`links -source $NaTTNS | sed "s/> */>\n/g" | grep ReplyDate | awk -F '<ttn:ReplyDate>' {'print $1'} | cut -b 1-10`)

#Проверяем работу УТМ
a=`curl -I 127.0.0.1:8082 2>/dev/null | head -n 1 | cut -d$' ' -f2`

if [[ $a == 200 ]]; then
	echo "" 
else
	exit
fi

b=`curl -X GET http://localhost:8082/home | grep -c 'Проблемы с RSA'`
if [ $b == 1 ]; then
	exit
fi

#Убираем лишние ReplyNaTTN

if [[ $countNaTTNS > 1 ]]; then
  for (( i = 0; i < $countNaTTNS; i++))
  do
   if [[ ${dateReplyNATTN[$i]} != $nowdate ]]; then
	curl -X DELETE ${NaTTNS[$i]}
	echo Удалил ${NaTTNS[$i]}
   else
    echo Уже есть свежая ReplyNATTN
   fi
  done
fi

#Перевысылаем если нету ReplyNATTN
countNaTTNS=`links -dump http://localhost:8082/opt/out | grep -c ReplyNATTN`
if [[ $countNaTTNS == 0 ]]; then
 /root/curlttn/natttns.sh
 sleep 600
fi

#Смотрим тикеты принятых накладных
rm Tickets
Tickets=(`links -dump http://localhost:8082/opt/out | grep Ticket`)

for i in ${Tickets[@]}
do
 links -source $i |  grep 'подтверждена' | grep '<tc:OperationComment>' | awk {'print $2'} >> Tickets
done
readarray Tickets < Tickets

#Работаем с одним ReplyNATTN

NaTTNS=`links -dump http://localhost:8082/opt/out | grep ReplyNATTN`
allTTNS=(`links -source $NaTTNS | sed "s/> */>\n/g" | grep "TTN-" | awk -F "</ttn:WbRegID>" {'print $1'}`)
reg=(`links -dump http://localhost:8082/opt/out | grep  FORM2REGINFO`)

countRegInfo=`links -dump http://localhost:8082/opt/out | grep -c FORM2REGINFO` ; echo Накладных на УТМ: $countRegInfo
countTTN=`links -source $NaTTNS | sed "s/> */>\n/g" | grep "TTN-" | awk -F "</ttn:WbRegID>" {'print $1'} | grep -c TTN` ; echo Накладных в ReplyNATTN: $countTTN

#Сравниваем кол-во накладных на утм и в ReplyNATTN
if [[ $countRegInfo < $countTTN ]]; then
   for count in ${allTTNS[@]} #Проверяем, есть ли накладная уже на утм
   do
    checkTTN=0
	for line in ${reg[@]}
	do
	 regTTN=`links -source $line | grep "wbr:WBRegId" | cut -d '>' -f2 | cut -d '<' -f1`
     if [[ $regTTN == $count ]]; then
      checkTTN=$((checkTTN + 1))
     fi
	done
    
	for i in ${Tickets[@]}
	do
	 if [[ $i == $count ]]; then
	  checkTTN=$((checkTTN + 1))
	 fi
	done
	
  
   if [[ $checkTTN == 0 ]]; then
   echo  Нету на УТМ $count
     sed -e "s/ID_t/$fsrar/g" QueryResendDoc.xml.prepare > QueryResendDoc.xml.prepare.1
   	 sed -e "s/TTNNUMBER/$count/g" QueryResendDoc.xml.prepare.1 > QueryResendDoc.xml
	 curl -F "xml_file=@QueryResendDoc.xml" http://localhost:8082/opt/in/QueryResendDoc
	 printf "`date +"%H:%M %d/%m/%Y"` | `uname -n | cut -d '-' -f2,3` | $count \n" >> $server/resendTTN.log
	 printf '\nTimeout 660 sec'
	 sleep 660
   else
    echo $count уже есть на УТМ
   fi
  done
fi
