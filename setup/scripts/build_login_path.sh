unbuffer expect -c "spawn /data/mysql/bin/mysql_config_editor set --login-path=main --host=10.0.40.33 --port=23306 --user=root --password expect -nocase \"Enter password:\" {send \"sd-9898w\r\"; interact}"
unbuffer expect -c "spawn /data/mysql/bin/mysql_config_editor set --login-path=sharding01 --host=10.0.40.34 --port=23306 --user=root --password expect -nocase \"Enter password:\" {send \"sd-9898w\r\"; interact}"
unbuffer expect -c "spawn /data/mysql/bin/mysql_config_editor set --login-path=sharding02 --host=10.0.40.35 --port=23306 --user=root --password expect -nocase \"Enter password:\" {send \"sd-9898w\r\"; interact}"
unbuffer expect -c "spawn /data/mysql/bin/mysql_config_editor set --login-path=sharding03 --host=10.0.40.36 --port=23306 --user=root --password expect -nocase \"Enter password:\" {send \"sd-9898w\r\"; interact}"
unbuffer expect -c "spawn /data/mysql/bin/mysql_config_editor set --login-path=sharding04 --host=10.0.40.37 --port=23306 --user=root --password expect -nocase \"Enter password:\" {send \"sd-9898w\r\"; interact}"
unbuffer expect -c "spawn /data/mysql/bin/mysql_config_editor set --login-path=oms --host=10.1.58.32 --port=$MYSQL_PORT --user=root --password expect -nocase \"Enter password:\" {send \"sd-9898w\r\"; interact}"


echo "/data/mysql/bin/mysql --login-path=main --default-character-set=utf8" > /usr/local/bin/my.main.sh
echo "/data/mysql/bin/mysql --login-path=sharding01 --default-character-set=utf8" > /usr/local/bin/my.sharding01.sh
echo "/data/mysql/bin/mysql --login-path=sharding02 --default-character-set=utf8" > /usr/local/bin/my.sharding02.sh
echo "/data/mysql/bin/mysql --login-path=sharding03 --default-character-set=utf8" > /usr/local/bin/my.sharding03.sh
echo "/data/mysql/bin/mysql --login-path=sharding04 --default-character-set=utf8" > /usr/local/bin/my.sharding04.sh
echo "/data/mysql/bin/mysql --login-path=oms --default-character-set=utf8" > /usr/local/bin/my.oms.sh