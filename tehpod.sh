#!/usr/bin/env bash
mkdir -p /root/flags/tehpod_files/logs

# --------------------- notifications --------------------------
for notifi in /root/notifications/*; do
  [[ -e "$notifi" ]] || continue
  printf "\033[1;36m%s:\e[m \033[1;18m%s\e[m\n" "$notifi" "$(cat "$notifi")"
done
# --------------------------------------------------------------

if [[ $(curl -I 127.0.0.1:8082 2>/dev/null | head -n 1 | cut -d$' ' -f2) == 200 ]]; then
  ooo_org_info=$(curl -X GET "http://localhost:8082/api/gost/orginfo" 2>/dev/null)
  ooo=$(echo "$ooo_org_info" | sed 's/,/\n/g' | grep '"cn"' | cut -d ':' -f2 | tr -d \"\\\\ 2>/dev/null)
  ooo_fsrar=$(curl -X GET http://localhost:8082/diagnosis 2>/dev/null | grep CN | cut -b 7-18)
  ooo_inn=$(echo "$ooo_org_info" | sed 's/,/\n/g' | grep inn | grep -oE '[0-9]+')
  ooo_kpp=$(grep kpp /linuxcash/cash/conf/ncash.ini | grep -oE '[0-9]+')
else
  ooo="-"
fi

if [[ $(curl -I 127.0.0.1:18082 2>/dev/null | head -n 1 | cut -d$' ' -f2) == 200 ]]; then
  ip_org_info=$(curl -X GET "http://localhost:18082/api/gost/orginfo" 2>/dev/null)
  ip=$(echo "$ip_org_info" | sed 's/,/\n/g' | grep '"cn"' | cut -d ':' -f2 | tr -d \"\\\\ 2>/dev/null)
  ip_fsrar=$(curl -X GET http://localhost:18082/diagnosis 2>/dev/null | grep CN | cut -b 7-18)
  ip_inn=$(echo "$ip_org_info" | sed 's/,/\n/g' | grep inn | grep -oE '[0-9]+')
  ip_inn=$(echo "$ip_org_info" | sed 's/,/\n/g' | grep inn | grep -oE '[0-9]+')
else
  ip="-"
  ip_fsrar=$(grep fsrarId /linuxcash/cash/conf/ncash.ini.d/egaisttn.ini | tail -n1 | grep -oE '[0-9]+')
  ip_inn=$(grep inn /linuxcash/cash/conf/utm2info.ini | grep -oE '[0-9]+')
fi

printf '\033[1;32m%s\e[m\n' "$(grep address /linuxcash/cash/conf/ncash.ini | cut -d= -f2 | tr -d '"')"

if [[ $ooo != "-" ]]; then
  printf '\033[0;36m%s\e[m\n' "8082: $ooo $ooo_fsrar $ooo_inn $ooo_kpp"
else
  ooo=$(grep name /linuxcash/cash/conf/ncash.ini | cut -d '=' -f2 |tr -d \"\\\\ 2>/dev/null)
  ooo_fsrar=$(grep fsrarId /linuxcash/cash/conf/ncash.ini.d/egaisttn.ini | head -n1 | grep -oE '[0-9]+')
  ooo_inn=$(grep inn /linuxcash/cash/conf/ncash.ini | grep -oE '[0-9]+')
  ooo_kpp=$(grep kpp /linuxcash/cash/conf/ncash.ini | grep -oE '[0-9]+')
  printf '\033[0;31m%s\e[m\n' "8082: $ooo FSRAR:$ooo_fsrar ИНН:$ooo_inn КПП:$ooo_kpp"
fi

if [[ $ip != "-" ]]; then
  printf '\033[0;36m%s\e[m\n' "18082: $ip $ip_fsrar $ip_inn"
else
  printf '\033[0;31m%s\e[m\n' "18082: $ip FSRAR:$ip_fsrar ИНН:$ip_inn"
fi

# --------------------- 1C --------------------------
hostname=$(hostname | cut -d- -f2)
host_1c=$(grep "$hostname" /root/flags/our_1C.txt)
if [[ $hostname == "$host_1c" ]]; then
  printf '\033[42;34m%s\e[m\n' "Обслуживаются у нас по 1C"
else
  printf '\033[41;38m%s\e[m\n' "Обслуживаются у нас по 1C"
fi

if [[ $(grep -c "CS" /root/flags/exchangesystems) == 0 ]]; then
  if ! [[ $hostname == "$host_1c" ]]; then
    printf '\033[42;34m%s\e[m\n' "Своя 1С, обслуживаются не у нас"
  else
    printf '\033[41;38m%s\e[m\n' "Своя 1С, обслуживаются не у нас"
  fi
else
  printf '\033[41;38m%s\e[m\n' "Своя 1С, обслуживаются не у нас"
fi

if [[ $(grep -c "CS" /root/flags/exchangesystems) == 1 ]]; then
  printf '\033[42;34m%s\e[m\n' "Наша 1С"
else
  printf '\033[41;38m%s\e[m\n' "Наша 1С"
fi
#----------------------------------------------------



printf '\033[0;33m%s\e[m\n' "Выберите ошибку:"
printf '\033[0;35m1: \e[m\e[1;18m%s\e[m\n' "Смена 24 часа"
printf '\033[0;35m2: \e[m\e[1;18m%s\e[m\n' "Ошибка при проверке ключа"
printf '\033[0;35m3: \e[m\e[1;18m%s\e[m\n' "Отсутсвует RSA сертификат"
printf '\033[0;35m4: \e[m\e[1;18m%s\e[m\n' "Штрихкод не найден"
printf '\033[0;35m5: \e[m\e[1;18m%s\e[m\n' "Товару не назначено ККМ"
printf '\033[0;35m6: \e[m\e[1;18m%s\e[m\n' "Товар с такой акцизной маркой запрещен к продаже"
printf '\033[0;35m7: \e[m\e[1;18m%s \033[0;33m (Есть новое) \e[m\n' "SQL"
printf '\033[0;35m8: \e[m\e[1;18m%s\e[m\n' "Документы"
printf '\033[0;35m9: \e[m\e[1;18m%s\e[m\n' "Reconfig MySQL"
printf '\033[0;35m10: \e[m\e[1;18m%s\e[m\n' "Восстановить цены сохранённые через F2"
printf '\033[0;35m11: \e[m\e[1;18m%s\e[m\n' "usbip"

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
  printf '\033[0;35m3: \e[m\e[1;18m%s\e[m\n' "Акцизная марка не соответствует штрих-коду"
  printf '\033[0;35m4: \e[m\e[1;18m%s\e[m\n' "Изменить единицу измерения"
  read -p "Номер строки: " SQLanswer
elif [[ $errorNumber == 8 ]]; then
  /root/flags/tehpod_files/8/8.sh
elif [[ $errorNumber == 9 ]]; then
  read -p  "Уверены? [y/n]: " -n 1 -r
  echo
  echo "$REPLY" | grep -ic 'y'
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    /root/flags/tehpod_files/9.sh
  elif [[ $REPLY =~ ^[Nn]$ ]]; then
    printf '\033[0;33m%s\e[m\n' "Молодец что передумал"
    exit
  else
    printf '\033[0;31m%s\e[m\n' "Неизвестный ответ '$REPLY'"
  fi
elif [[ $errorNumber == 10 ]]; then
  printf '\033[0;35m1: \e[m\e[1;18m%s\e[m\n' "Добавить сохранённые файлы за всё время существование кассы"
  printf '\033[0;35m2: \e[m\e[1;18m%s\e[m\n' "Сохранённые цены за определенное количество последних дней"
  read -p "Номер строки: " savePriceAnswer
elif [[ $errorNumber == 11 ]]; then
  /root/flags/tehpod_files/11.sh
else
  printf '\033[0;31m%s\e[m\n' "Данной ошибки не существует '$errorNumber'"
fi

if [[ $SQLanswer == 1 ]]; then /root/flags/tehpod_files/7/1.sh; fi
if [[ $SQLanswer == 2 ]]; then /root/flags/tehpod_files/7/2.sh; fi
if [[ $SQLanswer == 3 ]]; then /root/flags/tehpod_files/7/3.sh; fi
if [[ $SQLanswer == 4 ]]; then /root/flags/tehpod_files/7/4.sh; fi

if [[ $whiteAnswer == 1 ]]; then read -p "Акцизная марка: " amark; /root/flags/tehpod_files/6.sh "$amark"; fi
if [[ $whiteAnswer == 2 ]]; then /root/flags/tehpod_files/6.sh; fi

if [[ $eanAnswer == 1 ]]; then /root/flags/tehpod_files/4/1.py; fi
if [[ $eanAnswer == 2 ]]; then /root/flags/tehpod_files/4/2.py; fi

if [[ $savePriceAnswer == 1 ]]; then
  printf '\033[0;33m%s\e[m\n' "Отравил восстановление цен в фоновом режиме. Это может занять больше часа. Чтобы узнать закончился скрипт или нет нужно смотреть логи 'less /root/flags/tehpod_files/logs/10.log'"
  nohup /root/flags/tehpod_files/10.sh &
fi
if [[ $savePriceAnswer == 2 ]]; then
  read -p "Количество дней:" days
  printf '\033[0;33m%s\e[m\n' "Отравил восстановление цен в фоновом режиме. Это может занять больше часа. Чтобы узнать закончился скрипт или нет нужно смотреть логи 'less /root/flags/tehpod_files/logs/10.log'"
  nohup /root/flags/tehpod_files/10.sh "$days" &
fi
