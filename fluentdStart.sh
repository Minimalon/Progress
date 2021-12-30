#!/bin/bash
    if [[ `service td-agent status` == " * td-agent is not running" ]];then
        service td-agent start
    else
        echo `date +%H:%M:%S` "Tryed start td-agent..." >> /var/log/td-agent/supervisor-out.log
    fi