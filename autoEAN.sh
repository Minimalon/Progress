#!/usr/bin/env bash

terminal=$(cat /linuxcash/logs/current/terminal.log)

mkdir -p /linuxcash/logs/current/artur/
cd "/linuxcash/logs/current/artur/" || exit 1


# Товар со штрих-кодом не найден
for ean in $(echo "$terminal" | grep ' WARN  businesslogic  - Товар со штрих-кодом ' | cut -d "'" -f2 | grep -E '^[0-9]{1,13}$' | uniq); do
  if [ -f "cash_eans.txt" ]; then
    if ! grep -q "$ean" cash_eans.txt; then
      /root/ArturAuto/autoEAN/start.py
    fi
  else
    mkdir -p /linuxcash/logs/current/artur
    touch cash_eans.txt
  fi
done

# Товару не назначено ККМ
eans=$(echo "$terminal" | grep -B10 'Товару не назначена ККМ' | grep 'Поиск товара со штрих-кодом:' | awk -F ': ' '{print $2}' | grep -E '^[0-9]{1,13}$' | uniq)
for ean in $eans; do
  if ! [ -f "not_found_kkm.txt" ]; then
    echo "$ean" >> not_found_kkm.txt
    /root/ArturAuto/autoEAN/start.py -u "$ean"
  else
    if grep -q "$ean" not_found_kkm.txt; then
      continue
    else
      /root/ArturAuto/autoEAN/start.py -u "$ean"
      echo "$ean" >> not_found_kkm.txt
    fi
  fi
  if grep -q "$ean" /linuxcash/net/server/server/logs/checkBarcodes/notFoundKKM.txt ; then
    continue
  else
    echo "$ean" >> /linuxcash/net/server/server/logs/checkBarcodes/notFoundKKM.txt
  fi
done


# У товара не указан признак маркированной табачной продукции
sigi_ean=$(echo "$terminal" | grep -B10 'У товара не указан признак маркированной табачной продукции.' | grep 'Поиск товара со штрих-кодом:' | awk -F ': ' '{print $2}' | grep -E '^[0-9]{1,13}$' | uniq)
for ean in $sigi_ean; do
  if ! [ -f "notMarkSigi.txt" ]; then
    echo "$ean" >> notMarkSigi.txt
    /root/ArturAuto/autoEAN/start.py -u "$ean"
  else
    if grep -q "$ean" notMarkSigi.txt; then
      continue
    else
      /root/ArturAuto/autoEAN/start.py -u "$ean"
      echo "$ean" >> notMarkSigi.txt
    fi
  fi
  if grep -q "$ean" /linuxcash/net/server/server/logs/checkBarcodes/notMarkSigi.txt ; then
    continue
  else
    echo "$ean" >> /linuxcash/net/server/server/logs/checkBarcodes/notMarkSigi.txt
  fi
done


# Товар не маркирован
mark=$(echo "$terminal" | grep -B10 'ERROR dialog  - Диалог cooбщение: Товар не маркирован.' | grep 'Поиск товара со штрих-кодом:' | awk -F ': ' '{print $2}' | grep -E '^[0-9]{1,13}$' | uniq)
for ean in $mark; do
  if ! [ -f "goodNotMark.txt" ]; then
    echo "$ean" >> goodNotMark.txt
    /root/ArturAuto/autoEAN/start.py -u "$ean"
  else
    if grep -q "$ean" goodNotMark.txt; then
      continue
    else
      /root/ArturAuto/autoEAN/start.py -u "$ean"
      echo "$ean" >> goodNotMark.txt
    fi
  fi
  if grep -q "$ean" /linuxcash/net/server/server/logs/checkBarcodes/goodNotMark.txt ; then
    continue
  else
    echo "$ean" >> /linuxcash/net/server/server/logs/checkBarcodes/goodNotMark.txt
  fi
done
