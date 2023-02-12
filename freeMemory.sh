#!/usr/bin/env bash

if (( $(df -h / | awk '{print $5}' | grep -oE '[0-9].') >= 90 )); then
  rm -rf /var/log/*
  rm -rf /linuxcash/logs/backup /linuxcash/logs/cashlogs /linuxcash/logs/data /linuxcash/logs/defects /linuxcash/logs/utm_xml_backup /linuxcash/logs/lost+found
  logs=$(find /root/ /linuxcash/cash/ /bin/ /home/ /usr/ /opt/ /var -name '*.log')
  rm -rf "$logs"
  days=0
  for log in $(find /linuxcash/logs/archive/logs/ -maxdepth 1 -name '*.zip' | sort -r); do
    if (( days > 30 )); then
      rm /linuxcash/logs/archive/logs/$log
    fi
    days=$((days + 1))
  done
  printf "$(date +"%H:%M %d/%m/%Y")\t$(hostname)\t$(df -h / | awk '{print $5}' | grep -oE '[0-9].')\t$(df -h / | tail -n1 | awk {'print $1'})\n" >> /linuxcash/net/server/server/logs/freeMemory.txt
fi
