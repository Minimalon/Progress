#!/usr/bin/env bash
config="/linuxcash/net/server/server/All/reconfig"
version=$(cat /linuxcash/cash/data/info/version.json | cut -d '"' -f2)
hostname=$(hostname | cut -d '-' -f2)
if [[ -d $config/$version ]]; then
  printf '\033[0;32m%s\e[m\n' "Делаю реконфиг версии $version"
  mkdir /tmp/dict 2>/dev/null; cd /tmp/dict; rm /tmp/dict/* 2>/dev/null
  mysqldump dictionaries mol > mol.sql
  service mysql stop
  rm /linuxcash/cash/data/mysql/dictionaries/* 2>/dev/null
  # cp -r $config/$version/dict-ap/* /linuxcash/cash/data/mysql/dictionaries/
  unzip $config/$version/dict-ap.zip -d /linuxcash/cash/data/mysql/dictionaries/
  service mysql start; service sync-core2 stop
  printf '\033[0;32m%s\e[m\n' "Восстанавливаю дамп"
  mysql dictionaries < $config/$version/dictionaries.sql; mysql dictionaries < mol.sql
  service sync-core2 start
  rm /linuxcash/cash/exchangesystems/progress/* 2>/dev/null
  pkill artix-gui
  puppet agent -t
  printf '\033[0;32m%s\e[m\n' "Добавляю бутылки из накладных"
  rm -rf /root/ArturAuto/AutoSQL/ttnload/ && /root/ArturAuto/AutoSQL/start.sh
  printf '\033[0;32m%s\e[m\n' "Добавляю бутылки в белый список"
  /root/whiteauto.py && /opt/whitelist/run.sh
  printf '\033[0;32m%s\e[m\n' "Восстанавливаю цены"
  for good in $(cat /linuxcash/net/server/server/dict/$hostname/* | grep -e '#[0-9]' | awk -F ";" '{print $2"|"$4}'); do
    ean=$(echo $good | awk -F '|' '{print $1}')
    price=$(echo $good | awk -F '|' '{print $2}')
    mysql dictionaries -e "UPDATE tmc SET price = $price WHERE bcode = $ean"
    mysql dictionaries -e "UPDATE barcodes SET price = $price WHERE code = $ean"
  done
else
  printf '\033[0;31m%s\e[m\n' "Данной папки не существует $config/$version"
fi
