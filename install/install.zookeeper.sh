#!/bin/sh
# install zookeeper

## include libs
LIB_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
. $LIB_PATH/libs/util.sh

ZK_VERSION="3.5.5"

force_cd /data
# JDK下载包需要提前准备，建议使用JDK8的版本
cp -r $LIB_PATH/sources/apache-zookeeper-${ZK_VERSION}-bin.tar.gz .
tar xzf apache-zookeeper-${ZK_VERSION}-bin.tar.gz
rm -f apache-zookeeper-${ZK_VERSION}-bin.tar.gz
mv apache-zookeeper-${ZK_VERSION}-bin zookeeper-${ZK_VERSION}

echo "export PATH=\${PATH}:/data/zookeeper-${ZK_VERSION}/bin" >> /etc/profile
source /etc/profile

echo -e "${C_BGreen}install zookeeper ${ZK_VERSION} successfully${C_None}"
