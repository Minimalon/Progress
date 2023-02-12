#!/usr/bin/env bash
function check_error {
    port=$1

    # Наличие ошибок УТМ
    checkError=$(curl -X GET http://localhost:"$port"/home 2>/dev/null | grep -c 'Проблемы с RSA')
    x=0
    if [ "$checkError" == 1 ]; then
				printf '\033[0;31m%s\e[m\n' "Проблемы с RSA, перезагрузи компьютер"
				exit
    fi

		#В сети ли УТМ
		b=$(curl -X GET http://localhost:"$port"/home 2>/dev/null | grep -c 'Проблемы с RSA')
		if [ "$b" == 1 ]; then
				printf '\033[0;31m%s\e[m\n' "УТМ не работает"
				exit
		fi
}

nowdate=$(date +%Y-%m-%d)
cd /root/white420 || exit
rm accepted.xml > /dev/null 2>&1 && rm accepted.xml.prepare.* > /dev/null 2>&1
rm FORM2REGINFO.txt > /dev/null 2>&1
rm tmp2.txt > /dev/null 2>&1

check_error 18082
fsrar=$(curl -X GET http://localhost:18082/diagnosis 2>/dev/null | grep CN | cut -b 7-18)
sed -e "s/ID_t/$fsrar/g" accepted.xml.prepare > accepted.xml.prepare.1
whitelsts=($(links -source http://localhost:18082/opt/out | grep WayBill_v4 | awk -F "<|>" {'print $3'}))
tempCount=1
printf '\033[0;35m1: \e[m\e[1;33m%s\e[m\n' "Принять все накладные"
for count in "${whitelsts[@]}"; do
	tempCount=$((tempCount + 1))
	number=$(links -source "$count" | sed "s/> */>\n/g" | grep "/wb:NUMBER" | sed -e :a -e 's/<[^>]*>//g;/</N;//ba')
	dateTTN=$(links -source "$count" | sed 's/</\n</g' | grep "<wb:Date>" | awk -F "<|>" {'print $3'} )
	OOO_name=$(links -source "$count" | sed 's/</\n</g' | grep '<oref:ShortName>' | awk -F "<|>" {'print $3'} | head -n1)
	printf '\033[0;35m%s\e[m\e[1;18m\e[m' "$tempCount: "
	printf '\e[1;18m%s\e[m\n' "$number   $OOO_name   $dateTTN"
done
	read -p "Enter TTN number: " line
if [ "$line" -eq 1 ]; then
	whitelsts=$(links -source http://localhost:18082/opt/out | grep WayBill_v4 | awk -F "<|>" {'print $3'})
	for line in $whitelsts; do
	  wget "$line" 2>/dev/null
	  rm FORM2REGINFO.txt 2>/dev/null
	  nameFile=$(echo "$line" | awk -F "WayBill_v4" {'print $2'}| cut -d '/' -f2)
	  rm tmp.txt 2>/dev/null
	  number=$(links -source "$line" | sed "s/> */>\n/g" | grep "/wb:NUMBER" | sed -e :a -e 's/<[^>]*>//g;/</N;//ba')
		dateTTN=$(links -source "$line" | sed 's/</\n</g' | grep "<wb:Date>" | awk -F "<|>" {'print $3'} )
		OOO_name=$(links -source "$line" | sed 's/</\n</g' | grep '<oref:ShortName>' | awk -F "<|>" {'print $3'} | head -n1)
	  rm "$nameFile" 2>/dev/null
	  links -source http://localhost:18082/opt/out | awk -F "<|>" {'print $3'} | grep  FORM2REGINFO >> FORM2REGINFO.txt
	  regs=$(cat FORM2REGINFO.txt | awk {'print $1'})
	  for reg in $regs; do
	    wget "$reg" 2>/dev/null
	    nameregFile=$(echo "$reg" | awk -F "FORM2REGINFO" {'print $2'} | cut -d '/' -f2)
	    cat "$nameregFile" | grep -A1 "NUMBER"  > tmp2.txt
			friTTN=$(links -source "$reg" | grep "<wbr:WBRegId>" | cut -d '>' -f2 | cut -d '<' -f1)
	    numberreg=$(cat tmp2.txt | head -n1 | cut -d '>' -f2 | cut -d '<' -f1 | awk {'print $1'} )
	    if [ "$number" == "$numberreg" ]; then
	      regnum=$(cat "$nameregFile" | grep "wbr:WBRegId" | cut -d '>' -f2 | cut -d '<' -f1)
	      rm "$nameregFile" 2>/dev/null
	      sed -e "s/TTNREGID/$regnum/g" accepted.xml.prepare.1 > accepted.xml.prepare.2
	      sed -e "s/nowdate/$nowdate/g" accepted.xml.prepare.2 > accepted.xml
	      curl -F "xml_file=@accepted.xml" http://localhost:18082/opt/in/WayBillAct_v4 > /dev/null 2>&1
				printf '\033[0;32m%s\e[m\n' "Накладная отправлена $friTTN $number $OOO_name $dateTTN"
	      curl -X DELETE "$line" > /dev/null 2>&1
	      curl -X DELETE "$reg" > /dev/null 2>&1
		    /root/whiteauto.py $(echo "$friTTN" | cut -d '-' -f2)
	  		nohup /opt/whitelist/run.sh 2>/dev/null &
		  	rm "$nameregFile" 2>/dev/null
	      break
	    fi
	    rm "$nameregFile" 2>/dev/null
	  done
	done
else
  rm FORM2REGINFO.txt 2>/dev/null
	line=$((line - 2))
	wget "${whitelsts[$line]}" 2>/dev/null
	nameFile=$(echo "${whitelsts[$line]}" | awk -F "WayBill_v4" {'print $2'}| cut -d '/' -f2)
  rm tmp.txt 2>/dev/null
	number=$(links -source "${whitelsts[$line]}" | sed "s/> */>\n/g" | grep "/wb:NUMBER" | sed -e :a -e 's/<[^>]*>//g;/</N;//ba')
	dateTTN=$(links -source "${whitelsts[$line]}" | sed 's/</\n</g' | grep "<wb:Date>" | awk -F "<|>" {'print $3'} )
	OOO_name=$(links -source "${whitelsts[$line]}" | sed 's/</\n</g' | grep '<oref:ShortName>' | awk -F "<|>" {'print $3'} | head -n1)
  rm "$nameFile"  2>/dev/null
  links -dump http://localhost:18082/opt/out 2>/dev/null | grep  FORM2REGINFO >> FORM2REGINFO.txt
  regs=($(cat FORM2REGINFO.txt | awk {'print $1'}))
	 for reg in "${regs[@]}"; do
    wget "$reg" 2>/dev/null
    friTTN=$(links -source "$reg" | grep "<wbr:WBRegId>" | cut -d '>' -f2 | cut -d '<' -f1)
		nameregFile=$(echo "$reg" | awk -F "FORM2REGINFO" {'print $2'} | cut -d '/' -f2)
    cat "$nameregFile" | grep -A1 "NUMBER"  > tmp2.txt
    numberreg=$(cat tmp2.txt | head -n1 | cut -d '>' -f2 | cut -d '<' -f1 | awk {'print $1'} )
  	if [ "$number" == "$numberreg" ]; then
      regnum=$(cat "$nameregFile" | grep "wbr:WBRegId" | cut -d '>' -f2 | cut -d '<' -f1)
      rm "$nameregFile"  2>/dev/null
      sed -e "s/TTNREGID/$regnum/g" accepted.xml.prepare.1 >accepted.xml.prepare.2
      sed -e "s/nowdate/$nowdate/g" accepted.xml.prepare.2 > accepted.xml
      curl -F "xml_file=@accepted.xml" http://localhost:18082/opt/in/WayBillAct_v4 > /dev/null 2>&1
      curl -X DELETE "${whitelsts[$line]}" > /dev/null 2>&1
      curl -X DELETE "$reg" > /dev/null 2>&1
			printf '\033[0;32m%s\e[m\n' "Накладная отправлена $friTTN $number $OOO_name $dateTTN"
			/root/whiteauto.py $(echo "$friTTN" | cut -d '-' -f2)
			nohup /opt/whitelist/run.sh 2>/dev/null &
			rm "$nameregFile"  2>/dev/null
			break
	fi
    rm "$nameregFile"  2>/dev/null
	done
fi
DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key Escape
sleep 1
DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key Escape
sleep 1
DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key Escape
