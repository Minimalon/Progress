#!/usr/bin/env bash
inn=$(grep inn  /linuxcash/cash/conf/ncash.ini | grep -oE '[0-9]+')
if [[ $(grep -c $inn /linuxcash/net/server/server/All/Artur/whiteSKB.txt) == 0 ]]; then
  printf "ИНН не в белом списке $inn\n"
  exit
fi


if [[ $(grep -c 'deb http://ru.archive.ubuntu.com/ubuntu/ trusty main restricted universe multiverse' /etc/apt/sources.list.d/artix.list) == 0 ]]; then
  echo 'deb http://ru.archive.ubuntu.com/ubuntu/ trusty main restricted universe multiverse' >> /etc/apt/sources.list.d/artix.list
  echo 'deb-src http://ru.archive.ubuntu.com/ubuntu/ trusty main restricted universe multiverse' >> /etc/apt/sources.list.d/artix.list
else
  echo "Ссылки уже есть в соурс листе"
fi


if [[ $(apt-cache show libx11-dev) ]]; then
  # apt update
  #
  # sudo apt-get install libx11-dev -y
  echo 123
else
  echo 321
  # echo "libx11-dev Уже установлен"
fi

if [[ $(ls /root | grep -c 'skb-0.3.tar.gz') == 0 ]]; then
  cd /root
  wget http://plhk.ru/static/skb/skb-0.3.tar.gz
  tar xfvz skb-0.3.tar.gz
else
  echo "Скачан уже skb-0.3.tar.gz"
fi

if ! [[ $(DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon skb -1) ]]; then
  cd skb-0.3
  make
  sudo make install
  if [[ $(echo $?) == 0 ]]; then
    printf "`hostname` ok\n" >> /linuxcash/net/server/server/logs/skb.txt
  else
    printf "`hostname` ERROR\n" >> /linuxcash/net/server/server/logs/skb.txt
  fi
else
  echo "skb Уже установлен"
fi
