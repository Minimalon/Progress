#!/usr/bin/env bash

uniq_barcodes="/linuxcash/net/server/server/logs/EANs/uniq_mark_pivo.txt"
update_sql_file="/linuxcash/cash/data/update-database/scripts/pivo.sql"


echo "Штрихкод: "
read -p  bcode

if ! grep -q $bcode $uniq_barcodes; then
 echo "$bcode" >> $uniq_barcodes
fi

mysql -e "UPDATE  dictionaries.barcodes SET tmctype = 7 WHERE code = '$bcode' LIMIT 1;"
echo "UPDATE dictionaries.barcodes SET tmctype = 7 WHERE code = '$bcode' LIMIT 1;" >> "$update_sql_file"
echo 'Готово'
