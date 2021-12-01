#!/bin/bash
#installOva=`vboxmanage list vms | grep '"7"' | wc -l`
#downloadOva=`ls | grep -c 7.ova`
#if [[ $installOva == 0 ]]; then
# if [[ $downloadOva > 0 ]]; then
#  vboxmanage import 7.ova
# else
#  printf "`uname -n`\n" >> /linuxcash/net/server/server/vm7.txt
# fi
#fi
wget http://194.87.110.186/7.ova
vboxmanage import 7.ova
