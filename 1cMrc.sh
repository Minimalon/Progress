#!/usr/bin/env bash
if [-f /linuxcash/cash/data/tmp/check.img]; then
  if [[ `tail -n50 /linuxcash/logs/current/terminal.log | grep -c "Проверка не пройдена: нарушение минимальной цены"` > 0 ]]; then
    priceMrc=(`tail -n50 /linuxcash/logs/current/terminal.log | grep "Проверка не пройдена: нарушение минимальной цены" | sed 's/(/(\n/g' | cut -d "(" -f2 | cut -d "-" -f2 | cut -d ")" -f1`)
    amarkMrc=`tail -n50 /linuxcash/logs/current/terminal.log | grep "Проверка не пройдена: нарушение минимальной цены" | sed 's/(/(\n/g' |  cut -d "(" -f2 | cut -d "-" -f1`
    count=0
    for mark in ${amarkMrc[@]}; do
      bcode=`sed 's/,/,\n/g' /linuxcash/cash/data/tmp/check.img | grep -B100 $mark | grep -m1 '"bcode"' | cut -d '"' -f4`
      printf "`date +"%H:%M %d/%m/%Y"`\t`uname -n | cut -d '-' -f2,3`\t$bcode\t${priceMrc[$count]}\n" >> /linuxcash/net/server/server/1cMRC.txt
      count=$((count + 1))
    done
  fi
fi
