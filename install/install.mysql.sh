#!/bin/sh
# install MySQL Server
# 1. 安装依赖 install_jemalloc.sh
# 2. 与 nginx 并存时不做其他优化，主要优化目标为 nginx ( optimize.system.nginx.sh )
# 3. 本脚本执行前建议调整初始密码，执行中需要输入一次此密码

## include libs
LIB_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
. $LIB_PATH/libs/util.sh

# 有外网的情况
# yum -y install gcc gcc-c++ gcc-g77 autoconf automake zlib* fiex* libxml* ncurses-devel libmcrypt* libtool-ltdl-devel* make cmake bison lsof expect
# 离线时在optimize.system.nginx|mysql.sh 中已经安装了必须的rpm

if [ $(getent group mysql) ]; then
    echo "group 'mysql' exists"
else
    echo "add group 'mysql'"
    groupadd -r mysql
fi
if id -u mysql > /dev/null 2>&1; then
    echo "user 'mysql' exists";
else
    echo "add user 'mysql'";
    useradd -r -g mysql -c "MySQL server" -s /sbin/nologin mysql
fi

MYSQL_VERSION="mysql-5.7.26"
MYSQL_PORT=23306
# 密码不可包含$符号，否则可能创建login-path失败
MYSQL_PASSWORD="genlot@BJ628"
force_cd /data/temp
# 有外网的情况
# prepare_source_by_wget "${MYSQL_VERSION}.tar.gz" "$MYSQL_VERSION" "https://dev.mysql.com/get/Downloads/MySQL-5.6/${MYSQL_VERSION}.tar.gz"
# https://jaist.dl.sourceforge.net/project/boost/boost/1.59.0/boost_1_59_0.tar.gz
# 离线的情况 >>>
cp $LIB_PATH/sources/${MYSQL_VERSION}.tar.gz .
tar xzf ${MYSQL_VERSION}.tar.gz

cp $LIB_PATH/sources/boost_1_59_0.tar.gz .
tar xzf boost_1_59_0.tar.gz
mv boost_1_59_0 /usr/local/boost_1_59_0
# <<<

cd $MYSQL_VERSION

cmake . \
-DCMAKE_INSTALL_PREFIX=/data/mysql \
-DMYSQL_DATADIR=/data/mysql/data \
-DSYSCONFDIR=/data/mysql/config \
-DWITH_MYISAM_STORAGE_ENGINE=1 \
-DWITH_INNOBASE_STORAGE_ENGINE=1 \
-DWITH_MEMORY_STORAGE_ENGINE=1 \
-DWITH_READLINE=1 \
-DMYSQL_UNIX_ADDR=/tmp/mysql.sock \
-DMYSQL_TCP_PORT=$MYSQL_PORT \
-DENABLED_LOCAL_INFILE=1 \
-DWITH_PARTITION_STORAGE_ENGINE=1 \
-DEXTRA_CHARSETS=all \
-DDEFAULT_CHARSET=utf8 \
-DDEFAULT_COLLATION=utf8_general_ci \
-DCMAKE_EXE_LINKER_FLAGS="-ljemalloc" \
-DWITH_SAFEMALLOC=OFF \
-DWITH_BOOST=/usr/local/boost_1_59_0

make && make install
cd ../

mkdir -p /log/mysql/binlog
mkdir -p /log/mysql/relaylog
mkdir -p /log/mysql/dumplog
mkdir -p /log/mysql/logs
mkdir -p /data/mysql/data
mkdir -p /data/mysql/config
chown -R mysql.mysql /log/mysql
chown -R mysql.mysql /data/mysql

server_id=$( get_inet_ip_decimal)
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
# 设置innodb缓冲池为物理内存的80%
innodb_buffer="`expr $phys_pages \* $page_size \* 80 / 107374182400`G"

cpu_cores=`getconf _NPROCESSORS_ONLN`
if [ -z "$cpu_cores" ]; then
  echo "WARN: cannot determine cpu cores, use default 8"
  cpu_cores=8
fi
threads="`expr $cpu_cores \* 2`"

echo "`date +"[%F %T.%N]"` write /data/mysql/config/my.cnf"
cat > /data/mysql/config/my.cnf << EOF
[client]
port    = $MYSQL_PORT
socket  = /tmp/mysql.sock

[mysqld]
character-set-server = utf8
replicate-ignore-db = mysql
replicate-ignore-db = test
replicate-ignore-db = sys
replicate-ignore-db = information_schema
replicate-ignore-db = performance_schema
user    = mysql
port    = $MYSQL_PORT
socket  = /tmp/mysql.sock
basedir = /data/mysql
datadir = /data/mysql/data
log-error = /log/mysql/logs/mysql_error.log
pid-file = /data/mysql/mysql.pid
open_files_limit = 10240
back_log = 600
max_connections = 2000
max_connect_errors = 6000
table_open_cache = 1024
external-locking = FALSE
max_allowed_packet = 32M
sort_buffer_size = 1M
join_buffer_size = 1M
thread_cache_size = 300
#thread_concurrency = 8
query_cache_size = 512M
query_cache_limit = 2M
query_cache_min_res_unit = 2k
default-storage-engine = MyISAM
thread_stack = 192K
transaction_isolation = READ-COMMITTED
tmp_table_size = 512M
max_heap_table_size = 512M
long_query_time = 3
log-slave-updates
log-bin = /log/mysql/binlog/mysql-bin
binlog_cache_size = 4M
binlog_format = MIXED
max_binlog_cache_size = 8M
max_binlog_size = 1G
relay-log-index = /log/mysql/relaylog/relay-bin
relay-log-info-file = /log/mysql/relaylog/relay-bin
relay-log = /log/mysql/relaylog/relay-bin
expire_logs_days = 14
key_buffer_size = 1G
read_buffer_size = 1M
read_rnd_buffer_size = 16M
bulk_insert_buffer_size = 64M
myisam_sort_buffer_size = 5G
myisam_max_sort_file_size = 20G
myisam_repair_threads = 1
myisam-recover-options = BACKUP

explicit_defaults_for_timestamp=true

interactive_timeout = 28800
wait_timeout = 28800

skip-name-resolve
#master-connect-retry = 10
slave-skip-errors = 1032,1062,126,1114,1146,1048,1396

server-id = $server_id

innodb_buffer_pool_size = $innodb_buffer
innodb_file_per_table = 1
innodb_data_file_path = ibdata1:256M:autoextend
innodb_write_io_threads = 8
innodb_read_io_threads = 8
innodb_thread_concurrency = $threads
innodb_flush_method = O_DIRECT
innodb_flush_log_at_trx_commit = 1
innodb_log_buffer_size = 16M
innodb_log_file_size = 256MB
innodb_log_files_in_group = 3
innodb_max_dirty_pages_pct = 90
innodb_lock_wait_timeout = 120
sync_binlog = 1

slow_query_log = OFF
slow_query_log_file = /log/mysql/logs/slow.log
long_query_time = 10

#lc-messages-dir=/usr/local/mysql/share

[mysqldump]
quick
max_allowed_packet = 32M
EOF

# 5.7
/data/mysql/bin/mysqld --defaults-file=/data/mysql/config/my.cnf --user=mysql --basedir=/data/mysql --datadir=/data/mysql/data --initialize

echo "export PATH=\${PATH}:/data/mysql/bin" >> /etc/profile
source /etc/profile

# start
/data/mysql/bin/mysqld_safe &
# 第一次启动会比较慢
sleep 20

ps aux | grep mysql

TempPassword=`cat /log/mysql/logs/mysql_error.log | grep "A temporary password is generated" | awk -F "root@localhost: " '{print $2}'`
echo -e "`date +"[%F %T.%N]"` ${C_BBlue}A temporary password is generated: ${C_None}$TempPassword"
# clean up user, set password
# DELETE FROM mysql.user WHERE (user = 'root' AND host != 'localhost' AND host != '127.0.0.1') OR user != 'root';
echo "`date +"[%F %T.%N]"` change password & add user 'root'@'%'"
/data/mysql/bin/mysql --host=localhost --user=root --port=$MYSQL_PORT --password="$TempPassword" --connect-expired-password --default-character-set=utf8 -e "
ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';
FLUSH PRIVILEGES;
CREATE USER 'root'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%';
FLUSH PRIVILEGES;"

# create login-path
unbuffer expect -c "
spawn /data/mysql/bin/mysql_config_editor set --login-path=local --host=localhost --port=$MYSQL_PORT --user=root --password
expect -nocase \"Enter password:\" {send \"$MYSQL_PASSWORD\r\"; interact}"

sleep 3

# add service
isSystemdEnable=$(is_centos_version 7)
if [ "$isSystemdEnable" == "true" ]; then
    # create systemd service
    cat > /usr/lib/systemd/system/mysqld.service << EOF
[Unit]
Description=MySQL Community Server
After=network.target
After=syslog.target

[Install]
WantedBy=multi-user.target
Alias=mysql.service

[Service]
User=mysql
Group=mysql

#systemctl status就是根据pid来判断服务的运行状态的
PIDFile=/data/mysql/mysql.pid

# 以root权限来启动程序
PermissionsStartOnly=true

# 设置程序启动前的必要操作。例如初始化相关目录等等
#ExecStartPre=/data/mysql/bin/mysql-systemd-start pre

# 启动服务
ExecStart=/data/mysql/bin/mysqld_safe

# 停止服务
ExecStop=/data/mysql/bin/mysqladmin --login-path=local shutdown

# Don't signal startup success before a ping works
#ExecStartPost=/data/mysql/bin/mysql-systemd-start post

# Give up if ping don't get an answer
TimeoutSec=600

#Restart配置可以在进程被kill掉之后，让systemctl产生新的进程，避免服务挂掉
Restart=always
PrivateTmp=false

LimitNOFILE=65535
LimitNPROC=65535
EOF
    systemctl enable mysqld.service
    systemctl restart mysqld.service
    systemctl status mysqld.service
else
    cp /data/mysql/support-files/mysql.server /etc/init.d/mysqld
    chmod a+x /etc/init.d/mysqld
    chkconfig mysqld on
    service mysqld restart
fi

echo "/data/mysql/bin/mysql --login-path=local --default-character-set=utf8" > /usr/local/bin/my.local.sh
chmod +x /usr/local/bin/my.local.sh

lsof -n | grep jemalloc

# 离线的情况 >>>
rm -rf /data/temp/$MYSQL_VERSION
rm -f /data/temp/${MYSQL_VERSION}.tar.gz
rm -f /data/temp/boost_1_59_0.tar.gz
# <<<

echo -e "${C_BGreen}install $MYSQL_VERSION successfully!${C_None}"