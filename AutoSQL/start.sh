#!/bin/bash

cp -R /root/ttnload/ /root/AutoSQL/
cd /root/AutoSQL/


listTTN=(`ls -r /root/AutoSQL/ttnload/TTN`)
for line in ${listTTN[@]}
do
	if ! [ -f /root/AutoSQL/ttnload/TTN/$line/InsertSQL ]; then
		
		cd /root/AutoSQL/ttnload/TTN/$line
		
		sed -i "s/< */<\n/g" WayBill_v4.xml
		grep  'pref:FullName>' WayBill_v4.xml | cut -d '<' -f1 | cut -d '>' -f2 | sed '/^$/d'  > bottleName
		grep  'wb:EAN13>' WayBill_v4.xml | cut -d '<' -f1 | cut -d '>' -f2 | sed '/^$/d' > bottleEAN
		grep  'pref:Capacity>' WayBill_v4.xml | cut -d '<' -f1 | cut -d '>' -f2 | sed '/^$/d'  > bottleCapacity
		grep  'wb:Price>' WayBill_v4.xml | cut -d '<' -f1 | cut -d '>' -f2 | sed '/^$/d' | cut -d '.' -f1  > bottlePrice

		bottleCount=$(cat bottleName | wc -l)

		readarray bottleName < bottleName
		readarray bottleEAN < bottleEAN
		readarray bottleCapacity < bottleCapacity
		readarray bottlePrice < bottlePrice
				
		for ((i = 0; i < $bottleCount; i++))
		do
			bottlePrice=$((${bottlePrice[$i]} + 1))
			bottleEAN=$((${bottleEAN[$i]} + 0))

			insert1="INSERT IGNORE INTO tmc (bcode, vatcode1, vatcode2, vatcode3, vatcode4, vatcode5, dcode, name, articul, cquant, measure, pricetype, price, minprice, valcode, quantdefault, quantlimit, ostat, links, quant_mode, bcode_mode, op_mode, dept_mode, price_mode, tara_flag, tara_mode, tara_default, unit_weight, code, aspectschemecode, aspectvaluesetcode, aspectusecase, aspectselectionrule, extendetoptions, groupcode, remain, remaindate, documentquantlimit, age, alcoholpercent, inn, kpp, alctypecode, manufacturercountrycode, paymentobject, loyaltymode, minretailprice) VALUES ('$bottleEAN',301,302,303,304,305,1,'${bottleName[$i]} ${bottleCapacity[$i]}мл','',1.000,2114,0,0.00,$bottlePrice.00,0,1.000,0.000,0,0,15,3,192,1,1,NULL,NULL,'0',NULL,'${bottleName[$i]} ${bottleCapacity[$i]}мл',NULL,NULL,NULL,NULL,NULL,NULL,0.000,'2021-22-12 22:22:22',2.000,NULL,15.00,NULL,NULL,0,NULL,NULL,0,0.00);"
			insert2="INSERT IGNORE INTO \`barcodes\` (\`code\`, \`barcode\`, \`name\`, \`price\`, \`cquant\`, \`measure\`, \`aspectvaluesetcode\`, \`quantdefault\`, \`packingmeasure\`, \`packingprice\`, \`minprice\`, \`minretailprice\`, \`customsdeclarationnumber\`, \`tmctype\`) VALUES ('$bottleEAN','$bottleEAN','${bottleName[$i]} ${bottleCapacity[$i]}л',0.00,NULL,2,NULL,1.000,2,NULL,0.00,NULL,NULL,NULL);"

			mysql dictionaries -e "$insert1"
			mysql dictionaries -e "$insert2"
			
			mysql dictionaries -e "DELETE FROM barcodes where barcode = ' ';"
			mysql dictionaries -e "DELETE FROM barcodes where barcode = '';"
			mysql dictionaries -e "DELETE FROM tmc where bcode = ' ';"
			mysql dictionaries -e "DELETE FROM tmc where bcode = '';"
		done
		touch InsertSQL
		cd /root/AutoSQL/
	else
	echo "/root/ttnload/TTN/$line ---> Уже добавлял"
fi
done
