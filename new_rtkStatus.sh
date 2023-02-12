#!/usr/bin/env bash

(
  flock -x -w 10 200 || exit 1

function logger {
	log_file_path="rtkStatus.txt"
	hostname=$(uname -n)
	echo "$1"
	printf '%s %s %s\n' "$(date +"%H:%M %d/%m/%Y")" "$1" "$(grep -c "$hostname $1" $log_file_path)" >> $log_file_path
}


function restart_rutoken {
	rutokens=$(grep -r 'Rutoken' /sys/bus/usb/drivers/usb/*/product | awk -F '/' '{print $7}')
	count_rutokens=$(grep -r 'Rutoken' /sys/bus/usb/drivers/usb/*/product | awk -F '/' '{print $7}' | wc -l)

	if (( count_rutokens == 0 )); then
		echo "Нету рутокенов"
	fi

	if (( count_rutokens == 1 )); then
		echo "$rutokens" > /sys/bus/usb/drivers/usb/unbind ; echo "$rutokens" "[off]"
		sleep 15
		echo "$rutokens"  > /sys/bus/usb/drivers/usb/bind ; echo "$rutokens" "[on]"
		sleep 2
		service pcscd restart
	fi

	if (( count_rutokens == 2 )); then
		if ! [ "$(command -v vboxmanage)" ];then
			for usb in $rutokens; do
				echo "$usb" > /sys/bus/usb/drivers/usb/unbind ; echo "$usb" "[off]"
				sleep 15
				echo "$usb"  > /sys/bus/usb/drivers/usb/bind ; echo "$usb" "[on]"
			done
			sleep 2
			service pcscd restart
		else
			if grep -r -q 'utm2' /etc/supervisor/conf.d/;  then
				for usb in $rutokens; do
					echo "$usb" > /sys/bus/usb/drivers/usb/unbind ; echo "$usb" "[off]"
					sleep 15
					echo "$usb"  > /sys/bus/usb/drivers/usb/bind ; echo "$usb" "[on]"
				done
				sleep 2
				service pcscd restart
			else
				usbPort=$(vboxmanage list usbhost 2>/dev/null | grep -A3 Rutoken | grep -E -B1 'Busy|Available' | cut -b 69-150 | awk -F "//device" {'print $1'} | awk -F "/" {'print $NF'} | sed '/^$/d')
				for usb in $usbPort; do
					if [ -f "/etc/rc.local" ]; then
						if grep -q "$usb" /etc/rc.local; then
							continue
						fi
					fi
					echo "$usb" > /sys/bus/usb/drivers/usb/unbind ; echo "$usb" "[off]"
					sleep 15
					echo "$usb"  > /sys/bus/usb/drivers/usb/bind ; echo "$usb" "[on]"
				done
				sleep 2
				service pcscd restart
			fi
		fi
	fi
}

while true
do
  syslog_error=$(tail /var/log/syslog | grep -c 'EHStatusHandlerThread() Error communicating to: Aktiv Rutoken ECP 00 00')
  if (( syslog_error > 0 )); then
    restart_rutoken
    logger syslog_error
    sleep 60
  fi
  sleep 30
done
) 200>/var/lock/new_rtkStatus.lock
