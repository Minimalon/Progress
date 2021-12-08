#!/bin/bash

listDump=(`ls /linuxcash/cash/data/db-dump/mysqldump | grep sql`)

#Проверка наличия папки
if ! [ -d /linuxcash/cash/data/db-dump/mysqldump ]; then
 mkdir /linuxcash/cash/data/db-dump/mysqldump
fi

#Количество дампов в папке
if [[ `ls /linuxcash/cash/data/db-dump/mysqldump | grep -c sql` == 0 ]];then
 echo "Нету созданных дампов"
 sleep 1
 exit
fi

x=0
for line in ${listDump[@]}; do #Вывод логов в консоль
 x=$((x+1))
 echo $x: $line
done

read -p "Enter line: " line

echo "Восстанавливаю дамп:" ${listDump[$line-1]}

mysql dictionaries < /linuxcash/cash/data/db-dump/mysqldump/${listDump[$line-1]}

echo "Дамп восстановлен"
sleep 1
