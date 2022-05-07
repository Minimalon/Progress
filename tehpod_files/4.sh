#!/usr/bin/env bash

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

read -p "Штрихкод: " EAN
countEAN=`cat /linuxcash/net/server/server/changeProduct/EAN_database.txt | cut -d '|' -f3 | grep -c $EAN`
if [[ $countEAN > 0 ]]; then
  name=`grep -m1 $EAN /linuxcash/net/server/server/changeProduct/EAN_database.txt | cut -d '|' -f2`
  otdel=`grep -m1 $EAN /linuxcash/net/server/server/changeProduct/EAN_database.txt | cut -d '|' -f1`
  op_mode $otdel
  printf '\033[0;36m%s\e[m\n' "Найден штрихкод в /linuxcash/net/server/server/changeProduct/EAN_database.txt"
  printf '\033[0;36m%s\e[m' "Имя: $name "
  printf '\033[0;36m%s\e[m\n' "Отдел: $otdel"
else
  read -p "Отдел товара: " otdel
  read -p "Название товара: " name

  op_mode $otdel
fi

insert1="INSERT IGNORE INTO tmc (bcode, vatcode1, vatcode2, vatcode3, vatcode4, vatcode5, dcode, name, articul, cquant, measure, pricetype, price, minprice, valcode, quantdefault, quantlimit, ostat, links, quant_mode, bcode_mode, op_mode, dept_mode, price_mode, tara_flag, tara_mode, tara_default, unit_weight, code, aspectschemecode, aspectvaluesetcode, aspectusecase, aspectselectionrule, extendetoptions, groupcode, remain, remaindate, documentquantlimit, age, alcoholpercent, inn, kpp, alctypecode, manufacturercountrycode, paymentobject, loyaltymode, minretailprice) VALUES ('$EAN',301,302,303,304,305,$otdel,'$name','',1.000,2114,0,0.00,0.00,0,1.000,0.000,0,0,15,3,$op_mode,1,1,NULL,NULL,'0',NULL,'$name',NULL,NULL,NULL,NULL,NULL,NULL,0.000,'2021-22-12 22:22:22',2.000,NULL,15.00,NULL,NULL,0,NULL,NULL,0,0.00);"
insert2="INSERT IGNORE INTO \`barcodes\` (\`code\`, \`barcode\`, \`name\`, \`price\`, \`cquant\`, \`measure\`, \`aspectvaluesetcode\`, \`quantdefault\`, \`packingmeasure\`, \`packingprice\`, \`minprice\`, \`minretailprice\`, \`customsdeclarationnumber\`, \`tmctype\`) VALUES ('$EAN','$EAN','$name',0.00,NULL,2,NULL,1.000,2,NULL,0.00,NULL,NULL,NULL);"
mysql dictionaries -e "$insert1"
mysql dictionaries -e "$insert2"
printf '\033[0;32m%s\e[m\n' "Добавлен"

count_EAN=`grep -c $EAN /linuxcash/net/server/server/changeProduct/1.txt`
if [[ $count_EAN == 0 ]]; then
  printf '%s\n' "$EAN|$otdel|$op_mode|$name" >> /linuxcash/net/server/server/changeProduct/1.txt
fi
