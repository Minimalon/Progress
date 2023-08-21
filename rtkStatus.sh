#!/usr/bin/env bash

lockfile="/var/lock/.rtkStatus.exclusivelock"

if [ -f "$lockfile" ]; then
	echo "File \"$lockfile\" exists"
	echo "less +F /linuxcash/logs/current/rtkStatus.log"
fi


(
  flock -x -w 2 200 || exit 1

for LIBPKCS11 in "/opt/aktivco/rutokenecp/i386/librtpkcs11ecp.so" "/opt/aktivco/rutokenecp/amd64/librtpkcs11ecp.so" "/usr/lib/librtpkcs11ecp.so" "/opt/utm/lib/librtpkcs11ecp.so" "/root/librtpkcs11ecp.so"; do
	if [[ -f "$LIBPKCS11" && -r "$LIBPKCS11" && -s "$LIBPKCS11" ]]; then
		break
	fi
done

function logger {
	log_file_path="/linuxcash/net/server/server/logs/rtkStatus.txt"
	hostname=$(uname -n)
	grep_all=$(grep "$hostname $1" $log_file_path)
	count_all=$(echo "$grep_all" | grep -c "$hostname $1" )
	count_today=$(echo "$grep_all" | grep -c "$(date +"%d/%m/%Y")")
	count_hour=$(echo "$grep_all "| grep "$(date +"%d/%m/%Y")" | grep -c "$(date +"%H:")")
	echo "$1"
	printf '%s %s %s %s\n' "$(date +"%H:%M %d/%m/%Y")" "$hostname" "$1" "[All:$count_all Day:$count_today Hour:$count_hour]" >> $log_file_path
}

function debug() {
	echo "$1"
	log_file_path="/linuxcash/logs/current/rtkStatus.log"
	printf '%s %s\n' "$(date +"%H:%M %d/%m/%Y")" "$1" >> $log_file_path
}

function restart_rutoken {
	rutokens=$(grep -r 'Rutoken ECP' /sys/bus/usb/drivers/usb/*/product | awk -F '/' '{print $7}')
	debug "$rutokens"
	count_rutokens=$(grep -r 'Rutoken ECP' /sys/bus/usb/drivers/usb/*/product | awk -F '/' '{print $7}' | wc -l)
	debug "Рутокенов: $count_rutokens"
	if (( count_rutokens == 0 )); then
		debug "Нету рутокенов"
	fi

	if (( count_rutokens == 1 )); then
		echo "$rutokens" > /sys/bus/usb/drivers/usb/unbind ; echo "$rutokens" "[off]"
		sleep 15
		echo "$rutokens" > /sys/bus/usb/drivers/usb/bind ; echo "$rutokens" "[on]"
		sleep 2
		#service pcscd restart
	fi

	if (( count_rutokens == 2 )); then
		if ! [ "$(command -v vboxmanage)" ];then
		debug "Нет vboxmanage"
			for usb in $rutokens; do
				echo "$usb" > /sys/bus/usb/drivers/usb/unbind ; echo "$usb" "[off]"
				sleep 15
				echo "$usb" > /sys/bus/usb/drivers/usb/bind ; echo "$usb" "[on]"
			done
			sleep 2
			#service pcscd restart
		else
		debug "Есть vboxmanage"
			if grep -r -q 'utm2' /etc/supervisor/conf.d/; then
			debug "Есть utm2"
				for usb in $rutokens; do
					echo "$usb" > /sys/bus/usb/drivers/usb/unbind ; echo "$usb" "[off]"
					sleep 15
					echo "$usb" > /sys/bus/usb/drivers/usb/bind ; echo "$usb" "[on]"
				done
				sleep 2
				#service pcscd restart
			else
				debug "Нет utm2"
				usbPort=$(vboxmanage list usbhost 2>/dev/null | grep -A3 "Rutoken ECP" | grep -E -B1 'Busy|Available' | cut -b 69-150 | awk -F "//device" {'print $1'} | awk -F "/" {'print $NF'} | sed '/^$/d')
				for usb in $usbPort; do
					if [ -f "/etc/rc.local" ]; then
						if grep -q "$usb" /etc/rc.local; then
							debug "Пропустил $usb"
							continue
						fi
					fi
					debug "Перевоткнул $usb"
					echo "$usb" > /sys/bus/usb/drivers/usb/unbind ; echo "$usb" "[off]"
					sleep 15
					echo "$usb" > /sys/bus/usb/drivers/usb/bind ; echo "$usb" "[on]"
				done
				sleep 2
				#service pcscd restart
			fi
		fi
	fi
}

function check_count_rutoken() {
	count_slots=$(pkcs11-tool --module "$LIBPKCS11" --list-token-slots | grep -c 'Slot')
	rutokens=$(grep -r 'Rutoken ECP' /sys/bus/usb/drivers/usb/*/product | awk -F '/' '{print $7}' | wc -l)
	if (( rutokens > count_slots )); then
		debug "Рутокенов больше чем найдено слотов в pcscd '$rutokens' > $count_slots'"
		debug "$(pkcs11-tool --module "$LIBPKCS11" --list-token-slots)"
		return 1
	else
		return 0
	fi
}

function check_syslog() {
	syslog_error=$(tail /var/log/syslog | grep -c 'EHStatusHandlerThread() Error communicating to: Aktiv Rutoken ECP 00 00')
	if (( syslog_error > 0 )); then
		return 1
	else
		return 0
	fi
}


function check_rtecpinfo(){
	status="/tmp/rtkStatus.slots"
	# error="/tmp/rtkStatus.error"
	# /root/rtecpinfo.sh > "$error"
	pkcs11-tool --module "$LIBPKCS11" --list-token-slots 2> "$status"
	# debug "$error = $(cat $error)"

	if grep -q "No slot" "$status"; then
		debug "ERROR $status = $(cat $status)"
		return 1
	fi

	# if grep -q -i "error" "$error"; then
	# 	debug "error = $(cat $status)"
	# 	return 1
	# fi
	return 0
}

function check_utm(){
	if [[ $(curl -I 127.0.0.1:8082 2>/dev/null | head -n 1 | cut -d$' ' -f2) == 200 ]]; then
		utm_8082=$(curl -X GET http://localhost:8082/api/info/list | grep -c 'RSA ERROR')
		if (( utm_8082 > 0 )); then
			debug "supervisorctl restart utm"
			supervisorctl restart utm
			logger utm_8082
		fi
	fi

	if grep -q -r 'utm2' "/etc/supervisor/conf.d/"; then
		if [[ $(curl -I 127.0.0.1:18082 2>/dev/null | head -n 1 | cut -d$' ' -f2) == 200 ]]; then
			utm_18082=$(curl -X GET http://localhost:18082/api/info/list | grep -c 'RSA ERROR')
			if (( utm_18082 > 0 )); then
				debug "supervisorctl restart utm2"
				supervisorctl restart utm2
				logger utm_18082
			fi
		fi
	fi
}

main() {
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

	if ! check_syslog; then
		for((i=0;i<5;i++)); do
			debug "check_syslog $i"
			restart_rutoken
			sleep 120
			if check_syslog; then
				logger syslog_OK
				debug syslog_OK
				break
			fi
			if (( i == 4 )); then
				service pcscd restart
				sleep 30
				if ! check_syslog; then
					logger syslog_ERROR_r
					debug syslog_ERROR_r
				else
					logger syslog_OK_r
					debug syslog_OK_r
				fi
			fi
		done
	fi

	if ! check_rtecpinfo; then
		count_rutokens=$(grep -r 'Rutoken ECP' /sys/bus/usb/drivers/usb/*/product | awk -F '/' '{print $7}' | wc -l)
		if (( count_rutokens > 0 )); then
			restart_rutoken
			sleep 30
			if ! check_rtecpinfo; then
				service pcscd restart
				sleep 30
				if ! check_rtecpinfo; then
					logger noSlots_ERROR_r
					debug noSlots_ERROR_r
				else
					logger noSlots_OK_r
					debug noSlots_OK_r
					check_utm
				fi
			else
				logger noSlots_OK
				debug noSlots_OK
				check_utm
			fi
		fi
		sleep 300
	else
		if grep -q -r 'utm2' "/etc/supervisor/conf.d/"; then
			if ! check_count_rutoken ; then
				restart_rutoken
				sleep 30
				if ! check_count_rutoken; then
					service pcscd restart
					sleep 30
					if ! check_count_rutoken; then
						logger count_slots_ERROR_r
						debug count_slots_ERROR_r
					else
						logger count_slots_OK_r
						debug count_slots_OK_r
						check_utm
					fi
				else
					logger count_slots_OK
					debug count_slots_OK
					check_utm
				fi
				sleep 120
			fi
		fi
	fi

	if check_rtecpinfo; then
		if check_syslog; then
			check_utm
		fi
	fi

	if [ "$(command -v vboxmanage)" ]; then
		if ! grep -q -r 'utm2' "/etc/supervisor/conf.d/"; then
			if [ -f "/etc/rc.local" ]; then
				count_state=$(vboxmanage list usbhost 2>/dev/null | grep -A3 "Rutoken ECP" | grep -Ec 'Busy|Available')
				if (( count_state > 1 )); then
					runningvms=$(vboxmanage list runningvms | grep -c "Ubuntu")
					if (( runningvms > 0 )); then
						pivoKey=$(grep 'VBoxM' /etc/rc.local | cut -d '|' -f2 | cut -d ' ' -f3)
						UUID=$(VBoxManage list usbhost | grep "$pivoKey" -B8 | grep UUID | /usr/bin/cut -d':' -f2 | awk '{print $1}')
						debug "$pivoKey $UUID"
						VBoxManage controlvm "Ubuntu" usbattach "$UUID"
						logger pivoKey
					fi
				fi
			fi
		fi
	fi
}

while true; do
	main
	debug "=========================================================="
	sleep 60
done

) 200>$lockfile
