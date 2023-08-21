#!/usr/bin/env bash

source crmenv/bin/activate
cd /home/zabbix/crm-django/CRM_django || exit
git pull
cd crm
python manage.py makemigrations && python manage.py migrate
