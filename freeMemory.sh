#!/usr/bin/env bash

if (( $(df -h / | awk '{print $5}' | grep -oE '[0-9]+') >= 99 )); then
  rm -rf /linuxcash/logs/backup /linuxcash/logs/cashlogs /linuxcash/logs/data /linuxcash/logs/defects /linuxcash/logs/utm_xml_backup /linuxcash/logs/lost+found
  logs=$(find /root/ /linuxcash/cash/ /bin/ /home/ /usr/ /var -name '*.log')
  logss=$(find /root/ /linuxcash/cash/ /bin/ /home/ /usr/ /var /opt -name '*.gz')
  syslogs=$(du -ha /var/log --exclude="supervisor" | sort -h | grep M | sed '$ d' | awk '{print $2}')
  rm -rf "$logs"
  rm -rf "$syslogs"
  rm -rf "$logss"
  find /linuxcash/logs/archive/logs/ -mtime +30 -exec rm -rf {} \;
  printf "$(date +"%H:%M %d/%m/%Y")\t$(hostname)\t$(df -h / | awk '{print $5}' | grep -oE '[0-9].')\t$(df -h / | tail -n1 | awk {'print $1'})\n" >> /linuxcash/net/server/server/logs/freeMemory.txt
fi
