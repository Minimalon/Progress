#!/usr/bin/env bash

if [[ `grep -c ',5;' /linuxcash/cash/conf/ncash.ini.d/ncash_hwfrdepartmappings.ini` == 0 ]]; then
  line=`grep -n '[0-4],[0-4],[0-4]'  /linuxcash/cash/conf/ncash.ini.d/ncash_hwfrdepartmappings.ini | cut -d: -f1`
  sed -i "$line s/;/,5;/" /linuxcash/cash/conf/ncash.ini.d/ncash_hwfrdepartmappings.ini
fi
