#!/bin/sh
# install sysbench

## include libs
LIB_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
. $LIB_PATH/libs/util.sh

# 有外网的情况
# yum -y install make automake libtool pkgconfig libaio-devel git mysql-devel
# mariadb-devel for mariaDB
# postgresql-devel for PostgreSQL
# 离线时在optimize.system.nginx|mysql.sh 中已经安装了必须的rpm

force_cd /data/tools/sysbench
force_cd /data/temp

# 有外网的情况
# prepare_source_by_git "https://github.com/akopytov/sysbench.git" "sysbench"
# 离线的情况 >>>
cp -r $LIB_PATH/sources/sysbench .
# <<<

cd sysbench

./autogen.sh
# Add --with-pgsql to build with PostgreSQL support
./configure --prefix=/data/tools/sysbench
make -j
make install

/data/tools/sysbench/bin/sysbench --version

# 离线的情况 >>>
rm -rf /data/temp/sysbench
# <<<

echo -e "${C_BGreen}install sysbench successfully${C_None}"
