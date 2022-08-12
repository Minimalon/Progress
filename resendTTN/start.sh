#!/bin/bash

# Проверка на ошибки УТМ
function check_error_UTM {
    port=$1
    # Статус утм
    statusCode=`curl -I http://localhost:$port 2>/dev/null | head -n 1 | cut -d$' ' -f2`
    if [[ $statusCode != 200 ]]; then
        echo "УТМ не загружен, попробуйте немного погодя"
        exit
    fi

    # Наличие ошибок УТМ
    checkError=`curl -X GET http://localhost:$port/home 2>/dev/null | grep -c 'Проблемы с RSA'`
    x=0
    if [ $checkError == 1 ]; then
        echo "Проблемы с RSA, перезагрузи компьютер"
        /root/ArturAuto/rtkStatus.sh
        sleep 600
        x=$((x + 1))
        if  (( x >= 3)); then
            printf "`date +"%H:%M %d/%m/%Y"`\t$fsrar\t`uname -n | cut -d '-' -f2,3`\UTM_ERROR\tERROR - Не поднимается утм" >> /linuxcash/net/server/server/resendTTN.log
            exit
        fi
    fi
}

# Ждём ответа от запроса
# $1=url адрес запроса $2=utmport
function wait_answer_url () {
    id=$1
    port=$2

    while true; do
        check_error_UTM $port
        links -source http://localhost:$port/opt/out | grep -oE '"(.*?)"' | tr -d \" > replyID
        countID=`grep -c $id replyID`

        if (( $countID >= 1 )); then
            rm replyID

            if (( "`links -source http://localhost:$port/opt/out | grep $id | grep -c 'ReplyNATTN'`" >= 1 )); then # Если Accepted ReplyNaTTN
                url=`links -source http://localhost:$port/opt/out | grep $id | grep -oE '>(.*?)<' | tr -d \<\>`
                printf "`date +"%H:%M %d/%m/%Y"`\t$fsrar\t`uname -n | cut -d '-' -f2,3`\tQueryNATTN\tAccepted - Пришел ответ от QueryNATTN. Не принятых накладных `links -source $url | sed 's/</\n</g' | grep -c 'TTN-'`\n" >> /linuxcash/net/server/server/resendTTN.log
                break
            fi

            if (( "`links -source http://localhost:$port/opt/out | grep $id | grep -c 'ReplyClient_v2'`" >= 1 )); then # Если Accepted ReplyClient_v2
                url=`links -source http://localhost:$port/opt/out | grep $id | tail -n1 | grep -oE '>(.*?)<' | tr -d \<\>`
                ClientRegId=`links -source $url  | sed "s/</\n</g" | grep '<oref:ClientRegId>' | cut -d '>' -f2`
                INN=`links -source $url  | sed "s/</\n</g" | grep '<oref:INN>' | cut -d '>' -f2`
                ShortName=`links -source $url  | sed "s/</\n</g" | grep '<oref:ShortName>' | cut -d '>' -f2`
                printf "$ClientRegId\t$INN\t$ShortName\n" >> /linuxcash/net/server/server/whitelist_autoaccept.txt
                break
            fi

            # На случай если придёт два тикета, это как правило WayBill
            url=`links -source http://localhost:$port/opt/out | grep $id | grep -oE '>(.*?)<' | tr -d \<\>`
            count_url=`links -source http://localhost:$port/opt/out | grep -c $id`
            echo "Тикетов пришло: $count_url"
            if (( $count_url > 1 )); then
                for ticket in $url; do
                    url=`links -source $ticket | sed "s/</\n</g" | grep -c '<tc:OperationComment>'`
                    if (( $url >= 1 )); then
                        answer=`links -source $ticket | sed "s/</\n</g" | grep '<tc:OperationComment>' | cut -d '>' -f2`
                        ticketStatus=`links -source $ticket | sed "s/</\n</g" | grep '<tc:OperationResult>' | awk -F "<tc:OperationResult>" {'print $2'} | cut -d '<' -f1 | tail -n1`
                        DocType=`links -source $ticket  | sed "s/</\n</g" | grep '<tc:DocType>' | cut -d '>' -f2`
                    fi
                done
            else
                answer=`links -source $url | sed 's/</\n</g' | grep '<tc:Comments>' | cut -d '>' -f2`
                url=`links -source http://localhost:$port/opt/out | grep $id | tail -n1 | grep -oE '>(.*?)<' | tr -d \<\>`
                ticketStatus=`links -source $url  | sed "s/</\n</g" | grep '<tc:Conclusion>' | cut -d '>' -f2`
                DocType=`links -source $url  | sed "s/</\n</g" | grep '<tc:DocType>' | cut -d '>' -f2`
            fi

            if [[ $ticketStatus == "Accepted" ]]; then
                printf "Accepted: $answer\n"
                printf "`date +"%H:%M %d/%m/%Y"`\t$fsrar\t`uname -n | cut -d '-' -f2,3`\t$DocType\t$ticketStatus - $answer\n" >> /linuxcash/net/server/server/resendTTN.log
                break
            elif [[ $ticketStatus == "Rejected" ]]; then
                printf "Rejected: $answer\n"
                printf "`date +"%H:%M %d/%m/%Y"`\t$fsrar\t`uname -n | cut -d '-' -f2,3`\t$DocType\t$ticketStatus - $answer\n" >> /linuxcash/net/server/server/resendTTN.log
                break
            else
                printf "Unknown error: $answer\n"
                printf "`date +"%H:%M %d/%m/%Y"`\t$fsrar\t`uname -n | cut -d '-' -f2,3`\t$DocType\t Unknown error - $answer\n" >> /linuxcash/net/server/server/resendTTN.log
                exit
            fi
        fi
    echo "Ожидание ответа от $id"
    sleep 30
    done
}

# Удаляем принятые ТТН
function check_accepted_TTN {
    port=$1

    if ! [ -f acceptedTTN ]; then
        touch acceptedTTN
    fi

    # Все принятые тикеты из УТМ
    acceptedTTN=`links -dump http://localhost:$port/opt/out | grep Ticket`
    for i in $acceptedTTN
    do
        checkStatusTTN=`links -source $i |  grep -c 'подтверждена'`
        if (( $checkStatusTTN >= 1)); then
            ttn=`links -source $i |  grep 'подтверждена' | grep '<tc:OperationComment>' | awk {'print $2'}`
            if (( `grep -c $ttn acceptedTTN` == 0 )); then # Если нету ТТН в файле
                echo $ttn >> acceptedTTN
            fi
        fi
    done

    acceptedTTN=`cat acceptedTTN`
    whitelsts=(`links -dump http://localhost:$port/opt/out | grep WayBill_v4`)
    fri=(`links -dump http://localhost:$port/opt/out | grep FORM2REGINFO`)
    for line in $acceptedTTN; do # Все принятые ТТН
        for count in ${fri[@]};do # Все FORM2REGINFO
            friTTN=`links -source $count | grep "<wbr:WBRegId>" | cut -d '>' -f2 | cut -d '<' -f1`
            friNumber=`links -source $count | grep "<wbr:WBNUMBER>" |cut -d '>' -f2 | cut -d '<' -f1`
            if [ "$friTTN" ==  "$line" ]; then # Если номера ТТН сходятся
                for whiteReg in ${whitelsts[@]} # Все WayBill_v4
                do
                    WBnumber=`links -source $whiteReg | sed "s/> */>\n/g" | grep "/wb:NUMBER" | sed -e :a -e 's/<[^>]*>//g;/</N;//ba'`
                    if [ "$friNumber" == "$WBnumber" ]; then # Если номера накладных сходятся
                        curl -X DELETE $count
                        curl -X DELETE $whiteReg
                        printf "`date +"%H:%M %d/%m/%Y"`\t$fsrar\t`uname -n | cut -d '-' -f2,3`\tWAYBILL\tDelete - Удалил уже принятую накладную $friTTN\n" >> /linuxcash/net/server/server/resendTTN.log
                    fi
                done
            fi
        done
    done
}

# Проверка на свежий ReplyNATTN
function check_current_ReplyNaTTN {
    port=$1
    nowdate=`date +%Y-%m-%d` # Текущая дата
    ReplyAdress=(`links -dump http://localhost:$port/opt/out | grep ReplyNATTN`) # Все ReplyNATTN
    ReplyDate=`links -source $ReplyAdress | sed "s/</\n</g" | grep "<ttn:ReplyDate>" | cut -d '>' -f2 | cut -d 'T' -f1` # Дата ReplyNATTN
    fsrar=$(curl -X GET http://localhost:$port/diagnosis 2>/dev/null | grep CN | cut -b 7-18) # FSRAR_ID с УТМ


    if [ "$ReplyDate" == "$nowdate" ]; then
        echo "свежий ReplyNATTN есть на УТМ $ReplyDate = $nowdate"
    else
        echo "отправляем запрос ReplyNATTN $ReplyDate != $nowdate"

        ReplyAdress=`links -dump http://localhost:$port/opt/out | grep ReplyNATTN` # Все ReplyNATTN
        for line in $ReplyAdress; do # Удаляем лишние ReplyNaTTN
            ReplyDate=`links -source $line | sed "s/</\n</g" | grep "<ttn:ReplyDate>" | cut -d '>' -f2 | cut -d 'T' -f1` # Дата ReplyNATTN
            if [ "$ReplyDate" != "$nowdate" ]; then
                    curl -X DELETE $line
            fi
        done

        # Проверяем не принятые тикеты QueryNATTN
        count_NaTTN=0
        tickets_NaTTN=`links -dump http://localhost:$port/opt/out | grep Ticket`
        for ticket in $tickets_NaTTN; do
          date_NaTTN=`links -source $ticket | sed "s/</\n</g" | grep '<tc:ConclusionDate>' | cut -d '>' -f2 | cut -d 'T' -f1`
          ticketStatus_NaTTN=`links -source $ticket  | sed "s/</\n</g" | grep '<tc:Conclusion>' | cut -d '>' -f2`
          DocType_NaTTN=`links -source $ticket  | sed "s/</\n</g" | grep '<tc:DocType>' | cut -d '>' -f2`
            if [[ "$date_NaTTN" = "$nowdate" && "$ticketStatus_NaTTN" = "Rejected" && "$DocType_NaTTN" = "QueryNATTN" ]]; then
              count_NaTTN=$((countNaTTN + 1))
            fi
        done

        if [[ $count_NaTTN = 0 ]]; then
          sed -e "s/ID_t/$fsrar/g" QueryNATTN.xml.prepare > QueryNATTN.xml
          NaTTN_url=`curl -F "xml_file=@QueryNATTN.xml" http://localhost:$port/opt/in/QueryNATTN 2>/dev/null | sed "s/>/>\n/g" | grep '</url>' | cut -d "<" -f1`
          wait_answer_url $NaTTN_url $port
          ReplyAdress=`links -dump http://localhost:$port/opt/out | grep ReplyNATTN` # Ответ ReplyNATTN
        fi
    fi
}


cd /root/ArturAuto/TTNresend


nowdate=`date +%Y-%m-%d`
nowtime=`date +%s`
fsrar=$(curl -X GET http://localhost:8082/diagnosis | grep CN | cut -b 7-18)
server="/linuxcash/net/server/server"

check_current_ReplyNaTTN 8082
check_accepted_TTN 8082

readarray acceptedTTN < acceptedTTN

#Работаем с одним ReplyNATTN
allTTNS=(`links -source $ReplyAdress | sed "s/> */>\n/g" | grep "TTN-" | awk -F "</ttn:WbRegID>" {'print $1'}`)
reg=(`links -dump http://localhost:8082/opt/out | grep  FORM2REGINFO`)

countRegInfo=`links -dump http://localhost:8082/opt/out | grep -c FORM2REGINFO` ; echo Накладных на УТМ: $countRegInfo
countTTN=`links -source $ReplyAdress | sed "s/> */>\n/g" | grep "TTN-" | awk -F "</ttn:WbRegID>" {'print $1'} | grep -c TTN` ; echo Накладных в ReplyNATTN: $countTTN

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
      echo $count уже есть на УТМ
     fi
	done

	for i in ${acceptedTTN[@]}
	do
	 if [[ $i == $count ]]; then
	  checkTTN=$((checkTTN + 1))
    echo $count Накладная уже принята
	 fi
	done


   if [[ $checkTTN == 0 ]]; then
     echo  Нету на УТМ $count
     sed -e "s/ID_t/$fsrar/g" QueryResendDoc.xml.prepare > QueryResendDoc.xml.prepare.1
     sed -e "s/TTNNUMBER/$count/g" QueryResendDoc.xml.prepare.1 > QueryResendDoc.xml
  	 curl -F "xml_file=@QueryResendDoc.xml" http://localhost:8082/opt/in/QueryResendDoc 2>/dev/null
  	 printf "`date +"%H:%M %d/%m/%Y"`\t$fsrar\t`uname -n | cut -d '-' -f2,3`\t$count\n" >> $server/resendTTN.log
  	 printf '\nTimeout 660 sec'
  	 sleep 660
   fi
  done
fi
