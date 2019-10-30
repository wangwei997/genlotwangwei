#!/bin/sh
# install jemalloc

## include libs
LIB_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
. $LIB_PATH/libs/util.sh

# 有外网的情况
# yum -y install gcc gcc-c++ make bzip2 unzip git lsof wget
# 离线时在optimize.system.nginx|mysql.sh 中已经安装了必须的rpm

force_cd /data/temp
# 有外网的情况
# prepare_source_by_wget "jemalloc-5.2.0.tar.bz2" "jemalloc-5.2.0" "https://github.com/jemalloc/jemalloc/releases/download/5.2.0/jemalloc-5.2.0.tar.bz2"
# 离线的情况 >>>
cp $LIB_PATH/sources/jemalloc-5.2.0.tar.bz2 .
tar xjf jemalloc-5.2.0.tar.bz2
# <<<

cd jemalloc-5.2.0
./configure
make && make install
echo '/usr/local/lib' > /etc/ld.so.conf.d/local.conf
ldconfig

echo "link jemalloc-config to /usr/bin"
ln -s /usr/local/bin/jemalloc-config /usr/bin
echo "link jemalloc.sh to /usr/bin"
ln -s /usr/local/bin/jemalloc.sh /usr/bin
echo "link jeprof to /usr/bin"
ln -s /usr/local/bin/jeprof /usr/bin
echo "add to system environment"
echo "export LD_PRELOAD=\`jemalloc-config --libdir\`/libjemalloc.so.\`jemalloc-config --revision\`" >> /etc/profile

# 离线的情况 >>>
rm -rf /data/temp/jemalloc-5.2.0
rm -f /data/temp/jemalloc-5.2.0.tar.bz2
# <<<

echo -e "${C_BGreen}install jemalloc successfully${C_None}"
echo "if you want to check it, input 'lsof -n | grep jemalloc'"
