#!/bin/bash

rm /root/Cheki/info.txt
mv /linuxcash/cash/data/tmp/check.img /root/Cheki/chekes/check.img
mkdir /root/Cheki/chekes
cp /root/Cheki/check.img /root/Cheki/chekes/check.img
touch /root/Cheki/chekes/check.txt
pkill artix-gui

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
sleep 1
number=$(grep -o -i allowOnlyExternalDiscount /root/Cheki/chekes/check.img | wc -l)
for ((i=0;i<"$number";i++))
do
barcode=$(sed -n 's/.*bcode" : "\(.*\)", "bcode_mode.*/\1/p' /root/Cheki/chekes/check.img)
exciseMark=$(sed -n 's/.*exciseMark" : "\(.*\)", "exciseMarkAdditionalInfo.*/\1/p' /root/Cheki/chekes/check.img)
price=$(sed -n 's/.*price" : \(.*\), "priceSource".*/\1/p' /root/Cheki/chekes/check.img)
sleep 2
DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key F10
while true
   do
       enterF10=`tail -n5 /linuxcash/logs/current/terminal.log | grep -c 'dialog  - Активация контекста диалога'`
       if [ $enterF10 == 1 ]; then
           break
       fi
   done
echo "$price"
echo "$price" >> /root/Cheki/chekes/check.txt
DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool type --delay 300 "$price"
sleep 1
DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key KP_Enter
sleep 1
echo "$barcode"
echo "$barcode" >> /root/Cheki/chekes/check.txt
DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool type "$barcode"
while true
   do
       enterprice=`tail -n5 /linuxcash/logs/current/terminal.log | grep -c 'dialog  - Деактивация контекста диалога'`
       if [ $enterprice == 1 ]; then
           break
       fi
   done
sleep 2
echo "$exciseMark"
echo "$exciseMark" >> /root/Cheki/chekes/check.txt
DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool type "$exciseMark"
while true
   do
       enterexciseMark=`tail -n10 /linuxcash/logs/current/terminal.log | grep -c 'documentOpen  - Ввод данных завершен'`
       if [ $enterexciseMark == 1 ]; then
           break
       fi
   done
sed -ri 's/(.*)allowOnlyExternalDiscount.*/\1/' /root/Cheki/chekes/check.img
done

rm /root/Cheki/chekes/check.img
sleep 1
DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key F12
sleep 1
DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key F12

while true
do
checkStatus=`tail -n10 /linuxcash/logs/current/terminal.log | grep -c 'checkprinter  - Чек закрыт успешно'`
	if [ $checkStatus == 1 ]; then
		break
	fi
done

echo "Закрыл чек" 
