#!/usr/bin/env bash

shopcode=`cat /linuxcash/cash/data/cash.reg | awk -F "shopCode" {'print $2'} | cut -d '"' -f3`
filepath=/linuxcash/net/server/server/whitelist/$shopcode/
back=`date +"%Y-%m-%d_%H-%M-%S"`
innlocal=$(cat /linuxcash/cash/conf/ncash.ini | grep inn | grep -oE "[0-9]{1,}")
inn_in_list=$(cat /opt/whitelist/inn.txt | grep $innlocal | sed 's/\r$//')

# Проверка наличия папок
if ! [ -d /opt/whitelist/work ] ; then
  mkdir -p /opt/whitelist/work
fi

# Копируем белый список
if [ -f "/linuxcash/net/wlist/off.txt" ]; then rsync -zh /linuxcash/net/wlist/off.txt /opt/whitelist/; fi
if [ -f "/linuxcash/net/wlist/inn.txt" ]; then rsync -zh /linuxcash/net/wlist/inn.txt /opt/whitelist/; fi

#Проверяем валидность
if [[ `hostname` == `grep $shopcode /opt/whitelist/off.txt` ]]; then
  printf '\033[0;31m%s\e[m\033[0;36m (номер магазина присутствует в файле off.txt)\e[m\n' "whitelist off"
  if [ -f "/linuxcash/cash/conf/ncash.ini.d/white.ini" ]; then   printf '\033[0;36m%s\e[m\n' "Удаляю white.ini и перезапускаю программу"; rm /linuxcash/cash/conf/ncash.ini.d/white.ini; pkill artix-gui; fi
  exit
fi

#Проверка наличия amark.txt
if ! [[ -f $filepath/amark.txt ]]; then
  printf '\033[0;31m%s\e[m\n' "amark.txt не найден"
  exit
fi
#Проверка наличия инн в списке
if [[ $innlocal == $inn_in_list ]]; then
  printf '\033[0;32m%s\e[m\033[0;36m (ИНН присутствует в файле inn.txt)\e[m\n' "whitelist on"
  if [ -e /opt/whitelist/cat.txt ] ; then
    sleep 300
    scode=$(cat /opt/whitelist/cat.txt)
    filepaths=/linuxcash/net/server/server/whitelist/$shopcode
    echo "rsync for $scode on"
    catpatch=/linuxcash/net/server/server/whitelist
    rsync -zvh $filepaths/amark.txt $catpatch/$scode/
  else
    printf '\033[0;36m%s\e[m\n' "cat off"
  fi

  cd $filepath
  mv amark.txt /opt/whitelist/work
  cd /opt/whitelist/work
  sed -i "s/\r//g" amark.txt
  sed -i '/^$/d' amark.txt

  count=0
  while read line; do
    amark=`echo $line | grep -oE "[A-Z0-9]{150}|[A-Z0-9]{68}"`
    ean=`echo $line | grep -oE "[0-9]{13}$"`
    if [[ $ean ]]; then
      count=$((count + 1))
      mysql dictionaries -e "INSERT  IGNORE INTO \`excisemarkwhite\` (\`excisemarkid\`, \`barcode\`) VALUES ('$amark','$ean');"
    else
      count=$((count + 1))
      mysql dictionaries -e "INSERT  IGNORE INTO \`excisemarkwhite\` (\`excisemarkid\`) VALUES ('`echo $line | awk '{print $1}'`');"
    fi
  done < amark.txt

  printf '\033[0;36m%s\e[m\n' "Добавлено $count марок в белый список"
  zip `date +"%Y-%m-%d_%H-%M-%S"`.zip amark.txt 1>/dev/null
  rm amark.txt
  if [[ `grep -c false /linuxcash/cash/conf/ncash.ini.d/white.ini 2>/dev/null` > 0 ]]; then
    printf '\033[0;32m%s\e[m\n' "Включаю white.ini"
    sed -i 's/false/true/g' /linuxcash/cash/conf/ncash.ini.d/white.ini
    pkill artix-gui
  fi
else
  printf '\033[0;31m%s\e[m\033[0;36m (ИНН отсутствует в файле inn.txt)\e[m\n' "whitelist off"
  if [ -f "/linuxcash/cash/conf/ncash.ini.d/white.ini" ]; then   printf '\033[0;36m%s\e[m\n' "Удаляю white.ini и перезапускаю программу"; rm /linuxcash/cash/conf/ncash.ini.d/white.ini; pkill artix-gui; fi
fi
