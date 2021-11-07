addressutm='127.0.0.1:18082'
nowdate=`date +%Y-%m-%d`
cd /root/white_p
rm WayBill_v3.txt
rm accepted.xml
rm temp.txt
rm FORM2REGINFO.txt
rm accepted.xml.prepare.1
rm accepted.xml.prepare.2
rm tmp2.txt
links -dump http://localhost:18082/ | grep FSRAR-RSA > temp.txt
fsrar=$(sed -n 's/   RSA FSRAR-RSA-\(.*\)_E/\1/p' temp.txt)
sed -e "s/ID_t/$fsrar/g" accepted.xml.prepare >accepted.xml.prepare.1
links -dump http://$addressutm/opt/out | grep WayBill_v3 > WayBill_v3.txt
whitelsts=(`cat WayBill_v3.txt`)
tempCount=1
echo "1: Accept all TTN"
for count in "${whitelsts[@]}"
do
	tempCount=$((tempCount + 1))
    number=`links -source $count | sed "s/> */>\n/g" | grep "/wb:NUMBER" | sed -e :a -e 's/<[^>]*>//g;/</N;//ba'`
	echo "$tempCount: "$number
done
	read -p "Enter TTN number: " line
if [ $line -eq 1 ]
then
whitelsts=`cat WayBill_v3.txt`
for line in $whitelsts
do
  wget $line
  rm FORM2REGINFO.txt
  nameFile=`echo $line | awk -F "WayBill_v3" {'print $2'}| cut -d '/' -f2`
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
      curl -F "xml_file=@accepted.xml" http://localhost:18082/opt/in/WayBillAct_v3
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
	nameFile=`echo ${whitelsts[$line]} | awk -F "WayBill_v3" {'print $2'}| cut -d '/' -f2`
    rm tmp.txt
    number=`links -source ${whitelsts[$line]} | sed "s/> */>\n/g" | grep "/wb:NUMBER" | sed -e :a -e 's/<[^>]*>//g;/</N;//ba'`
    echo $number
    rm $nameFile
    links -dump http://$addressutm/opt/out | grep  FORM2REGINFO >> FORM2REGINFO.txt
    regs=(`cat FORM2REGINFO.txt | awk {'print $1'}`)
	x=0
	  for reg in "${regs[@]}"
	  do
    wget ${regs[$x]}
	x=$((x + 1))
    nameregFile=`echo ${regs[$line]} | awk -F "FORM2REGINFO" {'print $2'} | cut -d '/' -f2`
    cat $nameregFile | grep -A1 "NUMBER"  > tmp2.txt
    numberreg=`cat tmp2.txt | head -n1 | cut -d '>' -f2 | cut -d '<' -f1 | awk {'print $1'} `
    if [ "$number" == "$numberreg" ]; then
      regnum=`cat $nameregFile | grep "wbr:WBRegId" | cut -d '>' -f2 | cut -d '<' -f1`
      rm $nameregFile
      sed -e "s/TTNREGID/$regnum/g" accepted.xml.prepare.1 >accepted.xml.prepare.2
      sed -e "s/nowdate/$nowdate/g" accepted.xml.prepare.2 > accepted.xml
      curl -F "xml_file=@accepted.xml" http://localhost:18082/opt/in/WayBillAct_v3
      curl -X DELETE ${whitelsts[$line]}
      curl -X DELETE ${regs[$x]}
	else
	echo "======================================"
	echo "Error: number != numberreg"
	fi
    rm $nameregFile
	done
fi


