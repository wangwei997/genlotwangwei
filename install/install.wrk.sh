#!/bin/sh
# install wrk

## include libs
LIB_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
. $LIB_PATH/libs/util.sh

# 有外网的情况
# yum -y install git
# 离线时在optimize.system.nginx|mysql.sh 中已经安装了必须的rpm

force_cd /data/tools
# 有外网的情况
# prepare_source_by_git "https://github.com/wg/wrk.git" "wrk"
# 离线的情况 >>>
cp -r $LIB_PATH/sources/wrk .
# <<<

cd wrk
make

./wrk -v

echo -e "${C_BGreen}install wrk successfully${C_None}"
