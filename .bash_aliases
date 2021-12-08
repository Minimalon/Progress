alias pa='pkill artix-gui'
alias vlu='vboxmanage list usbhost'
alias utmlog='tail -f -n 500 /opt/utm/transport/l/transport_info.log'
alias tlog='tail -f -n 500 /linuxcash/logs/current/terminal.log'
alias utmres='supervisorctl restart utm'
alias utmdbkill='supervisorctl stop utm;tar -cvvf /opt/utm/transport/$(date +%Y-%m-%d_%H:%M:%S).tar /opt/utm/transport/transportDB;rm -rf /opt/utm/transport/transportDB/;supervisorctl start utm'
alias catcom='cat /opt/comproxy/ComProxy.ini $$ cat /opt/comproxy2/ComProxy.ini'
alias usbres="stateUsbLink=(`vboxmanage list usbhost | grep -A 2 Rutoken | awk '/Current State:/  {print $3}'`);usbLinkBusy=`vboxmanage list usbhost | grep -A3 Rutoken | grep -B1 Busy | cut -b 69-150 | awk -F "//device" {'print $1'} | awk -F "/" {'print $NF'}`;echo $usbLinkBusy > /sys/bus/usb/drivers/usb/unbind;echo $usbLinkBusy off ;echo $usbLinkBusy  > /sys/bus/usb/drivers/usb/bind ; echo $usbLinkBusy on; service pcscd restart"

