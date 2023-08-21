#!/usr/bin/env bash

off="/linuxcash/net/server/server/All/off_2500.txt"
host=$(hostname | cut -d- -f2)

if grep -q "$host" "$off"; then
	rm /root/notifications/up 2>/dev/null
  echo "Уже отключено"
	exit
fi

rm /root/notifications/up 2>/dev/null
echo "$host" >> /linuxcash/net/server/server/All/off_2500.txt
echo "Отключил и удалил объявление"
