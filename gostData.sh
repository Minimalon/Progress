#!/usr/bin/env bash

if [[ `curl -I http://localhost:8082 2>/dev/null | head -n 1 | cut -d$' ' -f2` == 200 ]]; then
  time=`curl -X GET "http://localhost:8082/api/info/list" -H "accept: application/json" | jq '.gost.expireDate' | awk -F '"| ' '{print $2}'`
  if [[ $time > 0  ]]; then
    stamp=`date -d "$time" +%s`
    echo $stamp > /root/flags/unixgost1; chmod 777 /root/flags/unixgost1
  fi
fi

if [[ `curl -I http://localhost:18082 2>/dev/null | head -n 1 | cut -d$' ' -f2` == 200 ]]; then

  time=`curl -X GET "http://localhost:18082/api/info/list" -H "accept: application/json" | jq '.gost.expireDate' | awk -F '"| ' '{print $2}'`
  if [[ $time > 0  ]]; then
    stamp=`date -d "$time" +%s`
    echo $stamp > /root/flags/unixgost2; chmod 777 /root/flags/unixgost2
  fi
fi

echo `grep name /linuxcash/cash/conf/ncash.ini | cut -d '"' -f2` > /root/flags/name
