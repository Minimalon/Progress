cd /home/minimal/ansible/Progress/playbooks
#sed -i "s/.*\[//g" log/vm7.log
#sed -i "s/\].*//g" log/vm7.log
all=`cat log/vm7.log`
rm hosts/vm7

for cash in $all
do
 grep $cash hosts/allhosts >> hosts/vm7
done
echo `cat hosts/vm7 | wc -l` 
