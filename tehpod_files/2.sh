#!/usr/bin/env bash

printf '\033[0;36m%s\e[m\n' "Перевтыкаю рутокен"

usbLinkBusy=`vboxmanage list usbhost | grep -A3 Rutoken | grep -B1 Busy | cut -b 69-150 | awk -F "//device" {'print $1'} | awk -F "/" {'print $NF'}`
echo $usbLinkBusy > /sys/bus/usb/drivers/usb/unbind ; printf '\033[0;36m%s\e[m\n' "$usbLinkBusy  [off]"
echo $usbLinkBusy  > /sys/bus/usb/drivers/usb/bind ;  printf '\033[0;36m%s\e[m\n' "$usbLinkBusy  [on]"
sleep 10
service pcscd restart
sleep 5
DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key KP_Enter
sleep 1
DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key F12
sleep 1
DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key F12
sleep 2

if [[ `curl -X GET http://localhost:8082/home | grep -c 'Проблемы с RSA'` == 0 ]]; then
  printf '\033[0;32m%s\e[m\n' "УТМ работает"
else
  printf '\033[0;36m%s\e[m\n' "Перузапускаю УТМ"
  waitSeconds=10
  while true; do
    if (( $waitSeconds == 250 )); then
      printf '\033[0;31m%s\e[m\n' "УТМ не загрузился за 4 минуты"
      printf '\033[0;36m%s\e[m\n' "Нужно перевоткнуть ключ или перезагрузить комп"
      exit
    fi

    if (( $waitSeconds % 130 == 0 )); then
      usbLinkBusy=`vboxmanage list usbhost | grep -A3 Rutoken | grep -B1 Busy | cut -b 69-150 | awk -F "//device" {'print $1'} | awk -F "/" {'print $NF'} | grep -`
      echo $usbLinkBusy > /sys/bus/usb/drivers/usb/unbind ; printf '\033[0;36m%s\e[m\n' "$usbLinkBusy  [off]"
      echo $usbLinkBusy  > /sys/bus/usb/drivers/usb/bind ;  printf '\033[0;36m%s\e[m\n' "$usbLinkBusy  [on]"
      service pcscd restart
    fi

    a=`curl -I 127.0.0.1:8082 2>/dev/null | head -n 1 | cut -d$' ' -f2`
    if [[ $a == 200 ]]; then
      printf '\033[0;32m%s\e[m\n' "УТМ работает"
      exit
    else
      printf '\e[1;18m%s\e[m\n'  "Ожидание загрузки УТМ..."
      sleep 10
    fi
    waitSeconds=$((waitSeconds + 10))
  done
fi
