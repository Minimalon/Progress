#!/usr/bin/env bash

read -p "Штрихкод: " EAN
read -p "Цена: " price

mysql dictionaries -e  'UPDATE tmc SET price = $price WHERE bcode = $EAN;'
mysql dictionaries -e  'UPDATE barcodes SET price = $price WHERE barcode = $EAN;'
printf '\033[0;32m%s\e[m\n' "OK"
