#!/bin/bash

server="/linuxcash/net/server/server"
PCduplicate=$(grep -c `uname -n | cut -d '-' -f2,3 | cut -d "|" -f2` $server/rtkStatus.log)
winOn=`vboxmanage list runningvms | grep -c '"7"'`
if [[ $winOn == 1 ]]; then
	exit
fi

usbipON=`pgrep usbipd`
if [[ $usbipON > 1 ]]; then
	exit
fi

a=`tail -n80 /var/log/syslog | grep -c 'EHStatusHandlerThread() Error communicating to: Aktiv Rutoken ECP 00 00'`
countRutoken=`vboxmanage list usbhost | grep -c Rutoken`
if [[ $countRutoken == 1 ]]; then
    if [[ $a > 0 ]]; then
	cd /sys/bus/usb/drivers/usb
	stateUsbLink=(`vboxmanage list usbhost | grep -A 2 Rutoken | awk '/Current State:/  {print $3}'`)
	usbLink=(`vboxmanage list usbhost | grep -A 1 Rutoken | cut -b 69-150 | awk -F "//device" {'print $1'} | awk -F "/" {'print $NF'}`)
	echo $usbLink > unbind ; echo $usbLink  "[off]"
	echo $usbLink  > bind ; echo $usbLink  "[on]"
	service pcscd restart	
	printf "`date +"%H:%M %d/%m/%Y"` | `uname -n | cut -d '-' -f2,3` | err: `curl -X GET http://localhost:8082/api/info/list | grep -c 'RSA ERROR'` | `grep name /linuxcash/cash/conf/ncash.ini | tr -d \name=` | $PCduplicate\n" >> $server/rtkStatus.log
    fi
else

d=`vboxmanage list usbhost | grep -A 2 Rutoken | awk '/Current State:/  {print $3}' | grep -c 'Busy'`
if [[ $d == 2 ]]; then
	pivoKey=`cat /etc/rc.local | grep VBoxM | cut -d '|' -f2 | cut -d ' ' -f3`
	VBoxManage controlvm "Ubuntu" usbattach `VBoxManage list usbhost | grep $pivoKey -B8  | grep UUID | /usr/bin/cut -d':' -f2`
fi

#------------------Repair 18082---------------------
utmERROR=`curl -X GET http://localhost:18082/api/info/list | grep -c 'RSA ERROR'`
if [[ $utmERROR > 0 ]];then
 VBoxManage controlvm "Ubuntu" poweroff
 /etc/rc.local
 sleep 600
 utmERROR=`curl -X GET http://localhost:18082/api/info/list | grep -c 'RSA ERROR'`
 printf "`date +"%H:%M %d/%m/%Y"` | `uname -n | cut -d '-' -f2,3` | err: $utmERROR | `curl -I 127.0.0.1:8082 2>/dev/null | head -n 1 | cut -d$' ' -f2` \n" >> $server/errorPivo.log
fi

c=`curl -X GET http://localhost:8082/api/info/list | grep -c 'RSA ERROR'`
if [[ $c == 0 ]];then
	exit
fi
	cd /sys/bus/usb/drivers/usb
	stateUsbLink=(`vboxmanage list usbhost | grep -A 2 Rutoken | awk '/Current State:/  {print $3}'`)
	usbLinkBusy=`vboxmanage list usbhost | grep -A3 Rutoken | grep -B1 Busy | cut -b 69-150 | awk -F "//device" {'print $1'} | awk -F "/" {'print $NF'}`
	echo $usbLinkBusy > unbind ; echo $usbLinkBusy  "[off]"
	echo $usbLinkBusy  > bind ; echo $usbLinkBusy  "[on]" 
	service pcscd restart
	printf "`date +"%H:%M %d/%m/%Y"` | `uname -n | cut -d '-' -f2,3` | err: `curl -X GET http://localhost:8082/api/info/list | grep -c 'RSA ERROR'` | `grep name /linuxcash/cash/conf/ncash.ini | tr -d \name=` | $PCduplicate | 2! \n" >> $server/rtkStatus.log
fi
