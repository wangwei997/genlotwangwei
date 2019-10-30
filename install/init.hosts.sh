#!/bin/sh
# 规范 hosts 关于 localhost 的配置
# 不规范的 hosts 配置可能引起 InetAddress.getLocalHost().getHostName() 很慢
source /etc/profile
## include libs
LIB_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
. $LIB_PATH/libs/util.sh
HOSTNAME=`hostname`

echo -e "Host Name : ${C_BBlue}${HOSTNAME}${C_None}"
echo -e "================= before ================="
cat /etc/hosts
sed -i "/127\.0\.0\.1\s.*/c127.0.0.1   localhost ${HOSTNAME}" /etc/hosts
sed -i "/::1\s.*/c::1         localhost ${HOSTNAME}" /etc/hosts
echo -e "================= after  ================="
cat /etc/hosts