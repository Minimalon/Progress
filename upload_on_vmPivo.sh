#!/usr/bin/env bash

if [[ `vboxmanage list runningvms | grep -c Ubuntu` > 0 ]]; then
  # sshpass -p '111' scp -o "StrictHostKeyChecking=no" -P 2222 /root/ArturAuto/rtkStatus.sh  user@localhost:/home/user
  sshpass -p '111' scp -o "StrictHostKeyChecking=no" -P 2222 /root/rtecpinfo.sh  user@localhost:/home/user
  # sshpass -p '111' scp -o "StrictHostKeyChecking=no" -P 2222 /root/ArturAuto/clearcache.sh.sh  user@localhost:/home/user
  # sshpass -p '111' scp -o "StrictHostKeyChecking=no" -P 2222 /etc/cron.d/arturCron  user@localhost:/etc/cron.d
fi
