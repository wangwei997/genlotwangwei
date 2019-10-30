#!/bin/sh
GROUP=service_trade
SERVICE=trading-core-service

cd /data/ansible
ansible-playbook -i inventory -f 16 --extra-vars "group=$GROUP service=$SERVICE" playbook/deploy_service.yml
