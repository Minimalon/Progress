#!/usr/bin/env bash

cd /root/telegramBarcode

function op_mode {
  otdel="$1"
  if [[ "$otdel" == "1" ]]; then
  op_mode="192"
elif [[ "$otdel" == "2" ]]; then
  op_mode="64"
elif [[ "$otdel" == "3" ]]; then
  op_mode="32768"
elif [[ "$otdel" == "4" ]]; then
  op_mode="0"
else
  printf '\033[0;31m%s\e[m\n' "Данного отдела '$otdel' не существует. Только с 1 по 4"
  exit
fi
}

function main {
  cash=`uname -n`
  while read line
  do
    if [[ `echo $line | cut -d '|' -f1` == $cash  ]]; then
      if [[ `grep -c $line barcodes.txt` == 0 ]]; then
        EAN=`echo $line | cut -d '|' -f2`
        otdel=`echo $line | cut -d '|' -f2`
        name=`echo $line | cut -d '|' -f4`
        op_mode `echo $line | cut -d '|' -f3`
        insert1="INSERT IGNORE INTO tmc (bcode, vatcode1, vatcode2, vatcode3, vatcode4, vatcode5, dcode, name, articul, cquant, measure, pricetype, price, minprice, valcode, quantdefault, quantlimit, ostat, links, quant_mode, bcode_mode, op_mode, dept_mode, price_mode, tara_flag, tara_mode, tara_default, unit_weight, code, aspectschemecode, aspectvaluesetcode, aspectusecase, aspectselectionrule, extendetoptions, groupcode, remain, remaindate, documentquantlimit, age, alcoholpercent, inn, kpp, alctypecode, manufacturercountrycode, paymentobject, loyaltymode, minretailprice) VALUES ('$EAN',301,302,303,304,305,$otdel,'$name','',1.000,2114,0,0.00,0.00,0,1.000,0.000,0,0,15,3,$op_mode,1,1,NULL,NULL,'0',NULL,'$name',NULL,NULL,NULL,NULL,NULL,NULL,0.000,'2021-22-12 22:22:22',2.000,NULL,15.00,NULL,NULL,0,NULL,NULL,0,0.00);"
        insert2="INSERT IGNORE INTO \`barcodes\` (\`code\`, \`barcode\`, \`name\`, \`price\`, \`cquant\`, \`measure\`, \`aspectvaluesetcode\`, \`quantdefault\`, \`packingmeasure\`, \`packingprice\`, \`minprice\`, \`minretailprice\`, \`customsdeclarationnumber\`, \`tmctype\`) VALUES ('$EAN','$EAN','$name',0.00,NULL,2,NULL,1.000,2,NULL,0.00,NULL,NULL,NULL);"

        mysql dictionaries -e "DELETE FROM tmc WHERE bcode = $EAN"
        mysql dictionaries -e "DELETE FROM barcodes WHERE barcode = $EAN"
        mysql dictionaries -e "$insert1"
        mysql dictionaries -e "$insert2"
        echo $line >> barcodes.txt
      fi
    fi
  done < $1
}

main "/linuxcash/net/server/server/telegram_barcode.txt"
