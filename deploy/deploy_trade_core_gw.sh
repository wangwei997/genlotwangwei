#!/bin/sh
GROUP=gateway
GATEWAY=trading-core-gw

cd /data/ansible
ansible-playbook -i inventory -f 16 --extra-vars "group=$GROUP gateway=$GATEWAY" playbook/deploy_gateway.yml
