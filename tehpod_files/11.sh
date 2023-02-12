#!/usr/bin/env bash

function generate_pki {
  utmPort=$1
  fsrar=$(curl http://localhost:"$utmPort"/diagnosis 2>/dev/null | grep CN | awk -F '<|>' {'print $3'})
  info=$(curl http://localhost:"$utmPort"/api/rsa 2>/dev/null | jq . 2>/dev/null | grep "$fsrar" -C7 | grep Owner_ID -C7)
  INN=$(echo "$info" | jq '.INN' 2>/dev/null | cut -d '"' -f2)
  KPP=$(echo "$info" | jq '.KPP' 2>/dev/null | cut -d '"' -f2)
  Fact_Address=$(echo "$info" | jq '.Fact_Address' 2>/dev/null | awk '{print substr ($0, 1, length($0)-1)}' | awk '{print substr ($0, 2)}')
  Full_Name=$(echo "$info" | jq '.Full_Name' 2>/dev/null | awk '{print substr ($0, 1, length($0)-1)}' | awk '{print substr ($0, 2)}')
  ID=$(echo "$info" | jq '.ID' 2>/dev/null)

  rsa=$(curl -G "http://localhost:$utmPort/api/rsa/keygen" 2>/dev/null \
      -H "accept: application/json"  \
      --data "INN=$INN" \
      --data "KPP=$KPP" \
      --data-urlencode "factAddress=$Fact_Address" \
      --data "fsrarid=$fsrar" \
      --data-urlencode "fullName=$Full_Name" \
      --data "id=$ID")

  if [[ $(echo "$rsa" | grep -c 'true') -gt 0 ]]; then
    printf '\033[0;32m%s\e[m\n' "PKI успешно перезаписан"
  elif [[ $(echo "$rsa" | grep -c 'Не удалось записать RSA сертификат. Попробуйте еще раз') ]]; then
    printf '\033[0;31m%s\e[m\n' "Не удалось записать RSA сертификат. Попробую еще раз"
    for (( i = 1; i < 6; i++ )); do
      printf '\e[1;18m%s\e[m\n' "Попытка $i из 5"
      rsa=$(curl -G "http://localhost:$utmPort/api/rsa/keygen" 2>/dev/null \
          -H "accept: application/json"  \
          --data "INN=$INN" \
          --data "KPP=$KPP" \
          --data-urlencode "factAddress=$Fact_Address" \
          --data "fsrarid=$fsrar" \
          --data-urlencode "fullName=$Full_Name" \
          --data "id=$ID")
      if [[ $(echo "$rsa" | grep -c 'true') -gt 0 ]]; then
        printf '\033[0;32m%s\e[m\n' "PKI успешно перезаписан"
        break
      else
        printf '\033[0;31m%s\e[m\n' "$rsa"
      fi
    done
  fi

  if [[ $(echo "$rsa" | grep -c 'tr.ue') == 0 ]]; then
    printf '\033[0;31m%s\e[m\n' "PKI не перезаписан"
    printf '\033[0;31m%s\e[m\n' "$rsa"
  fi
}

function google_sheets {
	printf '\033[0;36m%s\e[m\n' "Чтобы отметить заявку в гугл таблице RSA выберите ваше имя или нажмите Ctrl+C чтобы не отмечать"
	operators=($(cat /linuxcash/net/server/server/logs/operatorsRSA))
	for operator in "${operators[@]}"; do
  	tempCount=$((tempCount + 1))
  	printf '\033[0;35m%s\e[m\e[1;18m\e[m' "$tempCount: "
  	printf '\e[1;18m%s\e[m\n' "$operator"
	done
	read -p "Строка: " line
	name="${operators[$line - 1]}"
  if [[ $name ]]; then
    echo "$name||$fsrar||$KPP||$Full_Name||$(hostname | cut -d- -f2)||$Fact_Address" >> /linuxcash/net/server/server/logs/rsaTable.txt
    printf '\033[0;32m%s\e[m\n\n' "Через минуту отмечу в гугл таблице RSA"
  else
    printf '\033[0;31m%s\e[m\n' "Неизвестное имя '$name'"
  fi
}

function usbip_bind_and_message {
  utmPort=$1
  if [ -d "/usr/share/hwdata" ]; then sleep 1; else mkdir /usr/share/hwdata; ln -s /usr/share/misc/usb.ids /usr/share/hwdata/usb.ids; fi
  service pcscd stop
  usbipd -D
  if [[ $1 == "8082" ]]; then
    usbPort=$(vboxmanage list usbhost 2>/dev/null | grep -A3 Rutoken | grep -E -B1 'Busy|Available' | cut -b 69-150 | awk -F "//device" {'print $1'} | awk -F "/" {'print $NF'} | sed '/^$/d' | tail -n1)
    if ! [[ "$usbPort" ]]; then usbPort=$(usbip list -l | grep 0a89 | grep busid | tail -2 | awk {'print $3'} | tail -1); fi
  elif [[ $1 == "18082" ]]; then
    usbPort=$(vboxmanage list usbhost 2>/dev/null | grep -A3 Rutoken | grep -B1 Captured | cut -b 69-150 | awk -F "//device" {'print $1'} | awk -F "/" {'print $NF'} | sed '/^$/d' | tail -n1)
    VBoxManage controlvm "Ubuntu" poweroff && service pcscd restart
    if ! [[ "$usbPort" ]]; then usbPort=$(usbip list -l | grep 0a89 | grep busid | tail -2 | awk {'print $3'} | head -1); fi
  else
    printf '\033[0;31m%s\e[m\n' "Неизвестный утм порт $utmPort"
  fi
  usbip bind -b "$usbPort"
  tun=$(ifconfig | grep "addr:10.8" | awk {'print $2'} | sed  -e "s/addr://")
  printf '\033[0;33m%s\e[m\n' "Для для подключения устройства на клиенте выполнить:"
  printf '\e[1;18m%s\e[m\n' "usbip attach -r $tun -b $usbPort"
  printf '\033[0;33m%s\e[m\n' "Для извлечения устройства на сервере выполнить:"
  printf '\e[1;18m%s\e[m\n' "usbip unbind -b $usbPort && service pcscd start && supervisorctl restart utm"
  printf '\033[0;33m%s\e[m\n' "Для извлечения устройства на клиенте выполнить:"
  printf '\e[1;18m%s\e[m\n\n' "usbip detach -p 00"
  if [[ $1 == "8082" ]]; then
    printf '\033[1;32m%s\e[m\n\n' "$(cat /linuxcash/cash/conf/ncash.ini | grep -E "inn|kpp|address|name" | sed -e 's/"/ /g')"
  fi
  printf '\e[1;18m%s\e[m\n' "PIN-код Пользователя   - 12345678"
  printf '\e[1;18m%s\e[m\n' "PIN-код Администратора - 87654321"
}

function main {
  utmPort=$1
  Fact_Address=$(grep address /linuxcash/cash/conf/ncash.ini | cut -d= -f2 | tr -d '"')
  fsrar=$(grep fsrarId /linuxcash/cash/conf/ncash.ini.d/egaisttn.ini | grep -oE "[0-9]+" | head -1)
  Full_Name=$(grep name /linuxcash/cash/conf/ncash.ini | cut -d= -f2 | awk '{print substr ($0, 1, length($0)-1)}' | awk '{print substr ($0, 2)}')
  KPP=$(grep kpp /linuxcash/cash/conf/ncash.ini | grep -oE '[0-9]+')
  usbip_bind_and_message "$utmPort"
}

if [[ "$1" ]]; then
  main "$1"
else
	printf '\033[0;33m%s\e[m\n' "Выберите порт:"
	printf '\033[0;35m1: \e[m\e[1;18m%s\e[m\n' "8082"
	printf '\033[0;35m2: \e[m\e[1;18m%s\e[m\n' "18082"
	read -p "Строка: " line
	if [[ $line == 1 ]]; then
		main 8082
	elif [[ $line == 2 ]]; then
		main 18082
	else
		printf '\033[0;31m%s\e[m\n' "Нету данной строки '$line'"
	fi
  google_sheets
fi
