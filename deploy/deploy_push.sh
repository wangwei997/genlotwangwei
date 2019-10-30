#!/bin/sh
GROUP=push
GATEWAY=push
DEAMON=push_api_daemon.sh
LOG=push_api_daemon.log
STOP=stop_push_api.sh

cd /data/ansible
ansible-playbook -i inventory -f 16 --extra-vars "group=$GROUP gateway=$GATEWAY deamon=$DEAMON log=$LOG stop=$STOP" playbook/deploy_gateway.yml
