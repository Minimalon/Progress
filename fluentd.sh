#!/bin/bash


hostNumber=`hostname | cut -d- -f2`
server="/linuxcash/net/server/server"


#Проверка на наличие папки компьютера на сервере
if ! [ -d $server/logs/$hostNumber ]; then
    mkdir $server/logs/$hostNumber
fi

#Проверка на наличие скаченного fluentd и его настройка
if ! [[ `type td-agent` ]]; then
    if ! [ -f /root/td-agent_2.3.1-0_i386.deb ]; then
    wget https://s3.amazonaws.com/packages.treasuredata.com/2/ubuntu/trusty/pool/contrib/t/td-agent/td-agent_2.3.1-0_i386.deb
    fi
    
    dpkg -i td-agent_2.3.1-0_i386.deb

    cd /etc/td-agent/
    rm td-agent.conf
    wget http://10.8.13.150/td-agent.conf
    sed -i 's!%logs_path%!'$server'/logs/'$hostNumber'/terminal.log!g' td-agent.conf
    sed -i 's!set -e!set -e\nexport LANG="en_US.UTF-8"!' /etc/init.d/td-agent
    service td-agent restart

    printf "\n[program:td-agent]\ncommand=/root/flags/fluentdStart.sh\nautostart=true\nautorestart=true\nstderr_logfile=/var/log/td-agent/supervisor-err.log\nstdout_logfile=/var/log/td-agent/supervisor-out.log\nredirect_stderr=true" >> /etc/supervisor/conf.d/transport.conf
    cd /root/flags
    curl -O http://10.8.13.150/fluentdStart.sh
    chmod +x fluentdStart.sh 
    service supervisor restart
fi
# if [[ `service td-agent status` == " * td-agent is not running" ]];then
#     service td-agent start
# fi
# service td-agent restart
