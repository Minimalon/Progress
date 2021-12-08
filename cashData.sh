#!/bin/bash

PCduplicate=$(grep -c `uname -n | cut -d '-' -f2,3` /linuxcash/net/server/server/KeyDATA.log)
if [[ $PCduplicate == 0 ]]; then
	a=(`curl -X GET http://localhost:8082/api/info/list | sed -e 's/,/\n/g' | grep "expireDate" | sed -e 's/"/!/g' | cut -d "!" -f4 | sed -e 's/+0300//g'`)
	b=(`curl -X GET http://localhost:18082/api/info/list | sed -e 's/,/\n/g' | grep "expireDate" | sed -e 's/"/!/g' | cut -d "!" -f4 | sed -e 's/+0400//g'`)
	printf "`uname -n | cut -d '-' -f2,3` | ООО: ${a[0]} ${a[1]} ${a[2]} ${a[3]} | ИП: ${b[0]} ${b[1]} ${b[2]} ${b[3]}\n" >> /linuxcash/net/server/server/KeyDATA.log
fi

NaTTNS=`links -dump http://localhost:18082/opt/out | grep ReplyNATTN`
countTTN=`links -source $NaTTNS | sed "s/> */>\n/g" | grep "TTN-" | awk -F "</ttn:WbRegID>" {'print $1'} | grep -c TTN`

PCduplicate=$(grep -c `uname -n | cut -d '-' -f2,3` /linuxcash/net/server/server/NaTTNpivo.txt)
a=`curl -I 127.0.0.1:18082 2>/dev/null | head -n 1 | cut -d$' ' -f2`
if [[ $PCduplicate == 0 ]]; then
	if [[ $a == 200 ]]; then
		countNaTTNS=`links -dump http://localhost:18082/opt/out | grep -c ReplyNATTN`
		if [[ $countNaTTNS == 0 ]]; then
		 /root/curlttns/natttns.sh
		 sleep 600
		fi	
		printf "`uname -n | cut -d '-' -f2,3` | $countTTN \n" >> /linuxcash/net/server/server/NaTTNpivo.txt
	fi
fi