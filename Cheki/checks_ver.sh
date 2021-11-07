#!/bin/bash

#Начало кода
while true
do					   
	if ls /linuxcash/cash/data/tmp/check.img &>/dev/null; then #Проверка действующего чека 
		echo "Есть действующий чек"
		sleep 10
	else
		break
	fi
done

if ls /root/Cheki/ChecksOtl/check.img &>/dev/null; then #Проверка отложенного чека 
	numCheck=0
	echo "Возвращаю check.img"
	mv /root/Cheki/ChecksOtl/check.img /linuxcash/cash/data/tmp/check.img
	/root/Cheki/autocheck.sh
fi			
		while true #Проверка наличие чеков
		do
		numCheck=$(($numCheck+1))
			if ls /root/Cheki/ChecksOtl/check.img_$numCheck &>/dev/null; then #Проверка отложеных чеков в папке
				echo 'Возвращаю чек check.img_'$numCheck
				mv /root/Cheki/ChecksOtl/check.img_$numCheck /linuxcash/cash/data/tmp/check.img
				/root/Cheki/autocheck.sh
			else
				break	
			fi	
		done

rm /root/Cheki/ChecksOtl/backup/*