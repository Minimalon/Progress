#!/bin/bash
while(true)
do
  check_dubl=$(tail -n 10 /linuxcash/logs/current/terminal.log | grep 'попытка продажи дубля' | wc -l)
  if [[ $check_dubl > 0 ]]; then
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
    printf "`date +"%H:%M %d/%m/%Y"`\t`hostname | cut -d '-' -f2,3`\tДубль\n" >> /linuxcash/net/server/server/dublAndKey.txt
  fi

  check_key=`tail /linuxcash/logs/current/terminal.log | grep -c 'Ошибка при проверке ключа'`
  if [[ $check_key > 0 ]]; then
    count_rtk=`vboxmanage list usbhost | grep -A3 Rutoken | grep -c Busy`
    if [[ $c == 1 ]]; then
      usbLinkBusy=`vboxmanage list usbhost | grep -A3 Rutoken | grep -B1 Busy | cut -b 69-150 | awk -F "//device" {'print $1'} | awk -F "/" {'print $NF'}`
      echo $usbLinkBusy > /sys/bus/usb/drivers/usb/unbind
      echo $usbLinkBusy  > /sys/bus/usb/drivers/usb/bind
      sleep 10
      service pcscd restart
      sleep 5
      DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key KP_Enter
      sleep 1
      DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key F12
      sleep 1
      DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key F12
      printf "`date +"%H:%M %d/%m/%Y"`\t`hostname | cut -d '-' -f2,3`\tКлюч\t`curl -X GET http://localhost:8082/home 2>/dev/null | grep -c 'Проблемы с RSA'`\n" >> /linuxcash/net/server/server/dublAndKey.txt
      sleep 30
    fi
  fi

  sleep 5
done
