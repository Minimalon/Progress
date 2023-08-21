#!/usr/bin/env bash

delete_notifi() {
  if [ -f $NOTIFICATION_FILE ]; then
    rm $NOTIFICATION_FILE
  fi
}


kkm=$(/root/kkminfo.sh | grep "ККМ2" -A1)
NOTIFICATION_FILE="/root/notifications/badFFD.txt"



if [[ -n "${kkm}" ]]; then
  if ! echo "$kkm" | grep -Eqi "штрих|заглушка" ; then
    ffd=$(echo "$kkm" | grep "ФФД" | awk '{print $5}')
    if [[ -n "$(echo "$ffd" | grep "1.0")" ]] || [[ -n "$(echo "$ffd" | grep "1.05")" ]]; then
      echo 'Нарушена работа с системой Честный знак' > $NOTIFICATION_FILE
    else
      delete_notifi
    fi
  else
    echo "Заглушка или Штрих"
    delete_notifi
  fi
else
  delete_notifi
fi
