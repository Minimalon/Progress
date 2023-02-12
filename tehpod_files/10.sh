#!/usr/bin/env bash
hostname=$(hostname | cut -d '-' -f2)
if ! [[ -d /linuxcash/net/server/server/dict/$hostname ]]; then
  printf "$(date +"%H:%M %d/%m/%Y")\tНету папки компьютера /linuxcash/net/server/server/dict/$hostname\n" >> /root/flags/tehpod_files/logs/10.log
fi

if [[ "$1" ]]; then
  printf "$(date +"%H:%M %d/%m/%Y")\tСканирую файлы за $1 дней\n" >> /root/flags/tehpod_files/logs/10.log
  files=$(find /linuxcash/net/server/server/dict/"$hostname"/ -type f -mtime -"$1" | sort)
  if [[ $files == 0 ]]; then
    mkdir -p /root/flags/tehpod_files/logs
    printf "$(date +"%H:%M %d/%m/%Y") Найдено 0 файлов" >> /root/flags/tehpod_files/logs/10.log
    exit
  fi
  printf "$(date +"%H:%M %d/%m/%Y")\tСканирую сохранённые цены\n" >> /root/flags/tehpod_files/logs/10.log
  for good in $(cat "$files" | grep -e '#[0-9]' | awk -F ";" '{print $2"|"$4}'); do
    ean=$(echo "$good" | awk -F '|' '{print $1}')
    price=$(echo "$good" | awk -F '|' '{print $2}')
    printf "$(date +"%H:%M %d/%m/%Y")\tИзменил цену $ean на $price\n" >> /root/flags/tehpod_files/logs/10.log
    mysql dictionaries -e "UPDATE tmc SET price = $price WHERE bcode = '$ean' LIMIT 1"
    mysql dictionaries -e "UPDATE barcodes SET price = $price WHERE code = '$ean' LIMIT 1"
  done
  printf "$(date +"%H:%M %d/%m/%Y")\tЗакончил восстановление цен\n" >> /root/flags/tehpod_files/logs/10.log
else
  printf "$(date +"%H:%M %d/%m/%Y")\tСканирую файлы\n" >> /root/flags/tehpod_files/logs/10.log
  files=$(find /linuxcash/net/server/server/dict/"$hostname"/ -type f | sort)
  if [[ $files == 0 ]]; then
    mkdir -p /root/flags/tehpod_files/logs
    printf "$(date +"%H:%M %d/%m/%Y") Найдено 0 файлов" >> /root/flags/tehpod_files/logs/10.log
    exit
  fi
  printf "$(date +"%H:%M %d/%m/%Y")\tСканирую сохранённые цены\n" >> /root/flags/tehpod_files/logs/10.log
  for good in $(cat "$files" | grep -e '#[0-9]' | awk -F ";" '{print $2"|"$4}'); do
    ean=$(echo "$good" | awk -F '|' '{print $1}')
    price=$(echo "$good" | awk -F '|' '{print $2}')
    printf "$(date +"%H:%M %d/%m/%Y")\tИзменил цену $ean на $price\n" >> /root/flags/tehpod_files/logs/10.log
    mysql dictionaries -e "UPDATE tmc SET price = $price WHERE bcode = '$ean' LIMIT 1"
    mysql dictionaries -e "UPDATE barcodes SET price = $price WHERE code = '$ean' LIMIT 1"
  done
  printf "$(date +"%H:%M %d/%m/%Y")\tЗакончил восстановление цен\n" >> /root/flags/tehpod_files/logs/10.log
fi
