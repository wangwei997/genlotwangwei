#!/bin/sh
# 初始化负载类（Nginx）服务器环境

## 创建初始化目录
mkdir -p /data/resources
cd /data/resources

if [ ! -f "/root/.server_init/init_nginx_finished" ]; then
    ## 初始化服务器
    ### 优化内核参数
    /data/resources/install/optimize.system.tcp.sh
    ### 优化内存调度
    /data/resources/install/install.jemalloc.sh
    ### 安装Nginx
    /data/resources/install/install.nginx.sh

    mkdir -p /root/.server_init
    echo "FINISHED @ `date  +"%F %T.%3N"`" > /root/.server_init/init_nginx_finished

    echo -e "\033[1;32mNginx server initialization succeeded!\033[0m\n"
else
    echo -e "\033[1;32mNginx server has been initialized!\033[0m\n"
fi