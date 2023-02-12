#!/usr/bin/env bash

exsys=$(cat /root/flags/exchangesystems)
if [[ "$exsys" == "CS" ]]; then
	sleep 1
else
	echo "exit"
	exit
fi

function tmctype {
  otdel="$1"
  if [[ $otdel == "1" ]]; then
    tmctype="1"
  fi
  if [[ $otdel == "2" ]]; then
    tmctype="0"
  fi
  if [[ $otdel == "3" ]]; then
    tmctype="3"
  fi
  if [[ $otdel == "4" ]]; then
    tmctype="0"
  fi
  if [[ $otdel == "5" ]]; then
    tmctype="7"
  fi
  if [[ $otdel == "6" ]]; then
    tmctype="7"
  fi
}
mysqlcheck -o -A
echo '1.txt'
while read line
do
  EAN=$(echo "$line" | cut -d "|" -f1)
  otdel=$(echo "$line" | cut -d '|' -f2)
  op_mode=$(echo "$line" | cut -d '|' -f3)
  name=$(echo "$line" | cut -d "|" -f4)
  tmctype "$otdel"
  insert1="INSERT IGNORE INTO tmc (bcode, vatcode1, vatcode2, vatcode3, vatcode4, vatcode5, dcode, name, articul, cquant, measure, pricetype, price, minprice, valcode, quantdefault, quantlimit, ostat, links, quant_mode, bcode_mode, op_mode, dept_mode, price_mode, tara_flag, tara_mode, tara_default, unit_weight, code, aspectschemecode, aspectvaluesetcode, aspectusecase, aspectselectionrule, extendetoptions, groupcode, remain, remaindate, documentquantlimit, age, alcoholpercent, inn, kpp, alctypecode, manufacturercountrycode, paymentobject, loyaltymode, minretailprice) VALUES ('$EAN',301,302,303,304,305,$otdel,'$name','',1.000,2114,0,0.00,50.00,0,1.000,0.000,0,0,15,3,$op_mode,1,1,NULL,NULL,'0',NULL,'$EAN',NULL,NULL,NULL,NULL,NULL,NULL,0.000,'2021-22-12 22:22:22',2.000,NULL,15.00,NULL,NULL,0,NULL,NULL,0,0.00);"
  insert2="INSERT IGNORE INTO \`barcodes\` (\`code\`, \`barcode\`, \`name\`, \`price\`, \`cquant\`, \`measure\`, \`aspectvaluesetcode\`, \`quantdefault\`, \`packingmeasure\`, \`packingprice\`, \`minprice\`, \`minretailprice\`, \`customsdeclarationnumber\`, \`tmctype\`) VALUES ('$EAN','$EAN','$name',0.00,NULL,2,NULL,1.000,2,NULL,0.00,NULL,NULL,$tmctype);"
  mysql dictionaries -e "$insert1"
  mysql dictionaries -e "$insert2"
  echo "$EAN"
done < /linuxcash/net/server/server/changeProduct/1.txt

echo '2.txt'
while read line
do
  EAN=$(echo "$line" | cut -d "|" -f1)
  otdel=$(echo "$line" | cut -d '|' -f2)
  op_mode=$(echo "$line" | cut -d '|' -f3)
  tmctype "$otdel"
  mysql dictionaries -e "UPDATE tmc SET dcode = $otdel, op_mode = $op_mode WHERE bcode = '$EAN'"
  mysql dictionaries -e "UPDATE barcodes SET tmctype = $tmctype WHERE barcode = '$EAN';"
  echo "$EAN"
done < /linuxcash/net/server/server/changeProduct/2.txt
sleep 15
mysqlcheck --auto-repair -A
