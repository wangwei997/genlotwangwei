#!/bin/sh
GROUP=service_user
SERVICE=user-service

cd /data/ansible
ansible-playbook -i inventory -f 16 --extra-vars "group=$GROUP service=$SERVICE" playbook/deploy_service.yml
