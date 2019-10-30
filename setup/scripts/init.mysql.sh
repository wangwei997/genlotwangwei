#!/bin/sh
# 初始化数据类（MySQL）服务器环境

## 创建初始化目录
mkdir -p /data/resources
cd /data/resources

if [ ! -f "/root/.server_init/init_mysql_finished" ]; then
    ## 初始化服务器
    ### 优化内核参数
    /data/resources/install/optimize.system.db.sh
    ### 优化内存调度
    /data/resources/install/install.jemalloc.sh
    ### 安装MySQL
    /data/resources/install/install.mysql.sh

    mkdir -p /root/.server_init
    echo "FINISHED @ `date  +"%F %T.%3N"`" > /root/.server_init/init_mysql_finished

    echo -e "\033[1;32mMySQL server initialization succeeded!\033[0m\n"
else
    echo -e "\033[1;32mMySQL server has been initialized!\033[0m\n"
fi