#!/bin/sh
# bet order stat

MYSQL=`which mysql`
MYSQL_OPTIONS="--login-path=<HOST> --default-character-set=utf8"
EXECUTE="$MYSQL $MYSQL_OPTIONS -e"

#
# 这里需要修改，每台分片机上的分库数量
#
DATABASEs=2
#
# 这里需要修改，每台分片机上的分库中的表数量
#
TABLEs=2
SHARDINGs="trade"

for host in ${SHARDINGs}; do
    # 处理一个分片节点
    # host 用于 mysql --login-path 参数
    
    for index in $(seq 0 $(($DATABASEs - 1))); do
        # 分片中的分库名, 这里以订单为例子, 
        # 
        # 这里需要修改，修改 keno_order_ 为想要的库名前缀
        #
        schemaRemote="keno_order_`printf %04d $index`"

        # 创建分库名
        ${EXECUTE/<HOST>/${host}} "CREATE DATABASE IF NOT EXISTS $schemaRemote"

        for i in $(seq 0 $(($TABLEs - 1))); do
            # 每日各个分库的同名表将合并到同一张表中
            # 
            # 这里需要修改，修改 bet_order_ 为想要的表名前缀
            #
            table="bet_order_`printf %04d $i`"

            echo -e "execute SQL in --login-path=%host  $schemaRemote.$table"
            # 
            # 这里需要修改，替换相应的语句即可
            # 
            #${EXECUTE/<HOST>/${host}} "SQL 语句"

        done
    done
done
