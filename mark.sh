#!/usr/bin/env bash

eans=`grep -A18 'Товар не маркирован' /linuxcash/logs/current/terminal.log | grep 'Поиск товара со штрих-кодом:' | awk -F: '{print $4}'`

for ean in $eans; do
  if [[ `grep -c $ean /linuxcash/net/server/server/mark.txt` == 0 ]]; then
    name=`echo -e "SELECT name from dictionaries.tmc where code = '$ean';" | mysql --skip-column-names`
    printf "`hostname`\t$ean\t$name\n"
  fi
done
