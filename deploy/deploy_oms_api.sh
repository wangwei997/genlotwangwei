#!/bin/sh
GROUP=oms
WEBAPP=keno_oms
DEAMON=keno_oms_daemon.sh
LOG=keno_oms.log
STOP=stop_keno_oms.sh

cd /data/ansible
ansible-playbook -i inventory -f 16 --extra-vars "group=$GROUP webapp=$WEBAPP deamon=$DEAMON log=$LOG stop=$STOP" playbook/deploy_webapps.yml
