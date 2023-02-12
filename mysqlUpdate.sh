#!/usr/bin/env bash

while read line
do
  mysql dictionaries -e "$line"
done < /linuxcash/net/server/server/All/Artur/repairBarcodes.sql
