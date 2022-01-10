addressutm='127.0.0.1:18082'
nowdate=`date +%Y-%m-%d`

cashNumber=`uname -n | cut -d '-' -f2,3`
server="/linuxcash/net/server/server"

cd /root/accept_18082
rm WayBill_v4.txt
rm accepted.xml
rm temp.txt
rm FORM2REGINFO.txt
rm accepted.xml.prepare.1
rm accepted.xml.prepare.2
rm tmp2.txt

fsrar=$(curl -X GET http://localhost:18082/diagnosis | grep CN | cut -b 7-18)
sed -e "s/ID_t/$fsrar/g" accepted.xml.prepare >accepted.xml.prepare.1
links -dump http://$addressutm/opt/out | grep WayBill_v4 > WayBill_v4.txt
whitelsts=`cat WayBill_v4.txt`

a=`curl -I 127.0.0.1:18082 2>/dev/null | head -n 1 | cut -d$' ' -f2`

if [[ $a == 200 ]]; then
	echo "" 
else
	exit
fi

b=`curl -X GET http://localhost:18082/home | grep -c 'Проблемы с RSA'`
if [ $b == 1 ]; then
	shutdown -r now
	exit
fi

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



