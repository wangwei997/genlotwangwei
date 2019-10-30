#!/bin/sh
# install zookeeper

## include libs
LIB_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
. $LIB_PATH/libs/util.sh

ES_VERSION="7.1.1"

force_cd /data
# JDK下载包需要提前准备，建议使用JDK8的版本
cp -r $LIB_PATH/sources/elasticsearch-${ES_VERSION}-linux-x86_64.tar.gz .
tar xzf elasticsearch-${ES_VERSION}-linux-x86_64.tar.gz
rm -f elasticsearch-${ES_VERSION}-linux-x86_64.tar.gz
cd elasticsearch-${ES_VERSION}

# disable swapping
sed -i 's/^vm.swappiness = 0/vm.swappiness = 1/g' /etc/sysctl.conf
sysctl -p

# set JVM options
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
# 设置 heap size 为物理内存的50%
heap_size="`expr $phys_pages \* $page_size \* 50 / 107374182400`"

sed -i "s/^-Xms1g/-Xms${heap_size}g/g" config/jvm.options
sed -i "s/^-Xmx1g/-Xmx${heap_size}g/g" config/jvm.options

# enable G1GC
sed -i 's/# 10-:-XX:-UseConcMarkSweepGC/10-:-XX:-UseConcMarkSweepGC/g' config/jvm.options
sed -i 's/# 10-:-XX:-UseCMSInitiatingOccupancyOnly/10-:-XX:-UseCMSInitiatingOccupancyOnly/g' config/jvm.options
sed -i 's/# 10-:-XX:+UseG1GC/10-:-XX:+UseG1GC/g' config/jvm.options
sed -i 's/# 10-:-XX:InitiatingHeapOccupancyPercent=75/10-:-XX:InitiatingHeapOccupancyPercent=75/g' config/jvm.options

echo "export PATH=\${PATH}:/data/elasticsearch-${ES_VERSION}/bin" >> /etc/profile
source /etc/profile

echo -e "${C_BGreen}install ElasticSearch ${ES_VERSION} successfully${C_None}"
