#!/usr/bin/env bash

(
  flock -x -w 2 200 || exit 1

function logger {
	log_file_path="rtkStatus.txt"
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
		#service pcscd restart
	fi

	if (( count_rutokens == 2 )); then
		if ! [ "$(command -v vboxmanage)" ];then
			for usb in $rutokens; do
				echo "$usb" > /sys/bus/usb/drivers/usb/unbind ; echo "$usb" "[off]"
				sleep 15
				echo "$usb"  > /sys/bus/usb/drivers/usb/bind ; echo "$usb" "[on]"
			done
			sleep 2
			#service pcscd restart
		else
			if grep -r -q 'utm2' /etc/supervisor/conf.d/;  then
				for usb in $rutokens; do
					echo "$usb" > /sys/bus/usb/drivers/usb/unbind ; echo "$usb" "[off]"
					sleep 15
					echo "$usb"  > /sys/bus/usb/drivers/usb/bind ; echo "$usb" "[on]"
				done
				sleep 2
				#service pcscd restart
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
				#service pcscd restart
			fi
		fi
	fi
}

status_path="/tmp/rtkStatus"
for LIBPKCS11 in "/opt/aktivco/rutokenecp/i386/librtpkcs11ecp.so" "/opt/aktivco/rutokenecp/amd64/librtpkcs11ecp.so" "/usr/lib/librtpkcs11ecp.so" "/opt/utm/lib/librtpkcs11ecp.so" "/root/librtpkcs11ecp.so"; do
				if [[ -f "$LIBPKCS11" && -r "$LIBPKCS11" && -s "$LIBPKCS11" ]]; then
								break
				fi
done

while true
do
	# grep 'EHStatusHandlerThread() Error communicating to: Aktiv Rutoken ECP 00 00' /var/log/syslog
	syslog_error=$(tail /var/log/syslog | grep -c 'EHStatusHandlerThread() Error communicating to: Aktiv Rutoken ECP 00 00')
	if (( syslog_error > 0 )); then
		restart_rutoken
		logger syslog_error
		sleep 60
	fi

	pkcs11-tool --module "$LIBPKCS11" --list-token-slots 2> "$status_path"
	if grep -q -E "error|No slot" "$status_path"; then
		restart_rutoken
		sleep 5
		service pcscd restart
		count_rutokens=$(grep -r 'Rutoken ECP' /sys/bus/usb/drivers/usb/*/product | awk -F '/' '{print $7}' | wc -l)
		if (( count_rutokens > 0 )); then
			logger rtkStatus
		fi

		sleep 300
	else
		if (( syslog_error == 0)); then
			if [[ $(curl -I 127.0.0.1:8082 2>/dev/null | head -n 1 | cut -d$' ' -f2) == 200 ]]; then
				utm_8082=$(curl -X GET http://localhost:8082/api/info/list | grep -c 'RSA ERROR')
				if (( utm_8082 > 0 )); then
					supervisorctl restart utm
					logger utm_8082
				fi
			fi
		fi
	fi
sleep 60
done
) 200>/var/lock/.new_rtkStatus.exclusivelock
