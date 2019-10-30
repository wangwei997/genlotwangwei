#!/bin/sh
# install MySQL Server
# 1. 安装依赖 install_jemalloc.sh
# 2. 后面部分会安装单机多实例，修改$REDIS_PORTS改变实例数量

## include libs
LIB_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
. $LIB_PATH/libs/util.sh

# 有外网的情况
# yum -y install gcc gcc-c++ gcc-g77 autoconf automake zlib* fiex* libxml* ncurses-devel libmcrypt* libtool-ltdl-devel* make cmake bison lsof expect
# 离线时在optimize.system.nginx|mysql.sh 中已经安装了必须的rpm

REDIS_VERSION="redis-5.0.5"
REDIS_PORTS="27001 27002 27003"
force_cd /data/temp
# 有外网的情况
# prepare_source_by_wget "${REDIS_VERSION}.tar.gz" "$REDIS_VERSION" "http://download.redis.io/releases/${REDIS_VERSION}.tar.gz"
# 离线情况 >>>
cp $LIB_PATH/sources/${REDIS_VERSION}.tar.gz .
tar xzf ${REDIS_VERSION}.tar.gz
# <<<
cd $REDIS_VERSION
make MALLOC=jemalloc PREFIX=/data/redis install

mkdir -p /data/redis/conf
mkdir -p /data/redis/data
mkdir -p /data/redis/logs

cp redis.conf sentinel.conf /data/redis/conf/
sed -i 's/^daemonize no/daemonize yes/g' /data/redis/conf/redis.conf
sed -i 's/^appendonly no/appendonly yes/g' /data/redis/conf/redis.conf

echo -e "${C_BBlue}export /data/redis/bin to PATH${C_None}"
echo "export PATH=\${PATH}:/data/redis/bin" >> /etc/profile
source /etc/profile

INET_IP=`ip address | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | grep -v '192\.168\.*'`
cluster=""
for port in $REDIS_PORTS; do
    REDIS_PORT=${port} \
    REDIS_CONFIG_FILE=/data/redis/conf/redis_${port}.conf \
    REDIS_LOG_FILE=/data/redis/logs/redis_${port}.log \
    REDIS_DATA_DIR=/data/redis/data/redis_${port} \
    REDIS_EXECUTABLE=`command -v redis-server` ./utils/install_server.sh

    sed -i "s/^bind 127.0.0.1/bind $INET_IP 127.0.0.1/g" /data/redis/conf/redis_${port}.conf
    sed -i 's/^appendonly no/appendonly yes/g' /data/redis/conf/redis_${port}.conf
    # 增加cluster配置
    sed -i '/# cluster-enabled yes/acluster-enabled yes' /data/redis/conf/redis_${port}.conf
    sed -i "/# cluster-config-file nodes-6379.conf/acluster-config-file nodes-${port}.conf" /data/redis/conf/redis_${port}.conf
    sed -i '/# cluster-node-timeout 15000/acluster-node-timeout 15000' /data/redis/conf/redis_${port}.conf
    # service 脚本增加环境变量引入，不加会影响jemalloc加载
    sed -i '/#Configurations injected by install_server below\.\.\.\./asource \/etc\/profile' /etc/init.d/redis_${port}
    cluster="$cluster $INET_IP:$port"
done

# 离线的情况 >>>
rm -rf /data/temp/$REDIS_VERSION
rm -f /data/temp/${REDIS_VERSION}.tar.gz
# <<<

echo -e "${C_BGreen}install $REDIS_VERSION successfully!${C_None}"
echo -e "${C_BGreen}Services running on [$REDIS_PORTS]${C_None}"

echo -e "${C_BYellow}如果需要建立cluster, 命令如下：${C_None}"
echo -e "${C_BBlue}redis-cli --cluster create $cluster --cluster-replicas 1${C_None}"

