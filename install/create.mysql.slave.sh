#!/bin/sh
# 构建 mysql salve
## env
source /etc/profile
## shell env
set -o errexit -o pipefail -o noclobber -o nounset
#set -o xtrace
## include libs
LIB_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
. $LIB_PATH/libs/util.sh

! getopt --test > /dev/null
enhanced=${PIPESTATUS[0]}
if [[ ${enhanced} -ne 4 ]]; then
    echo -e '`date  +"%F %T.%3N"` ${C_BRed}'getopt --test' return ${ENHANCED}, no enhanced getopt in this environment.${C_None}'
    exit 1
fi

# check parameters
OPTIONS="h:p:u:"
LONGOPTS="host:,password:,user:,help:,port:"

! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    # then getopt has complained about wrong arguments to stdout
    exit 2
fi
eval set -- "$PARSED"

usage(){
    echo -e "`date  +"%F %T.%3N"` ${C_BBlue}Usage${C_None}: $0 -u <user> -p <passowrd> -h <host> --port <port>"
    echo -e "`date  +"%F %T.%3N"`     [Mandatory]"
    echo -e "`date  +"%F %T.%3N"`     -h|--host     MySQL Host for master server"
    echo -e "`date  +"%F %T.%3N"`     -u|--user     MySQL User name (recommanded: ${C_CGreen}root${C_None}), which can create user and grant permission"
    echo -e "`date  +"%F %T.%3N"`     -p|--password password for user from --user"
    echo -e "`date  +"%F %T.%3N"`     [Optional]"
    echo -e "`date  +"%F %T.%3N"`     --port        MySQL post for master server"
}
# Arguments
# -h|--host     MySQL Host for master server
# -u|--user     MySQL User name (recommanded: root), which can create user and grant permission
# -p|--password password for user from --user
# --port        MySQL post for master server
MASTER_USER=""
MASTER_HOST=""
MASTER_PASSWORD=""
MASTER_PORT=3306
while true; do
    case "$1" in
        -h|--host)
            MASTER_HOST="$2"
            shift 2
            ;;
        -u|--user)
            MASTER_USER="$2"
            shift 2
            ;;
        -p|--password)
            MASTER_PASSWORD="$2"
            shift 2
            ;;
        --port)
            MASTER_PORT="$2"
            shift 2
            ;;
        --help)
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            echo -e "`date  +"%F %T.%3N"` ${C_BRed}unsupported arguments: $1${C_None}"
            exit 3
            ;;
    esac
done

if [ -z "${MASTER_HOST}" ] || [ -z "${MASTER_USER}" ] || [ -z "${MASTER_PASSWORD}" ]; then
    usage
    exit 3
fi

echo -e "`date  +"%F %T.%3N"` ${C_BBlue}master${C_None} host[$MASTER_HOST] path[$MASTER_PATH] user[$MASTER_USER] port[$MASTER_PORT] password.length[${#MASTER_PASSWORD}]"

# MySQL bin
MYSQL_CONFIG=`which mysql_config_editor`
MYSQL=`which mysql`
MYSQL_OPTIONS="--login-path=<HOST> --default-character-set=utf8"
MYSQL_DUMP=`which mysqldump`
MYSQL_DUMP_PATH="/log/mysql/dumplog"
EXECUTE="$MYSQL $MYSQL_OPTIONS -e"
EXECUTE_VALUE="$MYSQL $MYSQL_OPTIONS -sNe"

# fields
SLAVE_PATH="local"
MASTER_PATH="master"

# check current slave status
MASTER=`${EXECUTE_VALUE/<HOST>/${SLAVE_PATH}} "SELECT CONCAT(user_name, '@', host) FROM mysql.slave_master_info"`
if [ x"$MASTER" != x"" ]; then
    echo -e "`date  +"%F %T.%3N"` ${C_BRed}current instance already has a master: $MASTER${C_None}"
    exit 4
fi

# --login-path=master must be exist
MASTER_DBS=`$MYSQL --user=$MASTER_USER --host=$MASTER_HOST --password=$MASTER_PASSWORD --port=$MASTER_PORT -sNe "SELECT schema_name FROM information_schema.schemata WHERE schema_name NOT IN ('mysql','information_schema','performance_schema','test');"`
if [ $? -eq 0 ]; then
    $MYSQL_CONFIG remove --login-path=master
    unbuffer expect -c "
    spawn $MYSQL_CONFIG set --login-path=$MASTER_PATH --host=$MASTER_HOST --port=$MASTER_PORT --user=$MASTER_USER --password
    expect -nocase \"Enter password:\" {send \"$MASTER_PASSWORD\r\"; interact}"

    echo "$MYSQL --login-path=master --default-character-set=utf8" > /usr/local/bin/my.master.sh
    chmod +x /usr/local/bin/my.master.sh
else
    # cannot connect master server from input arguments
    exit 5
fi

# slave@inet-ip
INET_IP=`ip address | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | grep -v '192\.168\.*'`
# >= 5.7.8 mysql.user.user change to char(32), use more meaningful strings
SLAVE_USER="slave_{$INET_IP//\./\_}"
${EXECUTE/<HOST>/${MASTER_PATH}} "
CREATE USER '$SLAVE_USER'@'$INET_IP';
GRANT REPLICATION SLAVE ON *.* TO '$SLAVE_USER'@'$INET_IP' IDENTIFIED BY '$MASTER_PASSWORD';"

# warning same databases in both master ans slave
SLAVE_DBS=`${EXECUTE_VALUE/<HOST>/${SLAVE_PATH}} "SELECT schema_name FROM information_schema.schemata WHERE schema_name NOT IN ('mysql','information_schema','performance_schema','test');"`
COMMON_DBS=`comm -12 <(printf "%s\n" "${MASTER_DBS[@]}" | sort) <(printf "%s\n" "${SLAVE_DBS[@]}" | sort)`
if [ ! -z "$COMMON_DBS" ]; then
    echo -e "`date  +"%F %T.%3N"` ${C_BRed}current instance has same databases with master: $(join , ${COMMON_DBS[@]})${C_None}"
    exit 6
fi

## dump master database
$MASTER_DATAS="$MYSQL_DUMP_PATH/master.all.`date  +"%Y%m%d.%H%M%S.%3N"`.sql"
$MYSQL_DUMP --login-path=$MASTER_PATH --skip-lock-tables --single-transaction --flush-logs --hex-blob --master-data=2 --add-drop-table -B $(join , ${MASTER_DBS[@]}) > $MASTER_DATAS
MASTER_LOG_INFO="`head -n80 $MASTER_DATAS | grep "MASTER_LOG_POS"`"
# FROM: "-- CHANGE MASTER TO MASTER_LOG_FILE='mysql-bin.000052', MASTER_LOG_POS=120;"
# TO  : "MASTER_LOG_FILE='mysql-bin.000052', MASTER_LOG_POS=120;"
MASTER_LOG_INFO="${MASTER_LOG_INFO#*TO }"

## restore data to local MySQL
$MYSQL ${MYSQL_OPTIONS/<HOST>/${SLAVE_PATH}} < $MASTER_DATAS

## set master info
${EXECUTE/<HOST>/${SLAVE_PATH}} "
CHANGE MASTER TO 
MASTER_HOST='$MASTER_HOST',
MASTER_PORT=$MASTER_PORT,
MASTER_USER='$SLAVE_USER',
MASTER_PASSWORD='$MASTER_PASSWORD',
${MASTER_LOG_INFO}
START SLAVE;"

# check slave status
${EXECUTE_VALUE/<HOST>/${SLAVE_PATH}} "SHOW SLAVE STATUS\G" 

# finish
echo -e "`date  +"%F %T.%3N"` ${C_BGreen}current instance has bean slave to master: $MASTER_HOST${C_None}"