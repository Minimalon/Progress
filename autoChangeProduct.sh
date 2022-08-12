#!/usr/bin/env bash

function tmctype{
  op_mode="$1"
  if [[ $op_mode == "192" ]]; then
    tmctype="1"
  fi
  if [[ $op_mode == "64" ]]; then
    tmctype="0"
  fi
  if [[ $op_mode == "32768" ]]; then
    tmctype="3"
  fi
  if [[ $op_mode == "0" ]]; then
    tmctype="0"
  fi
}


while read line
do
  echo $line > tmptmp.txt
  EAN=`cat tmptmp.txt | cut -d "|" -f1`
  otdel=`cat tmptmp.txt | cut -d '|' -f2`
  op_mode=`cat tmptmp.txt | cut -d '|' -f3`
  name=`cat tmptmp.txt | cut -d "|" -f4`
  insert1="INSERT IGNORE INTO tmc (bcode, vatcode1, vatcode2, vatcode3, vatcode4, vatcode5, dcode, name, articul, cquant, measure, pricetype, price, minprice, valcode, quantdefault, quantlimit, ostat, links, quant_mode, bcode_mode, op_mode, dept_mode, price_mode, tara_flag, tara_mode, tara_default, unit_weight, code, aspectschemecode, aspectvaluesetcode, aspectusecase, aspectselectionrule, extendetoptions, groupcode, remain, remaindate, documentquantlimit, age, alcoholpercent, inn, kpp, alctypecode, manufacturercountrycode, paymentobject, loyaltymode, minretailprice) VALUES ('$EAN',301,302,303,304,305,$otdel,'$name','',1.000,2114,0,0.00,0.00,0,1.000,0.000,0,0,15,3,$op_mode,1,1,NULL,NULL,'0',NULL,'$name',NULL,NULL,NULL,NULL,NULL,NULL,0.000,'2021-22-12 22:22:22',2.000,NULL,15.00,NULL,NULL,0,NULL,NULL,0,0.00);"
  insert2="INSERT IGNORE INTO \`barcodes\` (\`code\`, \`barcode\`, \`name\`, \`price\`, \`cquant\`, \`measure\`, \`aspectvaluesetcode\`, \`quantdefault\`, \`packingmeasure\`, \`packingprice\`, \`minprice\`, \`minretailprice\`, \`customsdeclarationnumber\`, \`tmctype\`) VALUES ('$EAN','$EAN','$name',0.00,NULL,2,NULL,1.000,2,NULL,0.00,NULL,NULL,NULL);"
  mysql dictionaries -e "$insert1"
  mysql dictionaries -e "$insert2"
done < /linuxcash/net/server/server/changeProduct/1.txt

while read line
do
  echo $line > tmptmp.txt
  EAN=`cat tmptmp.txt | cut -d "|" -f1`
  otdel=`cat tmptmp.txt | cut -d '|' -f2`
  op_mode=`cat tmptmp.txt | cut -d '|' -f3`
  mysql dictionaries -e "UPDATE tmc SET dcode = $otdel WHERE bcode = $EAN"
  mysql dictionaries -e "UPDATE tmc SET op_mode = $op_mode WHERE bcode = $EAN"
done < /linuxcash/net/server/server/changeProduct/2.txt

rm tmptmp.txt
