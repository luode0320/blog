# 一、环境准备

**MySql的主从复制、主主复制【MySql 5.7，Docker】**

> 我们需要准备两台MySql，我这里使用docker，那么我就需要开启两个MySql容器就好了。
> docker安装MySql看这里 [Docker安装MySql并启动](https://www.xdx97.com/article/709492164794515456)
> docker相关命令 [Docker常用命令【镜像、容器、File】持续更新…](https://www.xdx97.com/article/709353261982810112)



# 二、主从复制

## 2-1：配置主服务器

### 2-1-1：配置主服务器的 my.cnf 添加以下内容

```
[mysqld]
## 同一局域网内注意要唯一
server-id=1
## 开启二进制日志功能，可以随便取（关键）
log-bin=mysql-bin
```

如果你是使用我上面那种方式启动的MySql，那么你只需要去你相关联的宿主机的配置文件夹里面去建立一个 my.cnf 然后写入上面的类容就好了。

比如：我的启动命令如下（不应该换行的，这里为了方便查看，我给它分行了）

那么我只需要在 **/docker/mysql_master/conf** 这个目录下创建 my.cnf 文件就好了。

```
 docker run -p 12345:3306 --name mysql_master 
-v /docker/mysql_master/conf:/etc/mysql/conf.d 
-v /docker/mysql_master/logs:/logs 
-v /docker/mysql_master/data:/var/lib/mysql 
-e MYSQL_ROOT_PASSWORD=123456 -d mysql:5.7
```

### 2-1-2：重启服务

这个命令是需要在容器里面执行的

```
 service mysql restart
```

docker重启mysql会关闭容器，我们需要重启容器。

### 2-1-3：查看 skip_networking 的状态

确保在主服务器上 skip_networking 选项处于 OFF 关闭状态, 这是默认值。
如果是启用的，则从站无法与主站通信，并且复制失败。

```
mysql> show variables like '%skip_networking%';
+-----------------+-------+
| Variable_name   | Value |
+-----------------+-------+
| skip_networking | OFF   |
+-----------------+-------+
1 row in set (0.00 sec)
```

### 2-1-4：创建一个专门用来复制的用户

```
CREATE USER 'repl'@'%' identified by '123456';

GRANT REPLICATION SLAVE ON *.*  TO  'repl'@'%';
```



## 2-2：配置从服务器

### 2-2-1：配置从服务器的 my.cnf (和上面一致)

```
[mysqld]
server-id=2
```

我的命令如下

```
docker run -p 12346:3306 --name mysql_from 
-v /docker/mysql_from/conf:/etc/mysql/conf.d 
-v /docker/mysql_from/logs:/logs 
-v /docker/mysql_from/data:/var/lib/mysql 
-e MYSQL_ROOT_PASSWORD=123456 -d mysql:5.7
```

### 2-2-2：重启 从服务器 (和上面一致)

### 2-2-3：配置连接到主服务器的相关信息

在从服务器配置连接到主服务器的相关信息 （在容器里面的mysql执行）

```
mysql>  CHANGE MASTER TO MASTER_HOST='xxxxx', MASTER_PORT=3306,MASTER_USER='repl',MASTER_PASSWORD='123456';
```

上面代码的xxxxx你需要换成你的IP，docker 查看容器 IP 的命令如下：

```
docker inspect --format=’{{.NetworkSettings.IPAddress}}’ 容器名称/容器id
```

启动的那个从服务器的线程

```
mysql> start slave;
Query OK, 0 rows affected (0.00 sec)
```

### 2-2-4：查看同步状态

```
mysql>  show slave status \G;
```

![image.png](../../../图片保存\preview)



## 2-3：测试

测试的话，你可以在主服务器里面，创建一个数据库，发现从服务器里面也有了，就成功了。



## 2-4：其它

#### 2-4-1 ：如果你还想要一个从服务器，那么你只需要按照上面配置从服务器再配置一个就行了，

#### 2-4-2 ：新建的从服务器，会自动保存主服务器之前的数据。（测试结果）



# 三、主主复制

如果你上面的主从复制搞定了，那么这个主主复制就很简单了。我们把上面的从服务器也改成主服务器

### 1、修改上面的从服务器的my.cnf文件，和主服务器的一样（注意这个server-id不能一样）然后重启服务器

### 2、在从服务器里面创建一个复制用户创建命令一样（这里修改一下用户名可以改为 repl2）

### 3、在之前的主服务器里面运行下面这个代码

```
 CHANGE MASTER TO MASTER_HOST='xxxx', MASTER_PORT=3306,MASTER_USER='repl2',MASTER_PASSWORD='123456';

start slave;
```

### 4、测试





# 四、其它

> 上面主要是教你怎么搭建一个MySql集群，但是这里面还有很多其它的问题。也是我在学习过程中思考的问题，可能有的小伙伴上来看到文章长篇大论的看不下去，只想去实现这样一直集群功能，所以我就把问题写在下面了。

### 1、MySQL的replication和pxc

MySql的集群方案有replication和pxc两种，上面是基于replication实现的。

**replication:** 异步复制，速度快，无法保证数据的一致性。
**pxc:** 同步复制，速度慢，多个集群之间是事务提交的数据一致性强。



### 2、MySQL的replication数据同步的原理

我们在配置的时候开启了它的二进制日志，每次操作数据库的时候都会更新到这个日志里面去。主从通过同步这个日志来保证数据的一致性。



### 3、可否不同步全部的数据

可以配置，同步哪些数据库，甚至是哪些表。



### 4、怎么关闭和开始同步

```
mysql> STOP SLAVE;

mysql> START SLAVE;
```



### 5、我就我的理解画出了，主从、主从从、主主、复制的图。

![image.png](../../../图片保存\preview)



### 6、视频讲解

https://www.bilibili.com/video/BV1BK4y1t7MY/