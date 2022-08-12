#!/usr/bin/env bash

# Если два ключа Busy
if [[ `vboxmanage list usbhost | grep -A 2 Rutoken | awk '/Current State:/  {print $3}' | grep -c Busy` == 2 ]]; then
  /etc/rc.local
fi

if [[ `/root/rtecpinfo.sh |& grep -i -c "No slots."` > 0  ]]; then
  for port in `grep -ri rutoken /sys/bus/usb/drivers/usb/*/* 2>/dev/null | awk -F "/product" {'print $1'} | awk -F "/" {'print $NF'} | sort | uniq`; do
    if [[ `grep -c $port /etc/rc.local` > 0 ]]; then
      continue
    fi
    echo $port > /sys/bus/usb/drivers/usb/unbind ; echo $port  "[off]"
    sleep 2
    echo $port  > /sys/bus/usb/drivers/usb/bind ; echo $port  "[on]"
    sleep 2
    service pcscd restart;
  done
fi

if [[ `/root/rtecpinfo.sh |& grep -i -c "error"` > 0 ]]; then
  service pcscd restart
fi

if [[ `/home/user/rtecpinfo.sh |& grep -c "No slots."` > 0  || `/home/user/rtecpinfo.sh |& grep -i -c "error"` > 0 ]]; then
  for port in `grep -ri rutoken /sys/bus/usb/drivers/usb/*/* 2>/dev/null | awk -F "/product" {'print $1'} | awk -F "/" {'print $NF'} | sort | uniq`; do
    if [[ `grep -c $port /etc/rc.local` > 0 ]]; then
      continue
    fi
    echo $port > /sys/bus/usb/drivers/usb/unbind ; echo $port  "[off]"
    sleep 2
    echo $port  > /sys/bus/usb/drivers/usb/bind ; echo $port  "[on]"
    sleep 2
    service pcscd restart;
  done
fi
