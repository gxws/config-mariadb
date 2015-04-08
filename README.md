config-mariadb
==============

mariadb服务器配置

说明
---
###1、文档
[mariadb文档](http://mariadb.org/)

###2、服务器结构
由3台服务器组成的集群，每台服务器运行1个mariadb实例。<br />
集群结构为多机单实例方式。

###3、目录结构
数据库实例根目录在/home/mysql/data。<br />

###4、集群模式
MariaDB的galera集群配置，使用mariadb multi-master多主方式。<br />
三层负载均衡，用dns配置ip负载均衡。<br />
四层负载均衡，可以用lvs做负载均衡，用keepalived做主机节点有效性检测。

###5、访问
使用DNS配置域名mysql.gxwsxx.com，或dev.mysql.gxwsxx.com。



单实例集群手动配置教程
---

## 一、安装MariaDB集群

### 1、添加yum源

在/etc/yum.repos.d添加文件MariaDB.repo，由于版本原因，有可能需要修改baseurl的地址
```bash
[root@localhost yum.repos.d]# yum makecache
```

### 2、安装MariaDB

安装MariaDB-Galera-server galera MariaDB-client
```bash
[root@localhost yum.repos.d]# yum -y install MariaDB-Galera-server galera MariaDB-client
```


### 3、登录mysql

设置mysql用户
```sql
MariaDB [(none)]> GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root' WITH GRANT OPTION;

MariaDB [(none)]> GRANT ALL PRIVILEGES ON *.* TO 'sst'@'%' IDENTIFIED BY 'sst' WITH GRANT OPTION;

MariaDB [(none)]> FLUSH PRIVILEGES;
```

### 4、创建并配置wsrep.cnf文件

```bash
[root@localhost my.cnf.d]# cp /usr/share/mysql/wsrep.cnf  /etc/my.cnf.d/
[root@localhost my.cnf.d]# vim /etc/my.cnf.d/wsrep.cnf
```
修改以下变量
```bash
wsrep_provider=/usr/lib64/galera/libgalera_smm.so

#配置集群中上一个节点
wsrep_cluster_address="gcomm://"

#mysql sst用户和密码
wsrep_sst_auth=sst:sst

wsrep_sst_method=rsync

#设置本机IP地址
wsrep_node_address=192.168.x.x
```

### 5、启动mysql

```bash
[root@localhost my.cnf.d]# systemctl start mysql.service
```

### 6、添加节点

修改配置文件
```bash
[root@localhost my.cnf.d]# vim /etc/my.cnf.d/wsrep.cnf
```

```bash
#配置集群中上一个节点
wsrep_cluster_address="gcomm://192.168.x.x:4567"
```

启动新节点
```bash
[root@localhost my.cnf.d]# systemctl start mysql.service
```

单实例集群手动配置教程
---