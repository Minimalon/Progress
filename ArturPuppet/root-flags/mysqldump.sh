#!/bin/bash

cd /linuxcash/cash/data
totalDumps=10

if ! [ -d ./db-dump ]; then
 mkdir db-dump
fi

if ! [ -d ./db-dump/mysqldump ]; then
  mkdir ./db-dump/mysqldump
  mysqldump dictionaries >> /linuxcash/cash/data/db-dump/mysqldump/`date +%d-%m-%Y`.sql
else
  if [[ `ls ./db-dump/mysqldump | grep -c '.sql'` < $totalDumps ]]; then
   mysqldump dictionaries >> /linuxcash/cash/data/db-dump/mysqldump/`date +%d-%m-%Y`.sql
  else
   rm ./db-dump/mysqldump/`ls -r ./db-dump/mysqldump | grep '.sql' -m1`
   mysqldump dictionaries >> /linuxcash/cash/data/db-dump/mysqldump/`date +%d-%m-%Y`.sql
  fi
fi

