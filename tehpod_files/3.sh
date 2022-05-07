#!/usr/bin/env bash

supervisorctl restart utm
sleep 10
usbLinkBusy=`vboxmanage list usbhost | grep -A3 Rutoken | grep -B1 Busy | cut -b 69-150 | awk -F "//device" {'print $1'} | awk -F "/" {'print $NF'} | grep -`
echo $usbLinkBusy > /sys/bus/usb/drivers/usb/unbind ; printf '\033[0;36m%s\e[m\n' "$usbLinkBusy  [off]"
echo $usbLinkBusy  > /sys/bus/usb/drivers/usb/bind ;  printf '\033[0;36m%s\e[m\n' "$usbLinkBusy  [on]"
service pcscd restart

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
