#!/usr/bin/env bash
if [[ `curl -I 127.0.0.1:8082 2>/dev/null | head -n 1 | cut -d$' ' -f2` == 200 ]]; then
  ooo=`curl -X GET "http://localhost:8082/api/gost/orginfo" 2>/dev/null | sed 's/,/\n/g' | grep '"cn"' | cut -d ':' -f2 | tr -d \"\\`
  ooo_date=`curl -X GET "http://localhost:8082/api/gost/orginfo" 2>/dev/null | sed 's/,/\n/g' | grep '"to"' | cut -d '"' -f4 | cut -d '+' -f1`
else
  ooo="-"
fi

if [[ `curl -I 127.0.0.1:18082 2>/dev/null | head -n 1 | cut -d$' ' -f2` == 200 ]]; then
  ip=`curl -X GET "http://localhost:18082/api/gost/orginfo" 2>/dev/null | sed 's/,/\n/g' | grep '"cn"' | cut -d ':' -f2 | tr -d \"\\`
  ip_date=`curl -X GET "http://localhost:18082/api/gost/orginfo" 2>/dev/null | sed 's/,/\n/g' | grep '"to"' | cut -d '"' -f4 | cut -d '+' -f1`
else
  ip="-"
fi

printf '\033[0;36m%s\e[m\n' "8082: $ooo $ooo_date"
printf '\033[0;36m%s\e[m\n' "18082: $ip $ip_date"
printf '\033[0;33m%s\e[m\n' "Выберите ошибку:"
printf '\033[0;35m1: \e[m\e[1;18m%s\e[m\n' "Смена 24 часа"
printf '\033[0;35m2: \e[m\e[1;18m%s\e[m\n' "Ошибка при проверке ключа"
printf '\033[0;35m3: \e[m\e[1;18m%s\e[m\n' "Отсутсвует RSA сертификат"
printf '\033[0;35m4: \e[m\e[1;18m%s\e[m\n' "Штрихкод не найден"
printf '\033[0;35m5: \e[m\e[1;18m%s\e[m\n' "Товару не назначено ККМ"
printf '\033[0;35m6: \e[m\e[1;18m%s\e[m\n' "Товар с такой акцизной маркой запрещен к продаже"

read -p "Номер ошибки: " errorNumber
if [[ $errorNumber == 1 ]]; then
  /root/flags/tehpod_files/1.sh
elif [[ $errorNumber == 2 ]]; then
  /root/flags/tehpod_files/2.sh
elif [[ $errorNumber == 3 ]]; then
/root/flags/tehpod_files/3.sh
elif [[ $errorNumber == 4 ]]; then
  /root/flags/tehpod_files/4.sh
elif [[ $errorNumber == 5 ]]; then
  /root/flags/tehpod_files/5.sh
elif [[ $errorNumber == 6 ]]; then
  printf '\033[0;35m1: \e[m\e[1;18m%s\e[m\n' "Найти накладную по акцизной марке"
  printf '\033[0;35m2: \e[m\e[1;18m%s\e[m\n' "Вывести список накладных"
  read -p "Номер строки: " whiteAnswer

  if [[ $whiteAnswer == 1 ]]; then
    read -p "Акцизная марка: " amark
    /root/flags/tehpod_files/6.sh $amark
  elif [[ $whiteAnswer == 2 ]]; then
    /root/flags/tehpod_files/6.sh
  else
    printf '\033[0;31m%s\e[m\n' "Данной строки не существует '$errorNumber'"
  fi
else
  printf '\033[0;31m%s\e[m\n' "Данной ошибки не существует '$errorNumber'"
fi
