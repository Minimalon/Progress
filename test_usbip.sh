#!/usr/bin/env bash

function generate_pki {
  fsrar=`curl http://localhost:8082/diagnosis 2>/dev/null | grep CN | awk -F '<|>' {'print $3'}`
  info=`curl http://localhost:8082/api/rsa 2>/dev/null | jq . 2>/dev/null | grep $fsrar -C7 | grep Owner_ID -C7`
  INN=`echo $info | jq '.INN' 2>/dev/null | cut -d '"' -f2`
  KPP=`echo $info | jq '.KPP' 2>/dev/null | cut -d '"' -f2`
  Fact_Address=`echo $info | jq '.Fact_Address' 2>/dev/null | awk '{print substr ($0, 1, length($0)-1)}' | awk '{print substr ($0, 2)}'`
  Full_Name=`echo $info | jq '.Full_Name' 2>/dev/null | awk '{print substr ($0, 1, length($0)-1)}' | awk '{print substr ($0, 2)}'`
  ID=$(echo $info | jq '.ID' 2>/dev/null)

  rsa=`curl -G "http://localhost:8082/api/rsa/keygen" 2>/dev/null \
      -H "accept: application/json"  \
      --data "INN=$INN" \
      --data "KPP=$KPP" \
      --data-urlencode "factAddress=$Fact_Address" \
      --data "fsrarid=$fsrar" \
      --data-urlencode "fullName=$Full_Name" \
      --data "id=$ID"`

  if [[ `echo $rsa | grep -c 'true'` > 0 ]]; then
    printf '\033[0;32m%s\e[m\n' "PKI успешно перезаписан"
  else
    printf '\033[0;31m%s\e[m\n' "PKI не перезаписан"
    printf '\033[0;31m%s\e[m\n' "$rsa"
  fi
}

function google_sheets {
  read -p "Ваше имя: " name
  echo "$name||$fsrar||$KPP||$Full_Name||`hostname | cut -d- -f2`||$Fact_Address" >> /linuxcash/net/server/server/logs/rsaTable.txt
  printf '\033[0;32m%s\e[m\n' "Через минуту отмечу в гугл таблице RSA"
}

code=`curl -s -o /dev/null -w "%{http_code}" localhost:8082`
if [ $code != 200 ]; then
  printf '\033[0;31m%s\e[m\n' "УТМ не работает"
else
  generate_pki
fi
google_sheets
