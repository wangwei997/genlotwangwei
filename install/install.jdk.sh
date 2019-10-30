#!/bin/sh
# install java

## include libs
LIB_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
. $LIB_PATH/libs/util.sh

JAVA_PATH="jdk1.8.0_211"
JAVA_VERSION="8u211"

force_cd /data
# JDK下载包需要提前准备，建议使用JDK8的版本
cp -r $LIB_PATH/sources/jdk-${JAVA_VERSION}-linux-x64.tar.gz .
tar xzf jdk-${JAVA_VERSION}-linux-x64.tar.gz
rm -f jdk-${JAVA_VERSION}-linux-x64.tar.gz

echo "export PATH=\${PATH}:/data/${JAVA_PATH}/bin" >> /etc/profile
echo "export CONFIG_ENV=pro" >> /etc/profile
source /etc/profile

echo "PATH=$PATH"
echo "CONFIG_ENV=$CONFIG_ENV"

java -version

echo -e "${C_BGreen}install JDK ${JAVA_VERSION} successfully${C_None}"
