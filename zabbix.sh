#!/usr/bin/env bash
zabbix_dir=`grep LogFile /etc/zabbix/zabbix_agentd.conf | cut -d '=' -f2`
if ! [[ -d $zabbix_dir ]]; then
  mkdir /var/log/zabbix-agent
  touch /var/log/zabbix-agent/zabbix_agentd.log
  if ! [[ `pgrep zabbix` ]]; then
    chmod 777 /var/log/zabbix-agent/zabbix_agentd.log
    nohup /usr/sbin/zabbix_agentd -c /etc/zabbix/zabbix_agentd.conf &
  fi
fi
