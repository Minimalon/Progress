#!/usr/bin/env bash

if [[ $(curl -I 127.0.0.1:18082 2>/dev/null | head -n 1 | cut -d$' ' -f2) == 200 ]]; then
  ip_org_info=$(curl -X GET "http://localhost:18082/api/gost/orginfo" 2>/dev/null)
  ip_fsrar=$(curl -X GET http://localhost:18082/diagnosis 2>/dev/null | grep CN | cut -b 7-18)
  ip_inn=$(echo "$ip_org_info" | sed 's/,/\n/g' | grep inn | grep -oE '[0-9]+')
  cash_number=$(uname -n | cut -d- -f2)
  backup_start=$(cat /root/ostatki-xls/start.sh)
  backup_config=$(cat /root/ostatki-xls/config.py)
  sed -i 's/:8082/:18082/g' /root/ostatki-xls/config.py
  printf '%s\n%s\n%s' "#!/bin/bash" "cd /root/ostatki-xls" "python3 query_rest.py $ip_fsrar $ip_inn $cash_number" > /root/ostatki-xls/start.sh
  /root/ostatki-xls/start.sh
  echo "$backup_config" > /root/ostatki-xls/config.py
  echo "$backup_start" > /root/ostatki-xls/start.sh
  sed -i 's/:18082/:8082/g' /root/ostatki-xls/config.py
else
  echo "УТМ не работает"
fi
