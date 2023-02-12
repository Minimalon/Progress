#!/usr/bin/env bash
function check_error {
    port=$1

    # Наличие ошибок УТМ
    checkError=$(curl -X GET http://localhost:"$port"/home 2>/dev/null | grep -c 'Проблемы с RSA')
    x=0
    if [ "$checkError" == 1 ]; then
				printf '\033[0;31m%s\e[m\n' "Проблемы с RSA"
				exit
    fi

		#В сети ли УТМы
		b=$(curl -X GET http://localhost:"$port"/home 2>/dev/null | grep -c 'Проблемы с RSA')
		if [ "$b" == 1 ]; then
				printf '\033[0;31m%s\e[m\n' "УТМ не работает"
				exit
		fi
}

# $1 "Сообщение"
function print_notification {
  NOTF_DIR="/root/notifications"
  COUNT_FILES=$(ls $NOTF_DIR | grep -c "Отказ от накладной")
  echo "$1" > "$NOTF_DIR/Отказ от накладной.($COUNT_FILES)"
  find $NOTF_DIR -name "Отказ от накладной*" -mtime +1 -exec rm -rf {} \;
}

while read EAN; do
  EAN=$(echo "$EAN" | tr -d "\n")
  nowdate=$(date +%Y-%m-%d)
  check_error 8082
  fsrar=$(curl -X GET http://localhost:8082/diagnosis 2>/dev/null | grep CN | cut -b 7-18)
  sed -e "s/ID_t/$fsrar/g" reject.xml.prepare > reject.xml.prepare.1
  whitelsts=($(links -dump http://localhost:8082/opt/out | grep WayBill_v4))
  for wb in "${whitelsts[@]}"; do
    if ! [[ $(links -source "$wb" | grep -ci "алкоторг") ]]; then
      echo "Накладная не Алкоторг"
      exit
    fi
    wb_number=$(links -source "$wb" | sed "s/> */>\n/g" | grep "/wb:NUMBER" | sed -e :a -e 's/<[^>]*>//g;/</N;//ba')
    CHECK_EAN=$(links -source "$wb" | sed "s/> */>\n/g" | grep "EAN" | sed -e :a -e 's/<[^>]*>//g;/</N;//ba' | grep "$EAN")
  	if [[ $CHECK_EAN ]]; then
      regs=($(links -dump http://localhost:8082/opt/out | grep  FORM2REGINFO | awk {'print $1'}))
      for reg in $regs; do
        friTTN=$(links -source "$reg" | grep "<wbr:WBRegId>" | cut -d '>' -f2 | cut -d '<' -f1)
        fr_number=$(links -source "$reg" | sed "s/> */>\n/g" | grep "wbr:WBNUMBER" | sed -e :a -e 's/<[^>]*>//g;/</N;//ba')
        if (( $fr_number == $wb_number )); then
          echo "DELETE"
          sed -e "s/nowdate/$nowdate/g" reject.xml.prepare.1 > reject.xml.prepare.2
          sed -e "s/TTNREGID/$friTTN/g" reject.xml.prepare.2 > reject.xml
          curl -F "xml_file=@reject.xml" http://localhost:8082/opt/in/WayBillAct_v4 2>/dev/null
          curl -X DELETE "$wb"
          curl -X DELETE "$reg"
          printf "$(date +"%H:%M %d/%m/%Y") $(hostname) $EAN $friTTN $wb_number\n" >> /linuxcash/net/server/server/rejected.log
          print_notification ""
        fi
      done
      fi
  done
done < /linuxcash/net/server/server/All/BlackList_EAN.txt
