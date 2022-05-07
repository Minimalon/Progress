#!/usr/bin/env bash

# $1=Номер ТТН
function ResendTTN  {
  cd /root/flags/tehpod_files/xml
  printf '\033[0;36m%s\e[m\n' "Перевысылаю накладную $1"
  Current_TTN=$1
  fsrar=$(curl -X GET http://localhost:8082/diagnosis 2>/dev/null | grep CN | cut -b 7-18) # FSRAR_ID с УТМ
  sed -e "s/ID_t/$fsrar/g" QueryResendDoc.xml.prepare > QueryResendDoc.xml.prepare.1
  sed -e "s/TTNNUMBER/$Current_TTN/g" QueryResendDoc.xml.prepare.1 > QueryResendDoc.xml
  QueryResendDoc_url=`curl -F "xml_file=@QueryResendDoc.xml" http://localhost:8082/opt/in/QueryResendDoc 2>/dev/null | sed "s/>/>\n/g" | grep '</url>' | cut -d "<" -f1`
  while true; do
      links -source http://localhost:8082/opt/out | grep -oE '"(.*?)"' | tr -d \" > replyID
      countID=`grep -c $QueryResendDoc_url replyID`
      if (( $countID >= 1 )); then
        /root/ttnload/start.sh
        links=`grep $QueryResendDoc_url replyID | cut -d ">" -f2 | cut -d "<" -f1`
        for url in $links; do
          curl -X DELETE $url
        done
      fi
  echo "Ожидание ответа от $QueryResendDoc_url"
  sleep 30
  done
  rm replyID
}

# $1=Номер ТТН
function add_amark  {
  TTN=$1
  StatusTTN=`/root/ttnstatus.sh $TTN | echo $?`
  if [[ $StatusTTN == 0 ]]; then
    printf '\033[0;32m%s\e[m\n' "Накладная $TTN просканирована"
    amark=`sed 's/</\n</g' /root/ttnload/TTN/$TTN/WayBill_v4.xml | grep "<ce:amc>" | cut -d '>' -f2 | cut -d '<' -f1`
    for line in $amark ; do
      mysql dictionaries -e "INSERT  IGNORE INTO \`excisemarkwhite\` (\`excisemarkid\`) VALUES ('$line');"
    done
  else
    printf '\033[0;31m%s\e[m\n' "Накладная $TTN не просканирована"
    printf '\033[0;35m1: \e[m\e[1;18m%s\e[m\n' "Добавить в белый список"
    printf '\033[0;35m2: \e[m\e[1;18m%s\e[m\n' "Выйти"
    read -p "Номер строки: " TTN_error_line
    if [[ $TTN_error_line == 1 ]]; then
      amark=`sed 's/</\n</g' /root/ttnload/TTN/$TTN/WayBill_v4.xml | grep "<ce:amc>" | cut -d '>' -f2 | cut -d '<' -f1`
      for line in $amark ; do
        mysql dictionaries -e "INSERT  IGNORE INTO \`excisemarkwhite\` (\`excisemarkid\`) VALUES ('$line');"
      done
    elif [[ $TTN_error_line == 2 ]]; then
      exit
    else
      printf '\033[0;31m%s\e[m\n' "Данной строки не существует '$TTN_error_line'"
      exit
    fi
  fi
}

# $1=Акцизнная марка
function Main {
  cd /root/ttnload/TTN/
  if [[ "$1" ]]; then
    TTN_count=`grep -Rc $1 | grep -c ':1'`
    if [[ $TTN_count == 0 ]]; then
      printf '\033[0;31m%s\e[m\n' "Накладной с данной акцизой не найдено"
      exit
    elif [[ $TTN_count == 1 ]]; then
      TTN=`grep -Flrc $1 | cut -d/ -f1`
    else
      printf '\033[0;31m%s\e[m\n' "Ошибка при поиске акцизы"
      exit
    fi
  else
    count=0
    TTN_list=(`ls -r | grep TTN -m10`)
    for line in ${TTN_list[@]}; do
      count=$((count+1))
      TTN_date=`ls -l | grep $line | awk '{print $6,$7,$8}'`
      printf '\033[0;35m%s\e[m' "$count: "
      printf '\e[1;18m%s\e[m' "$line "
      printf '\033[0;36m%s\e[m\n' "$TTN_date"
    done
    read -p "Номер строки: " line
    TTN=${TTN_list[$line-1]}
  fi

  INN=$(cat /linuxcash/cash/conf/ncash.ini | grep inn | grep -oE "[0-9]{1,}")
  KPP=$(cat /linuxcash/cash/conf/ncash.ini | grep kpp | grep -oE "[0-9]{1,}")
  if ! [ -f $TTN/WayBill_v4.xml ]; then
    printf '\033[0;31m%s\e[m\n' "Нету WayBill_v4.xml"
    ResendTTN $TTN
  fi

  if ! [ -f $TTN/FORM2REGINFO.xml ]; then
    printf '\033[0;31m%s\e[m\n' "Нету FORM2REGINFO.xml"
    ResendTTN $TTN
  fi

  if [ -f $TTN/Ticket.xml ]; then
    if [[ -f /linuxcash/net/server/server/exchange/$INN/$KPP/$TTN/Ticket.xml ]]; then
      add_amark $TTN
    else
      cp $TTN/Ticket.xml /linuxcash/net/server/server/exchange/$INN/$KPP/$TTN/Ticket.xml
      add_amark $TTN
    fi
  else
    StatusTTN=`/root/ttnstatus.sh $TTN | echo $?`
    if [[ $StatusTTN == 0 ]]; then
      printf '\033[0;32m%s\e[m\n' "Накладная $TTN просканирована"
      printf '\033[0;36m%s\e[m\n' "Добавил Ticket.xml"
      printf "<?xml version="1.0" encoding="utf-8"?>\n<ns:Documents xmlns:tc="http://fsrar.ru/WEGAIS/Ticket" xmlns:oref="http://fsrar.ru/WEGAIS/ClientRef" xmlns:ns="http://fsrar.ru/WEGAIS/WB_DOC_SINGLE_01" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" Version="1.0">\n  <ns:Owner>\n    <ns:FSRAR_ID>3463047</ns:FSRAR_ID>\n  </ns:Owner>\n  <ns:Document>\n    <ns:Ticket>\n      <tc:TicketDate>`date +'%Y-%m-%dT%H:%M:%S'`</tc:TicketDate>\n      <tc:Identity>00000056723-11.02.2022-23:29:11</tc:Identity>\n      <tc:DocId>13BD86A5-21EC-402B-B792-E3CC248C470C</tc:DocId>\n      <tc:TransportId>4d62f214-5613-44a3-a8f3-49cc9aaebab8</tc:TransportId>\n      <tc:RegID>$TTN</tc:RegID>\n      <tc:DocHash />\n      <tc:DocType>WAYBILL</tc:DocType>\n      <tc:OperationResult>\n        <tc:OperationName>Confirm</tc:OperationName>\n        <tc:OperationResult>Accepted</tc:OperationResult>\n        <tc:OperationDate>`date +'%Y-%m-%dT%H:%M:%S'`</tc:OperationDate>\n        <tc:OperationComment>Накладная $TTN подтверждена</tc:OperationComment>\n      </tc:OperationResult>\n    </ns:Ticket>\n  </ns:Document>\n</ns:Documents>\n" > $TTN/Ticket.xml
      cp $TTN/Ticket.xml /linuxcash/net/server/server/exchange/$INN/$KPP/$TTN/Ticket.xml
      amark=`sed 's/</\n</g' /root/ttnload/TTN/$TTN/WayBill_v4.xml | grep "<ce:amc>" | cut -d '>' -f2 | cut -d '<' -f1` >> /linuxcash/net/server/server/whitelist/`uname -n | cut -d- -f2`/amark.txt
    else
      printf '\033[0;31m%s\e[m\n' "Накладная $TTN не просканирована"
    fi
  fi
}

Main $1
