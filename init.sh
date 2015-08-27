#!/bin/bash

mariadb_config_base=$(cd `dirname $0`; pwd)
. $mariadb_config_base/mariadb-cluster.conf

echo "配置mariadb的yum源"
cp -f $mariadb_config_base/MariaDB.repo /etc/yum.repos.d/
yum -y install galera MariaDB-Galera-server MariaDB-client

echo "修改mariadb配置"
mariadb_server_cnf=/etc/my.cnf.d/my-innodb-heavy-4G.cnf
cp -f /usr/share/mysql/my-innodb-heavy-4G.cnf $mariadb_server_cnf
sed -i -e '/\[mysqld\]/a\ndatadir='"${mariadb_data_base}"'' $mariadb_server_cnf

echo "初始化数据库"
mysql_install_db --datadir=$mariadb_data_base

echo "修改wsrep配置"
cp /usr/share/mysql/wsrep.cnf  /etc/my.cnf.d/

sed -i -e 's,wsrep_provider=none,wsrep_provider=/usr/lib64/galera/libgalera_smm.so,g' /etc/my.cnf.d/wsrep.cnf
sed -i -e 's,wsrep_sst_auth=root:,wsrep_sst_auth=sst:sst1234,g' /etc/my.cnf.d/wsrep.cnf
ip=`ifconfig | grep 'inet '| grep -v '127.0.0.1' | awk '{ print $2}'`
sed -i -e 's,#wsrep_node_address=,wsrep_node_address='"${ip}"',g' /etc/my.cnf.d/wsrep.cnf

if [ ${ip} = ${mariadb_galera_cluster_ip} ]; then
    sed -i -e 's,#wsrep_cluster_address="dummy://",wsrep_cluster_address="gcomm://",g' /etc/my.cnf.d/wsrep.cnf
else
    sed -i -e 's,#wsrep_cluster_address="dummy://",wsrep_cluster_address="gcomm://'"${mariadb_galera_cluster_ip}"'",g' /etc/my.cnf.d/wsrep.cnf
fi

echo "配置系统设置selinux and firewall"
sed -i -e 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
systemctl stop firewalld.service
systemctl disable firewalld.service

echo "配置mysql数据库用户"

systemctl start mysql.service
/sbin/chkconfig mysql on
mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'sst'@'%' IDENTIFIED BY 'sst1234' WITH GRANT OPTION"
mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root' WITH GRANT OPTION"
mysql -e "FLUSH PRIVILEGES"

