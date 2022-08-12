#!/usr/bin/env bash

inn=`grep inn /linuxcash/cash/conf/ncash.ini | cut -d '"' -f2`
fsrar=`grep fsrarId /linuxcash/cash/conf/ncash.ini.d/egaisttn.ini | head -n1 | cut -d '"' -f2`
pcNumber=`uname -n | cut -d '-' -f2,3`

if [[ `grep -c $pcNumber /linuxcash/net/server/server/info.txt` == 0 ]]; then
  printf "$pcNumber\t$inn\t$fsrar\n" >> /linuxcash/net/server/server/info.txt
fi
