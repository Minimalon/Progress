#!/usr/bin/env bash


function logger {
	log_file_path="/linuxcash/net/server/server/logs/rtkStatus.txt"
	hostname=$(uname -n)
	echo "$1"
	printf '%s %s %s %s\n' "$(date +"%H:%M %d/%m/%Y")"  "$hostname" "$1" "$(grep -c "$hostname $1" $log_file_path)" >> $log_file_path
}


function restart_rutoken {
	rutokens=$(grep -r 'Rutoken ECP' /sys/bus/usb/drivers/usb/*/product | awk -F '/' '{print $7}')
	count_rutokens=$(grep -r 'Rutoken ECP' /sys/bus/usb/drivers/usb/*/product | awk -F '/' '{print $7}' | wc -l)

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
				usbPort=$(vboxmanage list usbhost 2>/dev/null | grep -A3 "Rutoken ECP" | grep -E -B1 'Busy|Available' | cut -b 69-150 | awk -F "//device" {'print $1'} | awk -F "/" {'print $NF'} | sed '/^$/d')
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

if [ "$(command -v vboxmanage)" ]; then
	winOn=$(vboxmanage list runningvms | grep -c '"7"')
	if [[ $winOn == 1 ]]; then
					exit
	fi
fi

usbipON=$(pgrep usbipd)
if [[ $usbipON -gt 1 ]]; then
        exit
fi
# grep 'EHStatusHandlerThread() Error communicating to: Aktiv Rutoken ECP 00 00' /var/log/syslog
syslog_error=$(tail /var/log/syslog | grep -c 'EHStatusHandlerThread() Error communicating to: Aktiv Rutoken ECP 00 00')
if (( syslog_error > 0 )); then
	restart_rutoken
	logger syslog_error
	sleep 60
fi

status_path="/tmp/rtkStatus"
pkcs11-tool --module /usr/lib/librtpkcs11ecp.so --list-token-slots 2> "$status_path"
if grep -q -E "error|No slot" "$status_path"; then
	restart_rutoken

	count_rutokens=$(grep -r 'Rutoken ECP' /sys/bus/usb/drivers/usb/*/product | awk -F '/' '{print $7}' | wc -l)
	if (( count_rutokens > 0 )); then
		logger rtkStatus
	fi

	sleep 300
fi

# utm_error=$(curl -X GET http://localhost:8082/api/info/list | grep -c 'RSA ERROR')
# if (( utm_error > 0 )); then
# 	restart_rutoken
# 	printf '%s %s %s\n' "$(date +"%H:%M %d/%m/%Y")"  "$(uname -n)" "utm_error" >> /linuxcash/net/server/server/logs/rtkStatus.txt
# fi

if [ "$(command -v vboxmanage)" ]; then
	if ! grep -q -r 'utm2' "/etc/supervisor/conf.d/";  then
		if [ -f "/etc/rc.local" ]; then
			count_state=$(vboxmanage list usbhost 2>/dev/null | grep -A3 "Rutoken ECP" | grep -Ec 'Busy|Available')
			if (( count_state > 1 )); then
				runningvms=$(vboxmanage list runningvms | grep -c "Ubuntu")
				if (( runningvms > 0 )); then
					pivoKey=$(grep 'VBoxM' /etc/rc.local | cut -d '|' -f2 | cut -d ' ' -f3)
					UUID=$(VBoxManage list usbhost | grep "$pivoKey" -B8  | grep UUID | /usr/bin/cut -d':' -f2 | awk '{print $1}')
					echo "$pivoKey" "$UUID"
					VBoxManage controlvm "Ubuntu" usbattach "$UUID"
					logger pivoKey
				fi
			fi
		fi
	fi
fi
