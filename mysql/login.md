```sh
mysql -u king -p king123 -h localhost -P 3306 shop
```

```sql
select @@version;
select @@datadir;
show databases;
use shop;
show tables;
select * from User;
```

MySQL5.7 默认文件

- 重做日志文件：ib_logfile0、ib_logfile1
- auto.cnf 数据复制时使用 server-uuid 标识唯一的 MySQL 实例
- *.pem 文件：SSL 证书文件
- performance_schema 目录：性能模式相关文件
- ibtmp1：临时文件
- ibdata1：InnoDB 系统表空间文件，存储数据字典、双写缓冲、插入缓冲等信息
- mysql.sock: MySQL 本地连接使用的套接字文件
- mysql 子目录：系统数据库，存储用户权限等信息

MySQL 8 默认文件

- undo 目录：存储回滚段文件
- .dblwr 文件：双写缓冲文件
- mysql.idb 文件：系统表空间文件

```sql
select * from performance_schema.users;
select user, host, total_connections as cxns from performance_schema.accounts order by cxns desc;
```

## Docker 启动 MySQL

CentOS 7 安装Docker

```sh
yum install -y docker
yum install yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install docker-ce docker-ce-cli containerd.io -y
systemctl start docker
systemctl enable --now docker
systemctl status docker
docker version
docker info
```

```sh
docker run --name mysql -e MYSQL_ROOT_HOST=% -e MYSQL_ROOT_PASSWORD=king6289 -e MYSQL_DATABASE=shop -e MYSQL_USER=king -e MYSQL_PASSWORD=king123 -p 3306:3306 -v /mydata/mysql:/var/lib/mysql -d mysql:5.7 --character-set-server=utf8mb4 --collation-server=utf8mb4_general_ci --default-authentication-plugin=mysql_native_password

# --innodb_buffer_pool_size=256M 缓冲池大小
# --innodb_flush_method=O_DIRECT 避免双重缓存
# --innodb_log_file_size=64M

docker exec -it mysql mysql -u king -p king123 shop
docker exec -it mysql bash

docker stop mysql
docker start mysql
docker restart mysql
docker logs mysql
docker rm -f mysql
```

```sh
docker run --name mariadb -e MYSQL_ROOT_PASSWORD=king6289 -e MYSQL_DATABASE=shop -e MYSQL_USER=king -e MYSQL_PASSWORD=king123 -p 3307:3306 -v /mydata/mariadb:/var/lib/mysql -d mariadb:10.5 --character-set-server=utf8mb4 --collation-server=utf8mb4_general_ci
```

```sh
docker run --name percona -e MYSQL_ROOT_PASSWORD=king6289 -e MYSQL_DATABASE=shop -e MYSQL_USER=king -e MYSQL_PASSWORD=king123 -p 3308:3306 -p 3360:33060 -v /mydata/percona:/var/lib/mysql -d percona/percona-server:latest --innodb-buffer-pool-size=256M --innodb_flush_method=O_DIRECT
```

## DBdeployer

```sh
wget https://github.com/datacharmer/DBdeployer/releases/latest/download/dbdeployer-*.tar.gz
tar -xvf dbdeployer-*.tar.gz
sudo mv dbdeployer /usr/local/bin
dbdeployer --version
dbdeployer init
```

```sh
wget https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-8.0.26-linux-glibc2.12-x86_64.tar.gz
mkdir /opt/mysql
dbdeployer --sandbox-binary=/opt/mysql/ unpack mysql-8.0.26-linux-glibc2.12-x86_64.tar.gz
dbdeployer --sandbox-binary=/opt/mysql/ deploy single 8.0.26
dbdeployer --sandbox-binary=/opt/mysql/ deploy replication 8.0.26
dbdeployer --sandbox-binary=/opt/mysql/ deploy replication 8.0.26 --topology=star --nodes=3
dbdeployer --sandbox-binary=/opt/mysql/ sandboxes
dbdeployer --sandbox-binary=/opt/mysql/ delete all
ps -ef | grep mysql
cd sandboxes/msb_8_0_26/
./use
mysql -u root -h 127.1 -P 8011
mysql -uroot -pmsandbox -S/tmp/mysql_sandbox8011.sock
```

## MySQL 升级

- 就地升级 关停 MySQL 服务，备份数据文件，更新MySQL二进制文件或包替换旧的, 在现有数据目录中启动 MySQL 服务，执行 mysql_upgrade 命令

- 逻辑升级 使用 mysqldump 或 mysqlpump 工具导出数据，安装新版本 MySQL，使用导出的数据文件导入数据

```sh
systemctl stop mysql
mv /var/lib/mysql /var/lib/mysql.bak
yum erase mysql-community-server -y
yum-config-manager --disable mysql57-community
yum-config-manager --enable mysql80-community
yum install mysql-community-server -y
systemctl start mysql
tail -f /var/log/mysqld.log
```
