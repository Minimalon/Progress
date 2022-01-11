addressutm='127.0.0.1:18082'
nowdate=`date +%Y-%m-%d`
cd /root/white420
rm WayBill_v4.txt
rm accepted.xml
rm temp.txt
rm FORM2REGINFO.txt
rm accepted.xml.prepare.1
rm accepted.xml.prepare.2
rm tmp2.txt

a=`curl -I 127.0.0.1:18082 2>/dev/null | head -n 1 | cut -d$' ' -f2`

if [[ $a == 200 ]]; then
	echo "" 
else
	while true 
	do	
		echo "УТМ не загружен, попробуйте немного погодя"
		sleep 1
	done
fi

b=`curl -X GET http://localhost:18082/home | grep -c 'Проблемы с RSA'`
if [ $b == 1 ]; then
	while true 
	do
		echo "Проблемы с RSA, перезагрузи компьютер"
		sleep 1
	done
fi

fsrar=$(curl -X GET http://localhost:18082/diagnosis | grep CN | cut -b 7-18)
sed -e "s/ID_t/$fsrar/g" accepted.xml.prepare >accepted.xml.prepare.1
links -dump http://$addressutm/opt/out | grep WayBill_v4 > WayBill_v4.txt
whitelsts=(`cat WayBill_v4.txt`)
tempCount=1
echo "1: Accept all TTN"
for count in "${whitelsts[@]}"
do
	tempCount=$((tempCount + 1))
    number=`links -source $count | sed "s/> */>\n/g" | grep "/wb:NUMBER" | sed -e :a -e 's/<[^>]*>//g;/</N;//ba'`
	dateTTN=`links -source $count | sed "s/> */>\n/g" | grep "ShippingDate" | awk -F "<wb:ShippingDate>" {'print $1'} | cut -b 1-10`
	echo "$tempCount: "$number " " $dateTTN
done
	printf "***Можно принимать выборочно TTN***\n"
	read -p "Enter TTN number: " line
if [ $line -eq 1 ]
then
whitelsts=`cat WayBill_v4.txt`
for line in $whitelsts
do
  wget $line
  rm FORM2REGINFO.txt
  nameFile=`echo $line | awk -F "WayBill_v4" {'print $2'}| cut -d '/' -f2`
  rm tmp.txt
  number=`links -source $line | sed "s/> */>\n/g" | grep "/wb:NUMBER" | sed -e :a -e 's/<[^>]*>//g;/</N;//ba'`
  echo $number
  rm $nameFile
  links -dump http://$addressutm/opt/out | grep  FORM2REGINFO >> FORM2REGINFO.txt
  regs=`cat FORM2REGINFO.txt | awk {'print $1'}`
  for reg in $regs
  do
    wget $reg
    nameregFile=`echo $reg | awk -F "FORM2REGINFO" {'print $2'} | cut -d '/' -f2`
    cat $nameregFile | grep -A1 "NUMBER"  > tmp2.txt
    numberreg=`cat tmp2.txt | head -n1 | cut -d '>' -f2 | cut -d '<' -f1 | awk {'print $1'} `
    if [ "$number" == "$numberreg" ]; then
      regnum=`cat $nameregFile | grep "wbr:WBRegId" | cut -d '>' -f2 | cut -d '<' -f1`
      rm $nameregFile
      sed -e "s/TTNREGID/$regnum/g" accepted.xml.prepare.1 > accepted.xml.prepare.2
      sed -e "s/nowdate/$nowdate/g" accepted.xml.prepare.2 > accepted.xml
      curl -F "xml_file=@accepted.xml" http://localhost:18082/opt/in/WayBillAct_v4
      curl -X DELETE $line
      curl -X DELETE $reg
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
    links -dump http://$addressutm/opt/out | grep  FORM2REGINFO >> FORM2REGINFO.txt
    regs=(`cat FORM2REGINFO.txt | awk {'print $1'}`)
	  for reg in "${regs[@]}"
	  do
    wget $reg
    nameregFile=`echo $reg | awk -F "FORM2REGINFO" {'print $2'} | cut -d '/' -f2`
    cat $nameregFile | grep -A1 "NUMBER"  > tmp2.txt
    numberreg=`cat tmp2.txt | head -n1 | cut -d '>' -f2 | cut -d '<' -f1 | awk {'print $1'} `
    if [ "$number" == "$numberreg" ]; then
      regnum=`cat $nameregFile | grep "wbr:WBRegId" | cut -d '>' -f2 | cut -d '<' -f1`
      rm $nameregFile
      sed -e "s/TTNREGID/$regnum/g" accepted.xml.prepare.1 >accepted.xml.prepare.2
      sed -e "s/nowdate/$nowdate/g" accepted.xml.prepare.2 > accepted.xml
      curl -F "xml_file=@accepted.xml" http://localhost:18082/opt/in/WayBillAct_v4
      curl -X DELETE ${whitelsts[$line]}
      curl -X DELETE $reg
	  
	  printf "\n--------------------------------------"
	  echo "Накладная принята"
	  echo "--------------------------------------"
	  sleep 2
	  break
	else
			printf "\n--------------------------------------"
			echo "Error: number != numberreg"
			echo "======================================"
	fi
    rm $nameregFile
	done
fi
DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key Escape
sleep 1
DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key Escape
sleep 1
DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key Escape



