#!/usr/bin/env bash

function check_error {
    port=$1

    # Наличие ошибок УТМ
    checkError=`curl -X GET http://localhost:$port/home 2>/dev/null | grep -c 'Проблемы с RSA'`
    if [ $checkError == 1 ]; then
		printf '\033[0;31m%s\e[m\n' "Проблемы с УТМ, перезагрузи кассу"
		exit
    fi

	#В сети ли УТМ
	b=`curl -s -o /dev/null -w "%{http_code}" localhost:$port`
	if [ $b != 200 ]; then
		printf '\033[0;31m%s\e[m\n' "УТМ не работает"
		exit
	fi
}

function wait_answer_url () {
    id=$1
    port=$2

    while true; do
        check_error $port
        links -source http://localhost:$port/opt/out | grep -oE "(.*?)" | tr -d \" > replyID
        countID=`grep -c $id replyID`
        if (( $countID >= 1 )); then
            if (( "`links -source http://localhost:$port/opt/out | grep $id | grep -c "ReplyNATTN"`" >= 1 )); then # Если Accepted ReplyNaTTN
                url=`links -source http://localhost:$port/opt/out | grep $id | grep -oE ">(.*?)<" | tr -d \<\>`
                printf "`date +"%H:%M %d/%m/%Y"`\t$fsrar\t$port\t`uname -n | cut -d "-" -f2,3`\tQueryNATTN\tAccepted - Пришел ответ от QueryNATTN. Не принятых накладных `links -source $url | sed "s/</\n</g" | grep -c "TTN-"`\n"
                break
            fi

            if (( "`links -source http://localhost:$port/opt/out | grep $id | grep -c "ReplyClient_v2"`" >= 1 )); then # Если Accepted ReplyClient_v2
                url=`links -source http://localhost:$port/opt/out | grep $id | tail -n1 | grep -oE ">(.*?)<" | tr -d \<\>`
                ClientRegId=`links -source $url  | sed "s/</\n</g" | grep "<oref:ClientRegId>" | cut -d ">" -f2`
                INN=`links -source $url  | sed "s/</\n</g" | grep "<oref:INN>" | cut -d ">" -f2`
                ShortName=`links -source $url  | sed "s/</\n</g" | grep "<oref:ShortName>" | cut -d ">" -f2`
                if [[ `grep -c $ClientRegId /linuxcash/net/server/server/whitelist_autoaccept.txt` == 0 ]]; then
                  printf "$ClientRegId\t$INN\t$ShortName\n"
                else
                  echo "$ClientRegId поставщик уже есть в /linuxcash/net/server/server/whitelist_autoaccept.txt"
                fi
                break
            fi

            # На случай если придёт два тикета, это как правило WayBill
            url=`links -source http://localhost:$port/opt/out | grep $id | grep -oE ">(.*?)<" | tr -d \<\>`
            count_url=`links -source http://localhost:$port/opt/out | grep -c $id`
            echo "Тикетов пришло: $count_url"
            if (( $count_url > 1 )); then
                for ticket in $url; do
                    url=`links -source $ticket | sed "s/</\n</g" | grep -c "<tc:OperationComment>"`
                    if (( $url >= 1 )); then
                        answer=`links -source $ticket | sed "s/</\n</g" | grep "<tc:OperationComment>" | cut -d ">" -f2`
                        ticketStatus=`links -source $ticket | sed "s/</\n</g" | grep "<tc:OperationResult>" | awk -F "<tc:OperationResult>" {"print $2"} | cut -d "<" -f1 | tail -n1`
                        DocType=`links -source $ticket  | sed "s/</\n</g" | grep "<tc:DocType>" | cut -d ">" -f2`
                    fi
                done
            else
                answer=`links -source $url | sed "s/</\n</g" | grep "<tc:Comments>" | cut -d ">" -f2`
                url=`links -source http://localhost:$port/opt/out | grep $id | tail -n1 | grep -oE ">(.*?)<" | tr -d \<\>`
                ticketStatus=`links -source $url  | sed "s/</\n</g" | grep "<tc:Conclusion>" | cut -d ">" -f2`
                DocType=`links -source $url  | sed "s/</\n</g" | grep "<tc:DocType>" | cut -d ">" -f2`
            fi

            if [[ $ticketStatus == "Accepted" ]]; then
                printf "\e[1;18m%s\e[m\n" "Accepted: $answer"
                break
            elif [[ $ticketStatus == "Rejected" ]]; then
                printf "\033[0;31m%s\e[m\n" "Rejected: $answer"
                break
            else
                printf "\033[0;31m%s\e[m\n" "Unknown error: $answer"
                exit
            fi
        fi
    echo "Ожидание ответа от $id"
    sleep 30
    done
    rm replyID
}


function sendDocument {
  docName=$1
  cd /root/flags/tehpod_files/8
  fsrar=$(curl -X GET http://localhost:$port/diagnosis 2>/dev/null | grep CN | cut -b 7-18)
  date_for_rrwb=`date +"%Y-%m-%dT%H:%M:%S"`
  date_for_wb=`date +'%Y-%m-%d'`
  sed -i "s/{{TTN}}/$TTN/g" $docName.xml
  sed -i "s/{{FSRAR}}/$fsrar/g" $docName.xml
  sed -i "s/{{DATERRWB}}/$date_for_rrwb/g" $docName.xml
  sed -i "s/{{DATEWB}}/$date_for_wb/g" $docName.xml
  url=`curl -F "xml_file=@$docName.xml" http://localhost:$port/opt/in/$docName 2>/dev/null | sed "s/>/>\n/g" | grep "</url>" | cut -d "<" -f1`
  #Back default values in file
  sed -i "s/$TTN/{{TTN}}/g" $docName.xml
  sed -i "s/$fsrar/{{FSRAR}}/g" $docName.xml
  sed -i "s/$date_for_rrwb/{{DATERRWB}}/g" $docName.xml
  sed -i "s/$date_for_wb/{{DATEWB}}/g" $docName.xml

  wait_answer_url $url $port
}

printf '\033[0;33m%s\e[m\n' "Выберите порт"
printf '\033[0;35m1: \e[m\e[1;18m%s\e[m\n' "8082"
printf '\033[0;35m2: \e[m\e[1;18m%s\e[m\n' "18082"
read -p "Номер строки: " portNumber
  if [[ $portNumber == 1 ]]; then
    port='8082'
  elif [[ $portNumber == 2 ]]; then
    port='18082'
  else
    printf '\033[0;31m%s\e[m\n' "Данной строки не существует '$portNumber'"
  fi
  check_error $port


printf '\033[0;33m%s\e[m\n' "Выберите документ"
printf '\033[0;35m1: \e[m\e[1;18m%s\e[m\n' "Перевыслать накладную"
printf '\033[0;35m2: \e[m\e[1;18m%s\e[m\n' "Принять накладную"
printf '\033[0;35m3: \e[m\e[1;18m%s\e[m\n' "Распроведение накладной"
printf '\033[0;35m4: \e[m\e[1;18m%s\e[m\n' "Остатки"
read -p "Номер строки: " docNumber

if [[ $docNumber == 1 ]]; then
  printf '\033[0;35m1: \e[m\e[1;18m%s\e[m\n' "Перевыслать автоматически"
  printf '\033[0;35m2: \e[m\e[1;18m%s\e[m\n' "Ввести номер ТТН самому"
  read -p "Номер строки: " QRDNumber
  if [[ $QRDNumber == 1 ]]; then
    /root/ArturAuto/TTNresend/$port.sh
  elif [[ $QRDNumber == 2 ]]; then
    read -p "Цифры TTN: " TTN
    sendDocument 'QueryResendDoc'
  else
    printf '\033[0;31m%s\e[m\n' "Данной строки не существует '$QRDNumber'"
  fi
elif [[ $docNumber == 2 ]]; then
  printf '\033[0;35m1: \e[m\e[1;18m%s\e[m\n' "Принять автоматически"
  printf '\033[0;35m2: \e[m\e[1;18m%s\e[m\n' "Ввести номер ТТН самому"
  read -p "Номер строки: " WBNumber
  if [[ $WBNumber == 1 ]]; then
    /root/white420/WB_$port.sh
  elif [[ $WBNumber == 2 ]]; then
    read -p "Цифры TTN: " TTN
    sendDocument "WayBillAct_v4"
  else
    printf '\033[0;31m%s\e[m\n' "Данной строки не существует '$WBNumber'"
  fi
elif [[ $docNumber == 3 ]]; then
  read -p "Цифры TTN: " TTN
  sendDocument 'RequestRepealWB'
elif [[ $docNumber == 4 ]]; then
  fsrar=$(curl -X GET http://localhost:$port/diagnosis 2>/dev/null | grep CN | cut -b 7-18)
  inn=`grep inn /linuxcash/cash/conf/ncash.ini | cut -d '"' -f2`
  sed -i "s/8082/$port/g" /root/ostatki_xls/query_rest.py
  python3 /root/ostatki_xls/query_rest.py $fsrar $inn `uname -n | cut -d "-" -f2`
  sed -i "s/$port/8082/g" /root/ostatki_xls/query_rest.py
else
  printf '\033[0;31m%s\e[m\n' "Данной строки не существует '$docNumber'"
fi
