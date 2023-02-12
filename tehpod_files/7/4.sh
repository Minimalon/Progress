#!/usr/bin/env bash

printf '\033[0;35m1: \e[m\e[1;18m%s\e[m\n' "Шт"
printf '\033[0;35m2: \e[m\e[1;18m%s\e[m\n' "Кг"

printf 'Номер строки: '; read -r measure
printf 'Штрихкод: '; read -r ean

if (( measure == 1 )); then
  mysql dictionaries -e "UPDATE tmc, barcodes SET tmc.measure = 1, barcodes.measure = 1 WHERE tmc.code = '$ean' AND barcodes.code = '$ean';"
elif (( measure == 2 )); then
  mysql dictionaries -e "UPDATE tmc, barcodes SET tmc.measure = 2, barcodes.measure = 2 WHERE tmc.code = '$ean' AND barcodes.code = '$ean';"
else
  printf '\033[0;31m%s\e[m\n' "Неизвестная строка у единицы измерения '$measure'"
fi
