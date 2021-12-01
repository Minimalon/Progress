cd /home/minimal/ansible/Progress/playbooks/hosts
all=`cat MainHosts.1`
for line in $all
do
 cash=`grep $line allhosts`
 echo $line
 sed -i "s/$line/$cash/g" MainHosts.1
done
cat MainHosts.1
