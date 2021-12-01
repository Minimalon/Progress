#!/bin/bash

cd /linuxcash/cash/data
totalDumps=10

if ! [ -d ./db-dump ]; then
 mkdir db-dump
 if ! [ -d ./db-dump/mysqldump ]; then
  mkdir mysqldump
  mysqldump dictionaries >> /linuxcash/cash/data/db-dump/mysqldump/`date +%d-%m-%Y`.sql
 else
  if [[ `ls ./db-dump/mysqldump | grep -c '.sql'` < $totalDumps ]];
   mysqldump dictionaries >> /linuxcash/cash/data/db-dump/mysqldump/`date +%d-%m-%Y`.sql
  else
   rm `ls -r ./db-dump/mysqldump | grep sql -m1`
   mysqldump dictionaries >> /linuxcash/cash/data/db-dump/mysqldump/`date +%d-%m-%Y`.sql
  fi
fi

