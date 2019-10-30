#!/bin/sh
# install jemalloc

## include libs
LIB_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
. $LIB_PATH/libs/util.sh

isSystemdEnable=$(is_centos_version 7)
if [ "$isSystemdEnable" == "true" ]; then
    if [ -x /etc/init.d/iptables ]; then
        echo "centOS 7 find iptables, stop it"
        systemctl stop iptables
    fi
    yum install -y firewalld
    #firewall-cmd --zone=public --add-service=http --permanent
    #firewall-cmd --zone=public --add-service=https --permanent
    firewall-cmd --zone=public --add-service=mysql --permanent
    # 永久允许白名单访问mysql端口
    #firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="8.8.8.8" service name="mysql" accept' --permanent
    firewall-cmd --reload
    firewall-cmd --zone=public --list-all
else
    iptables -I INPUT 5 -p tcp --dport 80 -j ACCEPT
    iptables -I INPUT 6 -p tcp --dport 443 -j ACCEPT
    service iptables save
fi
