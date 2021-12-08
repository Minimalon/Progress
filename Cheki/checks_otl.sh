mkdir /root/Cheki/ChecksOtl/backup

if ls /root/Cheki/ChecksOtl/check.img &>/dev/null; then #Проверка отложенного чека
 	numCheck=0
		while true #Проверка наличие чеков
		do
		numCheck=$(($numCheck+1))
			if ls /root/Cheki/ChecksOtl/check.img_$numCheck &>/dev/null; then #Проверка отложенного чека 			
				echo 'Есть отложенный чек check.img_'$numCheck
			else
				echo "Отложил check.img_"$numCheck
				cp /linuxcash/cash/data/tmp/check.img /root/Cheki/ChecksOtl/backup/check.img_$numCheck
				mv /linuxcash/cash/data/tmp/check.img /root/Cheki/ChecksOtl/check.img_$numCheck
				break
			fi
		done
fi

pkill artix-gui

if ls /root/Cheki/ChecksOtl/check.img &>/dev/null; then #Проверка отложенного чека если в папке нету чеков 
	echo "Перезапускаю программу"
else
	echo "Перезапускаю программу"
	echo  "Отложил check.img"
	cp /linuxcash/cash/data/tmp/check.img /root/Cheki/ChecksOtl/backup/check.img
	mv /linuxcash/cash/data/tmp/check.img /root/Cheki/ChecksOtl/check.img
fi

while true
   do
       startArtix=`tail -n10 /linuxcash/logs/current/terminal.log | grep -c 'authentication  - Активация контекста авторизации кассира'`
       if [ $startArtix == 1 ]; then
           break
       fi
   done
DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool type 4
sleep 1
DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key KP_Enter
sleep 1
DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key KP_Enter
echo "Отложил чек"
sleep 1
sleep 6600 && /root/Cheki/checks_ver.sh &

