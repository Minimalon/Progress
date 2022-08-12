#!/usr/bin/env bash

if [[ `grep -c 'Смена превысила 24 часа' /linuxcash/logs/current/terminal.log` == 0 ]]; then
  printf "\033[0;31m%s\e[m\n" "Ошибки в текущей смене не найдено"
  exit
fi

echo 'Копирую чек в /root'
cp /linuxcash/cash/data/tmp/check.img /root
sleep_time=1
while true; do
  echo "Пробую выйти в меню $sleep_time раз из 5 раз"
  DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key KP_Enter
  sleep $sleep_time
  DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key Escape
  sleep $sleep_time
  DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key Escape
  sleep $sleep_time
  DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key F4
  sleep $sleep_time
  DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key KP_Enter
  sleep $sleep_time
  DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key Shift+F11
  sleep_time=$((sleep_time + 1))
  if [[ `tail -n20 /linuxcash/logs/current/terminal.log | grep -c 'Активация главного меню'` > 0 ]]; then
    break
  fi
  if [[ $sleep_time == 5 ]]; then
    printf "\033[0;31m%s\e[m\n" "Не получается выйти в меню"
    exit
  fi
done
echo "Вышел в меню"
DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key 8
sleep 1
DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key KP_Enter
sleep 1
DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key KP_Enter

a=0
while true; do
  if [[ $a > 24 ]]; then
    printf "\033[0;31m%s\e[m\n" "Не видно закрытия смены"
    exit
  fi
  sleep 5
  a=$((a + 1))
  echo "Жду закрытия смены 5 секунд $a раз из 24 раз"
  if [[ `tail -n20 /linuxcash/logs/current/terminal.log | grep -c 'Активация главного меню'` > 0 ]]; then
    break
  fi
done
echo 'Смена закрылась'

b=1
while true; do
  if [[ $b > 3 ]]; then
    break
  fi
  DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key 1
  sleep 1
  DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key KP_Enter
  sleep 1
  DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key KP_Enter
  b=$((b + 1))
  echo "Пытаюсь войти в монитор кассира $b раз из 3 раз"
  if [[ `grep -c 'Активация контекста открытого документа' /linuxcash/logs/current/terminal.log` > 0 ]]; then
    break
  fi
done
echo 'Вошел в монитор кассира и пробиваю чек /root/recheck.sh /root/check.img'
/root/recheck.sh /root/check.img
