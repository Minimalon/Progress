#!/usr/bin/env bash
function check_error {
    port=$1

    # Наличие ошибок УТМ
    checkError=`curl -X GET http://localhost:$port/home 2>/dev/null | grep -c 'Проблемы с RSA'`
    x=0
    if [ $checkError == 1 ]; then
				printf '\033[0;31m%s\e[m\n' "Проблемы с RSA, перезагрузи компьютер"
				exit
    fi

		#В сети ли УТМы
		b=`curl -X GET http://localhost:$port/home 2>/dev/null | grep -c 'Проблемы с RSA'`
		if [ $b == 1 ]; then
				printf '\033[0;31m%s\e[m\n' "УТМ не работает"
				exit
		fi
}

nowdate=`date +%Y-%m-%d`
cd /root/white420
rm accepted.xml 2>/dev/null && rm accepted.xml.prepare.* 2>/dev/null
rm FORM2REGINFO.txt 2>/dev/null
rm tmp2.txt 2>/dev/null

check_error 18082
fsrar=$(curl -X GET http://localhost:18082/diagnosis 2>/dev/null | grep CN | cut -b 7-18)
sed -e "s/ID_t/$fsrar/g" accepted.xml.prepare > accepted.xml.prepare.1
whitelsts=(`links -dump http://localhost:18082/opt/out | grep WayBill_v4`)
tempCount=1
printf '\033[0;35m1: \e[m\e[1;33m%s\e[m\n' "Принять все накладные"
for count in "${whitelsts[@]}"; do
	tempCount=$((tempCount + 1))
	number=`links -source $count | sed "s/> */>\n/g" | grep "/wb:NUMBER" | sed -e :a -e 's/<[^>]*>//g;/</N;//ba'`
	dateTTN=`links -source $count | sed 's/</\n</g' | grep "<wb:Date>" | awk -F "<|>" {'print $3'} `
	OOO_name=`links -source $count | sed 's/</\n</g' | grep '<oref:ShortName>' | awk -F "<|>" {'print $3'} | head -n1`
	printf '\033[0;35m%s\e[m\e[1;18m\e[m' "$tempCount: "
	printf '\e[1;18m%s\e[m\n' "$number   $OOO_name   $dateTTN"
done
	read -p "Enter TTN number: " line
if [ $line -eq 1 ]; then
	whitelsts=`cat WayBill_v4.txt`
	for line in $whitelsts; do
	  wget $line
	  rm FORM2REGINFO.txt
	  nameFile=`echo $line | awk -F "WayBill_v4" {'print $2'}| cut -d '/' -f2`
	  rm tmp.txt
	  number=`links -source $line | sed "s/> */>\n/g" | grep "/wb:NUMBER" | sed -e :a -e 's/<[^>]*>//g;/</N;//ba'`
	  echo $number
	  rm $nameFile
	  links -dump http://localhost:18082/opt/out | grep  FORM2REGINFO >> FORM2REGINFO.txt
	  regs=`cat FORM2REGINFO.txt | awk {'print $1'}`
	  for reg in $regs; do
	    wget $reg
	    nameregFile=`echo $reg | awk -F "FORM2REGINFO" {'print $2'} | cut -d '/' -f2`
	    cat $nameregFile | grep -A1 "NUMBER"  > tmp2.txt
	    numberreg=`cat tmp2.txt | head -n1 | cut -d '>' -f2 | cut -d '<' -f1 | awk {'print $1'} `
	    if [ "$number" == "$numberreg" ]; then
	      regnum=`cat $nameregFile | grep "wbr:WBRegId" | cut -d '>' -f2 | cut -d '<' -f1`
	      rm $nameregFile
	      sed -e "s/TTNREGID/$regnum/g" accepted.xml.prepare.1 > accepted.xml.prepare.2
	      sed -e "s/nowdate/$nowdate/g" accepted.xml.prepare.2 > accepted.xml
	      curl -F "xml_file=@accepted.xml" http://localhost:18082/opt/in/WayBillAct_v4 2>/dev/null
	      curl -X DELETE $line
	      curl -X DELETE $reg
		  	amark=`cat /root/ttnload/TTN/$regnum/WayBill_v4.xml | grep "<ce:amc>" | cut -d '>' -f2 | cut -d '<' -f1`
				for line in $amark ; do
	      	mysql dictionaries -e "INSERT  IGNORE INTO \`excisemarkwhite\` (\`excisemarkid\`) VALUES ('$line');"
	    	done
				/opt/whitelist/run.sh
	      break
	    fi
	    rm $nameregFile
	  done
	done
else
  rm FORM2REGINFO.txt
	line=$((line - 2))
	wget ${whitelsts[$line]}
	nameFile=`echo ${whitelsts[$line]} | awk -F "WayBill_v4" {'print $2'}| cut -d '/' -f2`
  rm tmp.txt
  number=`links -source ${whitelsts[$line]} | sed "s/> */>\n/g" | grep "/wb:NUMBER" | sed -e :a -e 's/<[^>]*>//g;/</N;//ba'`
  echo $number
  rm $nameFile
  links -dump http://localhost:18082/opt/out | grep  FORM2REGINFO >> FORM2REGINFO.txt
  regs=(`cat FORM2REGINFO.txt | awk {'print $1'}`)
	 for reg in "${regs[@]}"; do
    wget $reg
    nameregFile=`echo $reg | awk -F "FORM2REGINFO" {'print $2'} | cut -d '/' -f2`
    cat $nameregFile | grep -A1 "NUMBER"  > tmp2.txt
    numberreg=`cat tmp2.txt | head -n1 | cut -d '>' -f2 | cut -d '<' -f1 | awk {'print $1'} `
  	if [ "$number" == "$numberreg" ]; then
      regnum=`cat $nameregFile | grep "wbr:WBRegId" | cut -d '>' -f2 | cut -d '<' -f1`
      rm $nameregFile
      sed -e "s/TTNREGID/$regnum/g" accepted.xml.prepare.1 >accepted.xml.prepare.2
      sed -e "s/nowdate/$nowdate/g" accepted.xml.prepare.2 > accepted.xml
      curl -F "xml_file=@accepted.xml" http://localhost:18082/opt/in/WayBillAct_v4 2>/dev/null
      curl -X DELETE ${whitelsts[$line]}
      curl -X DELETE $reg
	  	amark=`cat /root/ttnload/TTN/$regnum/WayBill_v4.xml | grep "<ce:amc>" | cut -d '>' -f2 | cut -d '<' -f1`
			for line in $amark ; do
	      mysql dictionaries -e "INSERT  IGNORE INTO \`excisemarkwhite\` (\`excisemarkid\`) VALUES ('$line');"
	    done      /opt/whitelist/run.sh
			printf '\033[0;32m%s\e[m\n' "Накладная отправлена"
		fi
    rm $nameregFile
	done
fi
DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key Escape
sleep 1
DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key Escape
sleep 1
DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key Escape
