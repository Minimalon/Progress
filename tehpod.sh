#!/usr/bin/env bash
if [[ `curl -I 127.0.0.1:8082 2>/dev/null | head -n 1 | cut -d$' ' -f2` == 200 ]]; then
  ooo_org_info=`curl -X GET "http://localhost:8082/api/gost/orginfo" 2>/dev/null`
  ooo=`echo $ooo_org_info | sed 's/,/\n/g' | grep '"cn"' | cut -d ':' -f2 | tr -d \"\\\\ 2>/dev/null`
  ooo_fsrar=`curl -X GET http://localhost:8082/diagnosis 2>/dev/null | grep CN | cut -b 7-18`
  ooo_inn=`echo $ooo_org_info | sed 's/,/\n/g' | grep inn | grep -oE '[0-9]+'`
  ooo_kpp=`grep kpp /linuxcash/cash/conf/ncash.ini | grep -oE '[0-9]+'`
else
  ooo="-"
  ooo_inn=`grep inn /linuxcash/cash/conf/ncash.ini | grep -oE '[0-9]+'`
  ooo_inn=`grep inn /linuxcash/cash/conf/utm2info.ini | grep -oE '[0-9]+'`
  ooo_kpp=`grep kpp /linuxcash/cash/conf/ncash.ini | grep -oE '[0-9]+'`
fi

if [[ `curl -I 127.0.0.1:18082 2>/dev/null | head -n 1 | cut -d$' ' -f2` == 200 ]]; then
  ip_org_info=`curl -X GET "http://localhost:18082/api/gost/orginfo" 2>/dev/null`
  ip=`echo $ip_org_info | sed 's/,/\n/g' | grep '"cn"' | cut -d ':' -f2 | tr -d \"\\\\ 2>/dev/null`
  ip_fsrar=`curl -X GET http://localhost:18082/diagnosis 2>/dev/null | grep CN | cut -b 7-18`
  ip_inn=`echo $ip_org_info | sed 's/,/\n/g' | grep inn | grep -oE '[0-9]+'`
else
  ip="-"
  ip_inn=`grep inn /linuxcash/cash/conf/utm2info.ini | grep -oE '[0-9]+'`
fi

if [[ $ooo != "-" ]]; then
  printf '\033[0;36m%s\e[m\n' "8082: $ooo $ooo_fsrar $ooo_inn $ooo_kpp"
else
  printf '\033[0;31m%s\e[m\n' "8082: $ooo $ooo_fsrar $ooo_inn $ooo_kpp"
fi

if [[ $ip != "-" ]]; then
  printf '\033[0;36m%s\e[m\n' "18082: $ip $ip_fsrar $ip_inn"
else
  printf '\033[0;31m%s\e[m\n' "18082: $ip $ip_fsrar $ip_inn"
fi

printf '\033[0;33m%s\e[m\n' "Выберите ошибку:"
printf '\033[0;35m1: \e[m\e[1;18m%s\e[m\n' "Смена 24 часа"
printf '\033[0;35m2: \e[m\e[1;18m%s\e[m\n' "Ошибка при проверке ключа"
printf '\033[0;35m3: \e[m\e[1;18m%s\e[m\n' "Отсутсвует RSA сертификат"
printf '\033[0;35m4: \e[m\e[1;18m%s\e[m\n' "Штрихкод не найден"
printf '\033[0;35m5: \e[m\e[1;18m%s\e[m\n' "Товару не назначено ККМ"
printf '\033[0;35m6: \e[m\e[1;18m%s\e[m\n' "Товар с такой акцизной маркой запрещен к продаже"
printf '\033[0;35m7: \e[m\e[1;18m%s\e[m\n' "SQL"
printf '\033[0;35m8: \e[m\e[1;18m%s\e[m\n' "Документы"

read -p "Номер ошибки: " errorNumber
if [[ $errorNumber == 1 ]]; then
  /root/flags/tehpod_files/1.sh
elif [[ $errorNumber == 2 ]]; then
  /root/flags/tehpod_files/2.sh
elif [[ $errorNumber == 3 ]]; then
/root/flags/tehpod_files/3.sh
elif [[ $errorNumber == 4 ]]; then
  printf '\033[0;35m1: \e[m\e[1;18m%s\e[m\n' "Автоматически"
  printf '\033[0;35m2: \e[m\e[1;18m%s\e[m\n' "Вручную"
  read -p "Номер строки: " eanAnswer
elif [[ $errorNumber == 5 ]]; then
  /root/flags/tehpod_files/5.sh
elif [[ $errorNumber == 6 ]]; then
  printf '\033[0;35m1: \e[m\e[1;18m%s\e[m\n' "Найти накладную по акцизной марке"
  printf '\033[0;35m2: \e[m\e[1;18m%s\e[m\n' "Вывести список накладных"
  read -p "Номер строки: " whiteAnswer
elif [[ $errorNumber == 7 ]]; then
  printf '\033[0;35m1: \e[m\e[1;18m%s\e[m\n' "Изменить МРЦ"
  printf '\033[0;35m2: \e[m\e[1;18m%s\e[m\n' "Изменить цену"
  read -p "Номер строки: " SQLanswer
elif [[ $errorNumber == 8 ]]; then
  /root/flags/tehpod_files/8/8.sh


else
  printf '\033[0;31m%s\e[m\n' "Данной ошибки не существует '$errorNumber'"
fi

if [[ $SQLanswer == 1 ]]; then /root/flags/tehpod_files/7/1.sh; fi
if [[ $SQLanswer == 2 ]]; then /root/flags/tehpod_files/7/2.sh; fi

if [[ $whiteAnswer == 1 ]]; then read -p "Акцизная марка: " amark; /root/flags/tehpod_files/6.sh $amark; fi
if [[ $whiteAnswer == 2 ]]; then /root/flags/tehpod_files/6.sh; fi

if [[ $eanAnswer == 1 ]]; then /root/flags/tehpod_files/4/1.py; fi
if [[ $eanAnswer == 2 ]]; then /root/flags/tehpod_files/4/2.py; fi
