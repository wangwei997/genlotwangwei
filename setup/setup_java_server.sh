#!/bin/sh
TYPE="java"

cd /data/ansible
ansible-playbook -i inventory -f 16 --extra-vars "type=$TYPE reboot=1" playbook/init_server.yml
