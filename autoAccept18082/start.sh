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
        /root/flags/rtkStatus.sh
        sleep 600
        x=$((x + 1))
        if  (( x >= 3)); then
            printf "`date +"%H:%M %d/%m/%Y"`\t$fsrar\t`uname -n | cut -d '-' -f2,3`\UTM_ERROR\tERROR - Не поднимается утм" >> /linuxcash/net/server/server/autoAccept$port.log
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
                printf "`date +"%H:%M %d/%m/%Y"`\t$fsrar\t`uname -n | cut -d '-' -f2,3`\tQueryNATTN\tAccepted - Пришел ответ от QueryNATTN. Не принятых накладных `links -source $url | sed 's/</\n</g' | grep -c 'TTN-'`" >> /linuxcash/net/server/server/autoAccept$port.log
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
                printf "`date +"%H:%M %d/%m/%Y"`\t$fsrar\t`uname -n | cut -d '-' -f2,3`\t$DocType\t$ticketStatus - $answer\n" >> /linuxcash/net/server/server/autoAccept$port.log
                break
            elif [[ $ticketStatus == "Rejected" ]]; then
                printf "Rejected: $answer\n"
                printf "`date +"%H:%M %d/%m/%Y"`\t$fsrar\t`uname -n | cut -d '-' -f2,3`\t$DocType\t$ticketStatus - $answer\n" >> /linuxcash/net/server/server/autoAccept$port.log
                break
            else
                printf "Unknown error: $answer\n"
                printf "`date +"%H:%M %d/%m/%Y"`\t$fsrar\t`uname -n | cut -d '-' -f2,3`\t$DocType\t Unknown error - $answer\n" >> /linuxcash/net/server/server/autoAccept$port.log
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
                        printf "`date +"%H:%M %d/%m/%Y"`\t$fsrar\t`uname -n | cut -d '-' -f2,3`\tWAYBILL\tDelete - Удалил уже принятую накладную $friTTN\n" >> /linuxcash/net/server/server/autoAccept$port.log
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

        sed -e "s/ID_t/$fsrar/g" QueryNATTN.xml.prepare > QueryNATTN.xml
        curl -F "xml_file=@QueryNATTN.xml" http://localhost:$port/opt/in/QueryNATTN 2>/dev/null | sed "s/>/>\n/g" | grep '</url>' | cut -d "<" -f1 > NaTTN_url
        NaTTN_url=`cat NaTTN_url`
        rm NaTTN_url
        wait_answer_url $NaTTN_url $port
        ReplyAdress=`links -dump http://localhost:$port/opt/out | grep ReplyNATTN` # Ответ ReplyNATTN
    fi
}

# Белый список пивных поставщиков
function check_whitelist_shipper {
    port=$1

    fsrar=$(curl -X GET http://localhost:$port/diagnosis 2>/dev/null | grep CN | cut -b 7-18) # FSRAR_ID с УТМ
    if ! [ -f shipper_fsrar ]; then
        touch shipper_fsrar
    fi

    shipper_fsrar=`links -source $ReplyAdress | sed "s/> */>\n/g" | grep "</ttn:Shipper>" | awk -F "</ttn:Shipper>" {'print $1'}` # FSRAR_ID поставщиков 
    for fsrar_id in $shipper_fsrar; do
        whiteFsrar=`grep -c $fsrar_id /linuxcash/net/server/server/whitelist_autoaccept.txt`
        if (( $whiteFsrar == 0 )); then
            sed -i "s/utmfsrar/$fsrar/g" QueryClients_v2.xml.prepare
            sed -e "s/ID_t/$fsrar_id/g" QueryClients_v2.xml.prepare > QueryClients_v2.xml
            curl -F "xml_file=@QueryClients_v2.xml" http://localhost:$port/opt/in/QueryClients_v2 2>/dev/null | sed "s/>/>\n/g" | grep '</url>' | cut -d "<" -f1 > QueryClients_v2
            QueryClients_v2=`cat QueryClients_v2`
            rm QueryClients_v2
            wait_answer_url $QueryClients_v2 $port
            echo $fsrar_id >> shipper_fsrar
        else
            echo "$fsrar_id уже есть в белом списке"
        fi

    done
}

# Приём накладных
# accepted_TTN $1=Максимальный возраст накладной в днях $2=utmport
function accepted_TTN () {
    dateTTN=(`links -source $ReplyAdress | sed "s/> */>\n/g" | grep "ttnDate" | awk -F "<ttn:ttnDate>" {'print $1'} | cut -b 1-10 | tr -d \-`) # Даты накладных
    TTNs=(`links -source $ReplyAdress | sed "s/> */>\n/g" | grep "TTN-" | awk -F "</ttn:WbRegID>" {'print $1'}`) # ТТНки
    printdateTTN=(`links -source $ReplyAdress | sed "s/> */>\n/g" | grep "ttnDate" | awk -F "<ttn:ttnDate>" {'print $1'} | cut -b 1-10`) # Даты накладных для вывода
    nowdate=`date +%Y-%m-%d` # Текущая дата
    oldDate=$((`date +%Y%m%d` - $1)) # (текущая дата без деффиса - максимальный возраст накладной в днях)
    port=$2
    count=0
    for date in "${dateTTN[@]}"; do # Перебираем все даты ТТНок из ReplyNaTTN
        cd /root/autoAccept$port
        if (( $date <= $oldDate )); then # Если дата меньше (текущая дата без деффиса < максимальный возраст накладной в днях)
            echo "Накладной больше $1 дня ${printdateTTN[$count]} ${TTNs[$count]}"
            if (( `grep -c ${TTNs[$count]} acceptedTTN` >= 1 )); then # Если есть совпадение в списке принятых тикетов, то ничего не делает, иначе принимаем
                echo "Накладная уже принята ${TTNs[$count]}"
            else    
                yearTTN=`links -source $ReplyAdress | sed "s/> */>\n/g" | grep "ttnDate" | awk -F "<ttn:ttnDate>" {'print $1'} | cut -b 1-10 | grep -m1 ${printdateTTN[$count]} | cut -d- -f1`
                monthTTN=`links -source $ReplyAdress | sed "s/> */>\n/g" | grep "ttnDate" | awk -F "<ttn:ttnDate>" {'print $1'} | cut -b 1-10 | grep -m1 ${printdateTTN[$count]} | cut -d- -f2`
                dayTTN=`links -source $ReplyAdress | sed "s/> */>\n/g" | grep "ttnDate" | awk -F "<ttn:ttnDate>" {'print $1'} | cut -b 1-10 | grep -m1 ${printdateTTN[$count]} | cut -d- -f3`
                
                if (( $yearTTN >= "2022" )); then # WB_4
                    cd /root/autoAccept$port/WayBillAct_v4
                    sed -e "s/ID_t/$fsrar/g" accepted.xml.prepare >accepted.xml.prepare.1
                    sed -e "s/TTNREGID/${TTNs[$count]}/g" accepted.xml.prepare.1 > accepted.xml.prepare.2
                    sed -e "s/nowdate/$nowdate/g" accepted.xml.prepare.2 > accepted.xml
                    curl -F "xml_file=@accepted.xml" http://localhost:$port/opt/in/WayBillAct_v4 2>/dev/null | sed "s/>/>\n/g" | grep '</url>' | cut -d "<" -f1 > WB_url
                    WB_url=`cat WB_url`
                    rm WB_url
                    echo "`date +"%H:%M %d/%m/%Y"` Принимаю накладную ${TTNs[$count]}" >> /root/autoAccept$port/acceptedTTN
                    printf "\n-------------------------------\n"
                    echo "Принимаю накладную ${TTNs[$count]}"
                    wait_answer_url $WB_url $port
                fi	

                if (( $yearTTN >= "2021" && 10#$monthTTN >= "06" )); then # WB_4
                    cd /root/autoAccept$port/WayBillAct_v4
                    sed -e "s/ID_t/$fsrar/g" accepted.xml.prepare >accepted.xml.prepare.1
                    sed -e "s/TTNREGID/${TTNs[$count]}/g" accepted.xml.prepare.1 > accepted.xml.prepare.2
                    sed -e "s/nowdate/$nowdate/g" accepted.xml.prepare.2 > accepted.xml
                    curl -F "xml_file=@accepted.xml" http://localhost:$port/opt/in/WayBillAct_v4 2>/dev/null | sed "s/>/>\n/g" | grep '</url>' | cut -d "<" -f1 > WB_url
                    WB_url=`cat WB_url`
                    rm WB_url
                    echo "`date +"%H:%M %d/%m/%Y"` Принимаю накладную ${TTNs[$count]}" >> /root/autoAccept$port/acceptedTTN
                    printf "\n-------------------------------\n"
                    echo "Принимаю накладную ${TTNs[$count]}"
                    wait_answer_url $WB_url $port
                fi
                    
                if (( $yearTTN == "2021" && 10#$monthTTN <= "05" )); then # WB_3
                    cd /root/autoAccept$port/WayBillAct_v3
                    sed -e "s/ID_t/$fsrar/g" accepted.xml.prepare >accepted.xml.prepare.1
                    sed -e "s/TTNREGID/${TTNs[$count]}/g" accepted.xml.prepare.1 > accepted.xml.prepare.2
                    sed -e "s/nowdate/$nowdate/g" accepted.xml.prepare.2 > accepted.xml
                    curl -F "xml_file=@accepted.xml" http://localhost:$port/opt/in/WayBillAct_v3 2>/dev/null | sed "s/>/>\n/g" | grep '</url>' | cut -d "<" -f1 > WB_url
                    WB_url=`cat WB_url`
                    rm WB_url
                    echo "`date +"%H:%M %d/%m/%Y"` Принимаю накладную ${TTNs[$count]}" >> /root/autoAccept$port/acceptedTTN
                    printf "\n-------------------------------\n"
                    echo "Принимаю накладную ${TTNs[$count]}"
                    wait_answer_url $WB_url $port
                fi
                        
                if (( $yearTTN == "2020" )); then # WB_3
                    cd /root/autoAccept$port/WayBillAct_v3
                    sed -e "s/ID_t/$fsrar/g" accepted.xml.prepare >accepted.xml.prepare.1
                    sed -e "s/TTNREGID/${TTNs[$count]}/g" accepted.xml.prepare.1 > accepted.xml.prepare.2
                    sed -e "s/nowdate/$nowdate/g" accepted.xml.prepare.2 > accepted.xml
                    curl -F "xml_file=@accepted.xml" http://localhost:$port/opt/in/WayBillAct_v3 2>/dev/null | sed "s/>/>\n/g" | grep '</url>' | cut -d "<" -f1 > WB_url
                    WB_url=`cat WB_url`
                    rm WB_url
                    echo "`date +"%H:%M %d/%m/%Y"` Принимаю накладную ${TTNs[$count]}" >> /root/autoAccept$port/acceptedTTN
                    printf "\n-------------------------------\n"
                    echo "Принимаю накладную ${TTNs[$count]}"
                    wait_answer_url $WB_url $port
                fi
                            
                if (( $yearTTN == "2019" )); then # WB_3
                    cd /root/autoAccept$port/WayBillAct_v3
                    sed -e "s/ID_t/$fsrar/g" accepted.xml.prepare >accepted.xml.prepare.1
                    sed -e "s/TTNREGID/${TTNs[$count]}/g" accepted.xml.prepare.1 > accepted.xml.prepare.2
                    sed -e "s/nowdate/$nowdate/g" accepted.xml.prepare.2 > accepted.xml
                    curl -F "xml_file=@accepted.xml" http://localhost:$port/opt/in/WayBillAct_v3 2>/dev/null | sed "s/>/>\n/g" | grep '</url>' | cut -d "<" -f1 > WB_url
                    WB_url=`cat WB_url`
                    rm WB_url
                    echo "`date +"%H:%M %d/%m/%Y"` Принимаю накладную ${TTNs[$count]}" >> /root/autoAccept$port/acceptedTTN
                    printf "\n-------------------------------\n"
                    echo "Принимаю накладную ${TTNs[$count]}"
                    wait_answer_url $WB_url $port
                fi
                                
                if (( $yearTTN == "2018" && 10#$monthTTN >= "04" )); then # WB_3
                    cd /root/autoAccept$port/WayBillAct_v3
                    sed -e "s/ID_t/$fsrar/g" accepted.xml.prepare >accepted.xml.prepare.1
                    sed -e "s/TTNREGID/${TTNs[$count]}/g" accepted.xml.prepare.1 > accepted.xml.prepare.2
                    sed -e "s/nowdate/$nowdate/g" accepted.xml.prepare.2 > accepted.xml
                    curl -F "xml_file=@accepted.xml" http://localhost:$port/opt/in/WayBillAct_v3 2>/dev/null | sed "s/>/>\n/g" | grep '</url>' | cut -d "<" -f1 > WB_url
                    WB_url=`cat WB_url`
                    rm WB_url
                    echo "`date +"%H:%M %d/%m/%Y"` Принимаю накладную ${TTNs[$count]}" >> /root/autoAccept$port/acceptedTTN
                    printf "\n-------------------------------\n"
                    echo "Принимаю накладную ${TTNs[$count]}"
                    wait_answer_url $WB_url $port
                fi
                                    
                if (( $yearTTN == "2018" && 10#$monthTTN <= "03" && 10#$dayTTN >= "15" )); then # WB_3
                    cd /root/autoAccept$port/WayBillAct_v3
                    sed -e "s/ID_t/$fsrar/g" accepted.xml.prepare >accepted.xml.prepare.1
                    sed -e "s/TTNREGID/${TTNs[$count]}/g" accepted.xml.prepare.1 > accepted.xml.prepare.2
                    sed -e "s/nowdate/$nowdate/g" accepted.xml.prepare.2 > accepted.xml
                    curl -F "xml_file=@accepted.xml" http://localhost:$port/opt/in/WayBillAct_v3 2>/dev/null | sed "s/>/>\n/g" | grep '</url>' | cut -d "<" -f1 > WB_url
                    WB_url=`cat WB_url`
                    rm WB_url
                    echo "`date +"%H:%M %d/%m/%Y"` Принимаю накладную ${TTNs[$count]}" >> /root/autoAccept$port/acceptedTTN
                    printf "\n-------------------------------\n"
                    echo "Принимаю накладную ${TTNs[$count]}"
                    wait_answer_url $WB_url $port
                fi
                
                if (( $yearTTN == "2018" && 10#$monthTTN == "03" && 10#$dayTTN <= "14" )); then # WB_2
                    cd /root/autoAccept$port/WayBillAct_v2
                    sed -e "s/ID_t/$fsrar/g" accepted.xml.prepare >accepted.xml.prepare.1
                    sed -e "s/TTNREGID/${TTNs[$count]}/g" accepted.xml.prepare.1 > accepted.xml.prepare.2
                    sed -e "s/nowdate/$nowdate/g" accepted.xml.prepare.2 > accepted.xml
                    curl -F "xml_file=@accepted.xml" http://localhost:$port/opt/in/WayBillAct_v2 2>/dev/null | sed "s/>/>\n/g" | grep '</url>' | cut -d "<" -f1 > WB_url
                    WB_url=`cat WB_url`
                    rm WB_url
                    echo "`date +"%H:%M %d/%m/%Y"` Принимаю накладную ${TTNs[$count]}" >> /root/autoAccept$port/acceptedTTN
                    printf "\n-------------------------------\n"
                    echo "Принимаю накладную ${TTNs[$count]}"
                    wait_answer_url $WB_url $port
                fi
                    
                if (( $yearTTN == "2018" && 10#$monthTTN <= "02" )); then # WB_2
                    cd /root/autoAccept$port/WayBillAct_v2
                    sed -e "s/ID_t/$fsrar/g" accepted.xml.prepare >accepted.xml.prepare.1
                    sed -e "s/TTNREGID/${TTNs[$count]}/g" accepted.xml.prepare.1 > accepted.xml.prepare.2
                    sed -e "s/nowdate/$nowdate/g" accepted.xml.prepare.2 > accepted.xml
                    curl -F "xml_file=@accepted.xml" http://localhost:$port/opt/in/WayBillAct_v2 2>/dev/null | sed "s/>/>\n/g" | grep '</url>' | cut -d "<" -f1 > WB_url
                    WB_url=`cat WB_url`
                    rm WB_url
                    echo "`date +"%H:%M %d/%m/%Y"` Принимаю накладную ${TTNs[$count]}" >> /root/autoAccept$port/acceptedTTN
                    printf "\n-------------------------------\n"
                    echo "Принимаю накладную ${TTNs[$count]}"
                    wait_answer_url $WB_url $port
                fi
                    
                if (( $yearTTN == "2017" && 10#$monthTTN >= "07" )); then # WB_2
                    cd /root/autoAccept$port/WayBillAct_v2
                    sed -e "s/ID_t/$fsrar/g" accepted.xml.prepare >accepted.xml.prepare.1
                    sed -e "s/TTNREGID/${TTNs[$count]}/g" accepted.xml.prepare.1 > accepted.xml.prepare.2
                    sed -e "s/nowdate/$nowdate/g" accepted.xml.prepare.2 > accepted.xml
                    curl -F "xml_file=@accepted.xml" http://localhost:$port/opt/in/WayBillAct_v2 2>/dev/null | sed "s/>/>\n/g" | grep '</url>' | cut -d "<" -f1 > WB_url
                    WB_url=`cat WB_url`
                    rm WB_url
                    echo "`date +"%H:%M %d/%m/%Y"` Принимаю накладную ${TTNs[$count]}" >> /root/autoAccept$port/acceptedTTN
                    printf "\n-------------------------------\n"
                    echo "Принимаю накладную ${TTNs[$count]}"
                    wait_answer_url $WB_url $port
                fi
                    
                if (( $yearTTN == "2017" && 10#$monthTTN <= "06" )); then # WB_1
                    cd /root/autoAccept$port/WayBillAct
                    sed -e "s/ID_t/$fsrar/g" accepted.xml.prepare >accepted.xml.prepare.1
                    sed -e "s/TTNREGID/${TTNs[$count]}/g" accepted.xml.prepare.1 > accepted.xml.prepare.2
                    sed -e "s/nowdate/$nowdate/g" accepted.xml.prepare.2 > accepted.xml
                    curl -F "xml_file=@accepted.xml" http://localhost:$port/opt/in/WayBillAct 2>/dev/null | sed "s/>/>\n/g" | grep '</url>' | cut -d "<" -f1 > WB_url
                    WB_url=`cat WB_url`
                    rm WB_url
                    echo "`date +"%H:%M %d/%m/%Y"` Принимаю накладную ${TTNs[$count]}" >> /root/autoAccept$port/acceptedTTN
                    printf "\n-------------------------------\n"
                    echo "Принимаю накладную ${TTNs[$count]}"
                    wait_answer_url $WB_url $port
                fi
                        
                if (( $yearTTN <= "2016" )); then # WB_1
                    cd /root/autoAccept$port/WayBillAct
                    sed -e "s/ID_t/$fsrar/g" accepted.xml.prepare >accepted.xml.prepare.1
                    sed -e "s/TTNREGID/${TTNs[$count]}/g" accepted.xml.prepare.1 > accepted.xml.prepare.2
                    sed -e "s/nowdate/$nowdate/g" accepted.xml.prepare.2 > accepted.xml
                    curl -F "xml_file=@accepted.xml" http://localhost:$port/opt/in/WayBillAct 2>/dev/null | sed "s/>/>\n/g" | grep '</url>' | cut -d "<" -f1 > WB_url
                    WB_url=`cat WB_url`
                    rm WB_url
                    echo "`date +"%H:%M %d/%m/%Y"` Принимаю накладную ${TTNs[$count]}" >> /root/autoAccept$port/acceptedTTN
                    printf "\n-------------------------------\n"
                    echo "Принимаю накладную ${TTNs[$count]}"
                    wait_answer_url $WB_url $port
                fi
            fi
        else
            echo "Накладной меньше $1 дня ${printdateTTN[$count]} ${TTNs[$count]}"
        fi
    count=$(($count + 1))
    done

}

# Основная логика
# Принимает $1=utmport
function main {
    port=$1
    cd /root/autoAccept18082

    check_error_UTM $port
    check_current_ReplyNaTTN $port

    accepted_TTN 1 $port # accepted_TTN $1=(Максимальный возраст накладной в днях) $2=utmport
    check_accepted_TTN $port
    check_whitelist_shipper $port
}

main 18082



