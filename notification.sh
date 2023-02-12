#!/usr/bin/env bash
whitelsts=`links -dump http://localhost:8082/opt/out | grep ReplyNATTN | awk {'print $1'}`
allTTNS=`links -source $whitelsts | sed "s/> */>\n/g" | grep "TTN-" | awk -F "</ttn:WbRegID>" {'print $1'}`
echo $allTTNS
acceptedTTN=`links -dump http://localhost:$port/opt/out | grep Ticket`
for i in $acceptedTTN
do
  checkStatusTTN=`links -source $i |  grep -c 'подтверждена'`
    if (( $checkStatusTTN >= 1)); then
      ttn=`links -source $i |  grep 'подтверждена' | grep '<tc:OperationComment>' | awk {'print $2'}`
      if (( `grep -c $ttn acceptedTTN` == 0 )); then # Если нету ТТН в файле
          echo $ttn >> acceptedTTN
      fi
    fi
done
