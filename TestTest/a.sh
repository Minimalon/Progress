#!/bin/bash
echo "1"
echo "1" >> /root/TestTest/c.txt
n=`tail -n10 /root/TestTest/c.txt | grep -c '1'`

if [ $n == 1]; then
echo "3"
fi