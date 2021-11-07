cp /linuxcash/logs/current/terminal.log /root/doubleTest/terminal.log
touch /root/doubleTest/info.txt

#checkEgaisInfo=`tac /root/doubleTest/double.txt | grep -c '<?xml version="1.0" encoding="utf-8"?>'`
barcode=`sed -n 's/.*<?xml version="1.0" encoding="utf-8"?>/ /p' /root/Cheki/check.img`

echo $checkEgaisInfo >> /root/doubleTest/info.txt

