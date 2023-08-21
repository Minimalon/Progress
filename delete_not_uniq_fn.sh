#!/usr/bin/env bash

fns=$(/linuxcash/cash/bin/InfoClient | sed 's/&/\n/g' | grep fn_number= | cut -d= -f2 | sort | uniq -c | awk '{print $1}')
log="/linuxcash/net/server/server/logs/delete_double_fn.log"

for s in $fns; do
 if (( s > 1)); then
    cd /linuxcash/cash/conf/drivers || exit
    rm "hw::AtolFiscalRegister_0.xml" "hw::AtolFiscalRegister_1.xml" "PiritFiscalRegister_0.xml" "PiritFiscalRegister_1.xml" "hw::ShtrihMFiscalRegister_0.xml" "hw::ShtrihMFiscalRegister_0.xml" 2>/dev/null
    pkill artix-gui
    echo "$(date +%Y-%m-%d_%H:%M:%S) $(hostname)" >> "$log"
    exit
 fi
done
