#!/usr/bin/env bash

for amark in `grep -B4 'Товар с такой акцизной маркой' /linuxcash/logs/current/terminal.log | grep Введено | cut -d "'" -f2`; do
  if [[ ! `echo -e "SELECT excisemarkid from dictionaries.excisemarkwhite where excisemarkid = '$amark';" | mysql --skip-column-names` ]]; then
    /root/flags/tehpod_files/6.sh
  fi
done
