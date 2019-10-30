#!/bin/sh
TYPE="redis"

cd /data/ansible
ansible-playbook -i inventory -f 16 --extra-vars "type=$TYPE" playbook/init_server.yml
