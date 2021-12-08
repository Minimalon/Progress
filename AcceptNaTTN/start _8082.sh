#!/bin/bash
nowdate=`date +%Y-%m-%d`

cd /root/AcceptNaTTN
rm TTNs.txt

whitelsts=`links -dump http://localhost:8082/opt/out | grep ReplyNATTN | awk {'print $1'}`

links -source $whitelsts | sed "s/> */>\n/g" | grep "TTN-" | awk -F "</ttn:WbRegID>" {'print $1'} > TTNs.txt
allTTNS=(`cat /root/TTNs.txt`)

fsrar=$(curl -X GET http://localhost:8082/diagnosis | grep CN | cut -b 7-18)
sed -e "s/ID_t/$fsrar/g" accepted.xml.prepare >accepted.xml.prepare.1

tempCount=1
echo "1: Accept all TTN"
for count in "${allTTNS[@]}"
do
	tempCount=$((tempCount + 1))
	echo "$tempCount: "$count
done

read -p "Enter line: " line

if [ $line -eq 1 ]
then
for ttn in "${allTTNS[@]}"
do	
      sed -e "s/TTNREGID/$ttn/g" accepted.xml.prepare.1 > accepted.xml.prepare.2
      sed -e "s/nowdate/$nowdate/g" accepted.xml.prepare.2 > accepted.xml
      curl -F "xml_file=@accepted.xml" http://localhost:8082/opt/in/WayBillAct_v4
	  echo \n"-------------------------------"
done
fi
