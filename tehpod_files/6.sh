#!/usr/bin/env bash

# $1=Номер ТТН
function add_amark {
  TTN=$1
	/root/whiteauto.py "$(echo "$TTN" | cut -d '-' -f2)"; /opt/whitelist/run.sh
}

# $1=Акцизнная марка
function Main {
  cd /root/ttnload/TTN/ || exit
  if [[ "$1" ]]; then
    TTN_count=$(grep -Rc "$1" | grep -c ':1')
    if [[ $TTN_count == 0 ]]; then
      inn=$(grep inn /linuxcash/cash/conf/ncash.ini | grep -oE "[0-9]+")
      kpp=$(grep kpp /linuxcash/cash/conf/ncash.ini | grep -oE "[0-9]+")
      ttn_path="/linuxcash/net/server/server/exchange/$inn/$kpp"
      if [ -d "$ttn_path" ]; then
        cd "$ttn_path"|| exit
        printf '\033[0;33m%s\e[m\n' "Ищу накладную на сервере"
        TTN=$(grep -Flrc "$1" | cut -d/ -f1)
        if ! [[ "$TTN" ]]; then
          printf '\033[0;31m%s\e[m\n' "Накладной с данной акцизой не найдено"
          exit
        fi
      else
        printf '\033[0;31m%s\e[m\n' "Накладной найдено"
        exit
      fi
    elif [[ $TTN_count == 1 ]]; then
      TTN=$(grep -Flrc "$1" | cut -d/ -f1)
    else
      printf '\033[0;31m%s\e[m\n' "Ошибка при поиске акцизы"
      exit
    fi
  else
    count=0
    TTN_list=($(ls -r | grep TTN -m10))
    for line in "${TTN_list[@]}"; do
      count=$((count+1))
      TTN_date=$(ls -l | grep "$line" | awk '{print $6,$7,$8}')
      printf '\033[0;35m%s\e[m' "$count: "
      printf '\e[1;18m%s\e[m' "$line"
      printf '\033[0;36m%s\e[m\n' "$TTN_date"
    done
    printf "Номер строки: "; read -r line
    TTN=${TTN_list[$line-1]}
  fi
    add_amark "$TTN"
}

Main "$1"
