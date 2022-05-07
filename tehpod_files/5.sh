#!/usr/bin/env bash

function op_mode {
  otdel="$1"
  if [[ "$otdel" == "1" ]]; then
  op_mode="192"
elif [[ "$otdel" == "2" ]]; then
  op_mode="64"
elif [[ "$otdel" == "3" ]]; then
  op_mode="32768"
elif [[ "$otdel" == "4" ]]; then
  op_mode="0"
else
  printf '\033[0;31m%s\e[m\n' "Данного отдела '$otdel' не существует. Только с 1 по 4"
  exit
fi
}

read -p "Отдел товара: " otdel

read -p "Штрихкод: " EAN
op_mode $otdel
mysql dictionaries -e "UPDATE tmc SET dcode = $otdel WHERE bcode = $EAN"
mysql dictionaries -e "UPDATE tmc SET op_mode = $op_mode WHERE bcode = $EAN"

printf '\033[0;32m%s\e[m\n' "Готово"

count_EAN=`grep -c $EAN /linuxcash/net/server/server/changeProduct/2.txt`
if [[ $count_EAN == 0 ]]; then
  printf "$EAN|$otdel|$op_mode\n" >> /linuxcash/net/server/server/changeProduct/2.txt
fi
