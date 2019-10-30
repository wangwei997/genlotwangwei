#!/bin/sh
# 初始化应用类（Java+Zookeeper）服务器环境

## 创建初始化目录
mkdir -p /data/resources
cd /data/resources

if [ ! -f "/root/.server_init/init_java_finished" ]; then
    ## 初始化服务器
    ### 优化内核参数
    /data/resources/install/optimize.system.tcp.sh
    ### 优化内存调度
    /data/resources/install/install.jemalloc.sh
    ### 安装JDK
    /data/resources/install/install.jdk.sh

    mkdir -p /root/.server_init
    echo "FINISHED @ `date  +"%F %T.%3N"`" > /root/.server_init/init_java_finished

    echo -e "\033[1;32mJava server initialization succeeded!\033[0m\n"
else
    echo -e "\033[1;32mJava has been initialized!\033[0m\n"
fi

if [ ! -f "/root/.server_init/init_zookeeper_finished" ]; then
    ### 安装ZK
    /data/resources/install/install.zookeeper.sh

    mkdir -p /root/.server_init
    echo "FINISHED @ `date  +"%F %T.%3N"`" > /root/.server_init/init_zookeeper_finished

    echo -e "\033[1;32mZookeeper server initialization succeeded!\033[0m\n"
else
    echo -e "\033[1;32mZookeeper has been initialized!\033[0m\n"
fi