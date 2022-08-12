#!/usr/bin/env bash

read -p "Штрихкод: " EAN
read -p "Мин-ая цена: " minprice

mysql dictionaries -e  'UPDATE tmc SET minprice = $minprice WHERE bcode = $EAN;'
mysql dictionaries -e  'UPDATE barcodes SET minprice = $minprice WHERE barcode = $EAN;'
printf '\033[0;32m%s\e[m\n' "OK"

mysql dictionaries -e "UPDATE tmc SET minprice = 50 WHERE name RLIKE '[Вв]ино|[Вв]инный|[Шш]ампанское' AND dcode = 1 AND bcode RLIKE '^\d{13}$'"
