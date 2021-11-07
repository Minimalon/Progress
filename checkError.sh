#!/bin/bash

a=`curl -X GET http://localhost:8082/api/info/list | grep -c 'RSA ERROR'`
if [[ $a = 0 ]];then
	echo УТМ без ошибок
	exit
fi

server="/linuxcash/net/server/server"

a=`tail -n10 /linuxcash/logs/current/terminal.log | grep -c 'ERROR dialog  - Диалог cooбщение: Отсутствует RSA сертификат'`
b=`tail -n50 /linuxcash/logs/current/terminal.log | grep -c 'ERROR dialog  - Диалог cooбщение: Ошибка при проверке ключа'`

if [ $a == 1 ]; then
 supervisorctl restart utm
 sleep 120
 printf "`date +"%H:%M %d/%m/%Y"` | `uname -n | cut -d '-' -f2,3` | Рутокенов: `vboxmanage list usbhost | grep -c 'Rutoken ECP'` | err: `curl -X GET http://localhost:8082/api/info/list | grep -c 'RSA ERROR'` | `curl -I 127.0.0.1:18082 2>/dev/null | head -n 1 | cut -d$' ' -f2` \n" >> $server/errorRSA.log
 a=`curl -I 127.0.0.1:18082 2>/dev/null | head -n 1 | cut -d$' ' -f2`
	if [[ $a == 200 ]]; then
		DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key KP_Enter
		sleep 1
		DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key F12
		sleep 1
		DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key F12
	fi
fi

if [ $b == 1 ]; then 
 printf "`date +"%H:%M %d/%m/%Y"` | `uname -n | cut -d '-' -f2,3` | Рутокенов: `vboxmanage list usbhost | grep -c 'Rutoken ECP'` | Исхд УТМ: `curl -X GET http://localhost:8082/opt/in | grep -c replyId` | `uname -r` | Обновлен УТМ: `curl -X GET http://localhost:8082/home | grep -c 'Необходимо обновить настройки'` | `grep name /linuxcash/cash/conf/ncash.ini | tr -d \name=` \n" >> $server/errorKEY.log
fi


