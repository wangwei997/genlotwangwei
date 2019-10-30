#!/bin/sh
if [ x"$#" != x"1" ]; then
    echo "usage : reset_yum_repo.sh [ansible inventory group name]"
    exit
fi

GROUP=$1

cd /data/ansible
ansible-playbook -i inventory -f 16 --extra-vars "group=$GROUP" playbook/reset_yum_repo.yml
