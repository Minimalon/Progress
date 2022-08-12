#!/usr/bin/env bash

for amark in `grep -B4 'Товар с такой акцизной маркой' /linuxcash/logs/current/terminal.log | grep Введено | cut -d "'" -f2`; do
  if ! [[ `echo -e "SELECT excisemarkid from dictionaries.excisemarkwhite where excisemarkid = '$amark';" | mysql --skip-column-names` ]]; then
  	if [[ `grep -c $amark dont_find_in_ttnload` > 0  ]]; then
      echo "Не найдено в ttnload $amark"
      continue
    fi
    /root/flags/tehpod_files/6.sh $amark
  	TTN=`grep -r $amark /root/ttnload/TTN/ | cut -d '/' -f5`
  	if [[ $TTN ]]; then
    	 printf "`date +"%H:%M %d/%m/%Y"`\t`uname -n`\t$TTN\t$amark\n" >> /linuxcash/net/server/server/whiteList.log
  	else
  	printf "`date +"%H:%M %d/%m/%Y"`\t`uname -n`\t-\t$amark\n" >> /linuxcash/net/server/server/whiteList.log
  	echo $amark >> dont_find_in_ttnload
  	fi
  fi
done
