#!/bin/sh
# optimize system
# 不可与 optimize.system.mysql.sh 同时执行

## include libs
LIB_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
. $LIB_PATH/libs/util.sh

# 有外网的情况
# yum -y install ipvsadm
# 无外网的情况 >>>
rpm -Uvh $LIB_PATH/rpms/*.rpm --nodeps --force
# <<<

# ulimit 参数 1024*1024
ulimit -n 1048576
echo "1. open files & file descriptor limit > 1048576"
echo "ulimit -n 1048576" >> /etc/profile
echo "* soft nofile 1048576" >> /etc/security/limits.conf
echo "* hard nofile 1048576" >> /etc/security/limits.conf
echo "* soft nproc 65535" >> /etc/security/limits.conf
echo "* hard nproc 65535" >> /etc/security/limits.conf

# ip_vs 参数
echo "2. ip_vs conn_tab_bits=20"
echo "options ip_vs conn_tab_bits=20" >> /etc/modprobe.d/ip_vs.conf
modprobe -r ip_vs
modprobe ip_vs
ipvsadm -l

# 网卡参数
echo "3. ethernet close gso gro tso"
ETHTOOL=`which ethtool`
ETHERNETS=`ip link | awk 'BEGIN{FS=": "} $0 !~ "lo|vir|wl|^[^0-9]"{print $2;getline}'`
for ethernet in $ETHERNETS; do
    $ETHTOOL -K $ethernet gso off
    $ETHTOOL -K $ethernet gro off
    $ETHTOOL -K $ethernet tso off

    cat >> /etc/rc.local << EOF
$ETHTOOL -K $ethernet gso off
$ETHTOOL -K $ethernet gro off
$ETHTOOL -K $ethernet tso off
EOF
done

# 内核启动参数
echo "4. kernel transparent_hugepage"
cat >> /etc/rc.local << EOF

if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
   echo never > /sys/kernel/mm/transparent_hugepage/enabled
fi
if test -f /sys/kernel/mm/transparent_hugepage/defrag; then
   echo never > /sys/kernel/mm/transparent_hugepage/defrag
fi

EOF

chmod +x /etc/rc.d/rc.local

echo "/sys/kernel/mm/transparent_hugepage/enabled [never]"
echo never > /sys/kernel/mm/transparent_hugepage/enabled
cat /sys/kernel/mm/transparent_hugepage/enabled
echo "/sys/kernel/mm/transparent_hugepage/defrag [never]"
echo never > /sys/kernel/mm/transparent_hugepage/defrag
cat /sys/kernel/mm/transparent_hugepage/defrag

# 内核sysctl参数
echo "5. kernel sysctl"

page_size=`getconf PAGE_SIZE`
phys_pages=`getconf _PHYS_PAGES`
if [ -z "$page_size" ]; then
  echo "WARN: cannot determine page size, use default 4096"
  page_size=4096
fi

if [ -z "$phys_pages" ]; then
  echo "WARN: cannot determine number of memory pages, use default 16777216(64GB)"
  phys_pages=16777216
fi

shmall=$phys_pages
shmmax=`expr $shmall \* $page_size`
echo "    shamll:$shmall shmmax:$shmmax"

cat > /etc/sysctl.conf << EOF
## NAT,GATEWAY:1
#禁用包过滤功能
## net.ipv4.ip_forward = 0
## net.ipv4.ip_forward = 1
## NAT,GATEWAY:0
## net.ipv4.tcp_tw_recycle = 0
## net.ipv4.tcp_tw_recycle = 1

fs.aio-max-nr = 16777216
fs.file-max   = 16777216
fs.nr_open    = 16777216
kernel.core_pipe_limit = 0
#控制core文件的文件名是否添加pid作为扩展
kernel.core_uses_pid = 1
# CentOS7/RHEL7:Exec-shield is no longer an option in sysctl for kernel tuning.
#kernel.exec-shield = 1
kernel.randomize_va_space = 1
#整个系统最大消息队列数量限制
kernel.msgmax = 65536
#每个消息队列的大小（单位：字节）限制
kernel.msgmnb = 65536
kernel.sem = 250 32000 100 128
#最大共享内存（单位：字节）限制，计算公式64G 64*1024*1024*1024(字节)
kernel.shmmax = $shmmax
#可分配共享内存的长度（单位：页，1页 = 4096）
#SHMMAX/PAGE_SIZE（4096）计算公式64G 64*1024*1024*1024/4096 (页)
kernel.shmall = $shmall
#使用sysrq组合键是了解系统目前运行情况，为安全起见设为0关闭
kernel.sysrq = 0
kernel.unknown_nmi_panic = 0
kernel.pid_max = 4194303
kernel.printk_ratelimit = 30
kernel.printk_ratelimit_burst = 200
net.bridge.bridge-nf-call-arptables = 0
net.bridge.bridge-nf-call-ip6tables = 0
net.bridge.bridge-nf-call-iptables = 0
#每个网络接口接收数据包的速率比内核处理这些包的速率快时，允许送到队列的数据包的最大数目
net.core.netdev_max_backlog = 524288
#系统中每一个端口最大的监听队列的长度，这是个全局的参数
#web应用中listen函数的backlog默认会给我们内核参数的net.core.somaxconn限制到128，而nginx定义的NGX_LISTEN_BACKLOG默认为511，所以有必要调整这个值
net.core.somaxconn = 524288
#禁用所有IP源路由
net.ipv4.conf.default.accept_source_route = 0
#启用源路由核查功能
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.all.arp_announce = 2
net.ipv4.conf.all.arp_notify = 1
net.ipv4.conf.all.arp_ignore = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.default.arp_announce = 2
#net.ipv4.conf.eth0.accept_source_route = 0
net.ipv4.conf.lo.accept_source_route = 0
net.ipv4.conf.lo.arp_announce = 2
net.ipv4.neigh.default.gc_stale_time = 120
#如果套接字由本端要求关闭，这个参数决定了它保持在FIN-WAIT-2状态的时间。
net.ipv4.tcp_fin_timeout = 15
#表示当keepalive起用的时候，TCP发送keepalive消息的频度（单位：秒）
net.ipv4.tcp_keepalive_time = 30
#系统中最多有多少个TCP套接字不被关联到任何一个用户文件句柄上。
#这个限制仅仅是为了防止简单的DoS攻击，不能过分依靠它或者人为地减小这个值，更应该增加这个值(如果增加了内存之后)
net.ipv4.tcp_max_orphans = 3276800
#记录的那些尚未收到客户端确认信息的连接请求的最大值。对于有128M内存的系统而言，缺省值是1024，小内存的系统则是128
net.ipv4.tcp_max_syn_backlog = 262144
#timewait的数量，默认是180000
net.ipv4.tcp_max_tw_buckets = 16777216
#min, pressure, max(单位：内存页)
#这个不需要特别配置，系统会自动根据物理内存页计算
#系统计算值为 38% 50% 75%
#net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_no_metrics_save = 1
#开启有选择的应答
net.ipv4.tcp_sack = 1
net.ipv4.tcp_slow_start_after_idle = 1
#为了打开对端的连接，内核需要发送一个SYN并附带一个回应前面一个SYN的ACK。也就是所谓三次握手中的第二次握手。这个设置决定了内核放弃连接之前发送SYN+ACK包的数量
net.ipv4.tcp_synack_retries = 2
#在内核放弃建立连接之前发送SYN包的数量
net.ipv4.tcp_syn_retries = 2
#TCP时间戳（会在TCP包头增加12个字节），以一种比重发超时更精确的方法（参考RFC 1323）来启用对RTT 的计算，为实现更好的性能应该启用这个选项。
net.ipv4.tcp_timestamps = 1
#开启TCP连接复用功能，允许将time_wait sockets重新用于新的TCP连接（主要针对time_wait连接）
net.ipv4.tcp_tw_reuse = 1
#开启TCP连接中time_wait sockets的快速回收
#Linux 从4.12内核版本开始移除了 tcp_tw_recycle 配置。
#net.ipv4.tcp_tw_recycle = 1
#支持更大的TCP窗口. 如果TCP窗口最大超过65535(64K), 必须设置该数值为1
net.ipv4.tcp_window_scaling = 1
#TCP读buffer
net.ipv4.tcp_rmem = 4096 131072 4194304
#为TCP socket预留用于接收缓冲的内存默认值（单位：字节）
net.core.rmem_default = 8388608
#为TCP socket预留用于接收缓冲的内存最大值（单位：字节）
net.core.rmem_max = 16777216
#TCP写buffer
net.ipv4.tcp_wmem = 4096 131072 4194304
#为TCP socket预留用于发送缓冲的内存默认值（单位：字节）
net.core.wmem_default = 8388608
#为TCP socket预留用于发送缓冲的内存最大值（单位：字节）
net.core.wmem_max = 16777216
net.nf_conntrack_max = 25000000
net.netfilter.nf_conntrack_max=25000000
net.netfilter.nf_conntrack_generic_timeout = 120
net.netfilter.nf_conntrack_tcp_timeout_close = 10
net.netfilter.nf_conntrack_tcp_timeout_close_wait = 60
net.netfilter.nf_conntrack_tcp_timeout_established = 180
net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 120
net.netfilter.nf_conntrack_tcp_timeout_last_ack = 30
net.netfilter.nf_conntrack_tcp_timeout_max_retrans = 300
net.netfilter.nf_conntrack_tcp_timeout_syn_recv = 60
net.netfilter.nf_conntrack_tcp_timeout_syn_sent = 120
net.netfilter.nf_conntrack_tcp_timeout_time_wait = 120
net.netfilter.nf_conntrack_tcp_timeout_unacknowledged = 300
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.neigh.default.gc_thresh1 = 2048
net.ipv4.neigh.default.gc_thresh2 = 4096
net.ipv4.neigh.default.gc_thresh3 = 8192
vm.overcommit_memory=1
vm.swappiness = 0
###vm.min_free_kbytes=65536
net.ipv4.tcp_fastopen = 3
#对外连接端口范围
net.ipv4.ip_local_port_range = 2048 65535
#端口预留，防止被TCP占用，业务端口填写，单个端口','分隔，端口段'-'分隔
# net.ipv4.ip_local_reserved_ports = 10050,11215,18000-18099,27017,60000-60099
vm.max_map_count=262144
# recommended for hosts with jumbo frames enabled
#net.ipv4.tcp_mtu_probing=1
fs.inotify.max_user_watches = 30000000
net.ipv6.conf.all.disable_ipv6 = 1
#bbr
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF

iptables -L -t nat
modprobe br_netfilter

# 有互联网的情况
# force_cd /data/temp/bbr
# wget --no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh
# chmod +x bbr.sh
# ./bbr.sh
# 无互联网的情况 
# RHEL 7 / CentOS 7 升级内核 >>>
rpm --import $LIB_PATH/elrepo/RPM-GPG-KEY-elrepo.org
rpm -Uvh $LIB_PATH/elrepo/elrepo-release-7.0-3.el7.elrepo.noarch.rpm

[ ! "$(command -v yum-config-manager)" ] && rpm -Uvh $LIB_PATH/yum/*.rpm --nodeps --force > /dev/null 2>&1
[ x"$(yum-config-manager elrepo-kernel | grep -w enabled | awk '{print $3}')" != x"True" ] && yum-config-manager --enable elrepo-kernel > /dev/null 2>&1

rpm -Uvh $LIB_PATH/kernel/*.rpm --nodeps --force

grub2-set-default 0

sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
echo "net.core.default_qdisc = fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf

#reboot
# <<<
