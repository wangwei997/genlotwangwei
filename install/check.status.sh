#!/bin/sh
# 检查机器优化情况
source /etc/profile
## include libs
LIB_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
. $LIB_PATH/libs/util.sh

COLOR_S="${C_BGreen}"
COLOR_E="${C_None}"
if [ x"$1" == x"1" ]; then
    COLOR_S=""
    COLOR_E=""
fi

echo -e "${COLOR_S}[ open files ]${COLOR_E}"
echo "ulimit `ulimit -a | grep open | awk '{print $4}'`"
cat /etc/security/limits.conf | grep "^[^#].*" | grep --color=auto nofile
cat /etc/security/limits.conf | grep "^[^#].*" | grep --color=auto nproc
echo ""

echo -e "${COLOR_S}[ ipvsadm status ]${COLOR_E}"
ipvsadm -l | head -n 1
echo ""

echo -e "${COLOR_S}[ ethernet gso gro tso ]${COLOR_E}"
ETHTOOL=`which ethtool`
ETHERNETS=`ip link | awk 'BEGIN{FS=": "} $0 !~ "lo|vir|wl|^[^0-9]"{print $2;getline}'`
for ethernet in $ETHERNETS; do
    echo "===== $ethernet ====="
    $ETHTOOL -k $ethernet | grep --color=auto generic-segmentation-offload
    $ETHTOOL -k $ethernet | grep --color=auto generic-receive-offload
    $ETHTOOL -k $ethernet | grep --color=auto tcp-segmentation-offload
done
echo ""

echo -e "${COLOR_S}[ transparent_hugepage  ]${COLOR_E}"
cat /sys/kernel/mm/transparent_hugepage/enabled
cat /sys/kernel/mm/transparent_hugepage/defrag
echo ""

echo -e "${COLOR_S}[ sysctl ]${COLOR_E}"
sysctl -p > /tmp/sysctl.log
cat /tmp/sysctl.log | grep --color=auto "kernel.shmmax"
cat /tmp/sysctl.log | grep --color=auto "kernel.shmall"
cat /tmp/sysctl.log | grep --color=auto "net.core.default_qdisc"
cat /tmp/sysctl.log | grep --color=auto "net.ipv4.tcp_congestion_control"
rm -f /tmp/sysctl.log
echo ""

echo -e "${COLOR_S}[ java ]${COLOR_E}"
JAVA="`which java 2>/dev/null`"
if [ -f "$JAVA" ]; then
    echo "$JAVA"
    echo ""
else
    echo "no java founded in $PATH"
    echo ""
fi

echo -e "${COLOR_S}[ mysql ]${COLOR_E}"
MYSQL="`which mysql 2>/dev/null`"
if [ -f "$MYSQL" ]; then
    echo "$MYSQL"
    echo ""
else
    echo "no mysql founded in $PATH"
    echo ""
fi

echo -e "${COLOR_S}[ jemalloc ]${COLOR_E}"
lsof -n | grep jemalloc | wc -l
wait $!