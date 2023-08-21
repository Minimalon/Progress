#!/usr/bin/env bash

TERMINAL_PATH='/linuxcash/logs/current/terminal.log'

mkdir -p /linuxcash/logs/current/artur/
cd "/linuxcash/logs/current/artur/" || exit 1

ean_not_found() {
  # Товар со штрих-кодом не найден
  for ean in $(echo "$terminal" | grep ' WARN  businesslogic  - Товар со штрих-кодом ' | cut -d "'" -f2 | grep -E '^[0-9]{1,13}$' | sort | uniq); do
  if [ -f "cash_eans.txt" ]; then
    if ! grep -q "$ean" cash_eans.txt; then
      /root/ArturAuto/autoEAN/start.py
    fi
  else
    mkdir -p /linuxcash/logs/current/artur
    touch cash_eans.txt
  fi
done
}

ean_not_found_kkm() {
  # Товару не назначено ККМ
  eans=$(echo "$terminal" | grep -B10 'Товару не назначена ККМ' | grep 'Поиск товара со штрих-кодом:' | awk -F ': ' '{print $2}' | grep -E '^[0-9]{1,13}$' | sort | uniq)
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
}

ean_minprice() {
  # Не указана минимальная цена товара
  eans=$(echo "$terminal" | grep -B10 'Не указана минимальная цена товара' | grep 'Поиск товара со штрих-кодом:' | awk -F ': ' '{print $2}' | grep -E '^[0-9]{1,13}$' | sort | uniq)
  for ean in $eans; do
    if ! [ -f "ean_minprice.txt" ]; then
      echo "$ean" >> ean_minprice.txt
      /root/ArturAuto/autoEAN/start.py -u "$ean"
    else
      if grep -q "$ean" ean_minprice.txt; then
        continue
      else
        /root/ArturAuto/autoEAN/start.py -u "$ean"
        echo "$ean" >> ean_minprice.txt
      fi
    fi
    if grep -q "$ean" /linuxcash/net/server/server/logs/checkBarcodes/ean_minprice.txt ; then
      continue
    else
      echo "$ean" >> /linuxcash/net/server/server/logs/checkBarcodes/ean_minprice.txt
    fi
  done
}


ean_not_tabak() {
  # У товара не указан признак маркированной табачной продукции
  sigi_ean=$(echo "$terminal" | grep -B10 'У товара не указан признак маркированной табачной продукции.' | grep 'Поиск товара со штрих-кодом:' | awk -F ': ' '{print $2}' | grep -E '^[0-9]{1,13}$' | sort | uniq)
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
}


ean_bad_mark(){
  # Товар не маркирован
  mark=$(echo "$terminal" | grep -B10 'ERROR dialog  - Диалог cooбщение: Товар не маркирован.' | grep 'Поиск товара со штрих-кодом:' | awk -F ': ' '{print $2}' | grep -E '^[0-9]{1,13}$' | sort | uniq)
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
}

check_dubl(){
  check_dubl=$(echo "$terminal" | grep -c 'попытка продажи дубля')
  if (( check_dubl > 0 )); then
    echo "127.0.0.1 mark-utm.egais.ru" >> /etc/hosts
    echo "127.0.0.1 filter-utm.egais.ru" >> /etc/hosts
    sleep 28
    DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key KP_Enter
    sleep 1
    DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key F12
    sleep 1
    DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key F12
    sleep 15
    sed -i 's/127.0.0.1 mark-utm.egais.ru//' /etc/hosts
    sed -i 's/127.0.0.1 filter-utm.egais.ru//' /etc/hosts
  fi
}



main(){
  while(true)
  do
    winOn=$(vboxmanage list runningvms | grep -c '"7"')
    if (( winOn == 1 )); then
      continue
    fi

    usbipON=$(pgrep usbipd)
    if (( usbipON > 1 )); then
      continue
    fi

    terminal=$(tail -n15 "$TERMINAL_PATH")
    check_dubl

    if [[ $(cat /root/flags/exchangesystems) == "CS" ]]; then
      ean_not_found
      ean_minprice
      ean_bad_mark
      ean_not_found_kkm
      ean_not_tabak
    fi
    sleep 15
  done
}

main
