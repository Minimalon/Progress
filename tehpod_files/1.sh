#!/usr/bin/env bash

function hours24 {
  while true; do
    while true; do
      if (( `tail /linuxcash/logs/current/terminal.log | grep -c "Диалог выбор: Вы действительно хотите сторнировать весь чек?, ОК, Отмена"` >= 1 )); then
        DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key KP_Enter
        printf '\e[1;18m%s\e[m\n' "Подтвердил сторнирование чека"
        break
      fi
      if (( `tail /linuxcash/logs/current/terminal.log | grep -c "Сторнирование всех позиций в документе завершено"` >= 1 )); then
        printf '\e[1;18m%s\e[m\n' "Сторнировал чек"
        DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key Shift+F11
        break
      fi
      if (( `tail /linuxcash/logs/current/terminal.log | grep -c "Активация главного меню"` >= 1 )); then
        printf '\e[1;18m%s\e[m\n' "Вышел в меню"
        DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key 8
        sleep 1
        DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key KP_Enter
        break
      fi
      if (( `tail /linuxcash/logs/current/terminal.log | grep -c "Диалог выбор: Вы действительно хотите закрыть смену?, ОК, Отмена"` >= 1 )); then
        DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key KP_Enter
        sleep 1
        DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key KP_Enter
        printf '\e[1;18m%s\e[m\n' "Закрываю смену"
        break
      fi
      if (( `tail /linuxcash/logs/current/terminal.log | grep -c "Печать документа ККМ выполнена успешно"` >= 1 )); then
        printf '\033[0;32m%s\e[m\n' "Смена закрыта"
        sleep 1
        DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key 8
        sleep 1
        DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key KP_Enter
        if (( -f /linuxcash/cash/data/tmp/check.img )); then
          printf '\033[0;31m%s\e[m\n' "Есть действующий чек. Дальше руками. Чек находится в /root/check.img"
        else
          /root/recheck.sh /root/check.img
          exit
        fi
        break
      fi
    done
  done
}

mkdir -p /root/backup_tehpod/1
cp /linuxcash/cash/data/tmp/check.img /root/backup_tehpod/1/`date +"%d-%m(%H:%M)"`.img
cp /linuxcash/cash/data/tmp/check.img /root/check.img
DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key KP_Enter
DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key Escape
DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key Escape
DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key F4
hours24
