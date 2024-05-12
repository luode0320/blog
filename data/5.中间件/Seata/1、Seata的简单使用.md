# Seata的简单使用

本文只介绍Seata的简单使用,没有涉及其原理.

 

## 1.在本地搭建一个TC服务(事务协调者).

### 1.1 下载seata的安装包

官网(https://github.com/seata/seata/releases)

　　往下滑滑,找到你想要的版本和格式下载即可.我这里使用的是`seata-server-1.1.0.zip`,解压即可使用.



### 1.2 配置

打开解压目录下的conf/registry.conf文件如下

```shell
registry {
  # file 、nacos 、eureka、redis、zk、consul、etcd3、sofa
  # 可以把seata-server理解为一个服务,它需要把自己注册到某个注册中心上去,方便使用seata的服务来找到自己
    #在这里就是指定注册中心的类型,由于我们项目用的是eureka,所以这里我选择eureka,即这一堆配置就下面一个eureka生效了
    #这里默认的是file,即文件,选了文件就可以不用搭注册中心,直接从文件里读取服务列表
    #复制之后一定要改一改
  type = "eureka"  

  nacos {
    serverAddr = "localhost"
    namespace = ""
    cluster = "default"
  }
  eureka { #"只有我生效啦"
    serviceUrl = "http://localhost:10086/eureka"  #eureka地址
    application = "seata_tc_server"		#在eureka里显示的名字
    weight = "1"
  }
  redis {
    serverAddr = "localhost:6379"
    db = "0"
  }
  zk {
    cluster = "default"
    serverAddr = "127.0.0.1:2181"
    session.timeout = 6000
    connect.timeout = 2000
  }
  consul {
    cluster = "default"
    serverAddr = "127.0.0.1:8500"
  }
  etcd3 {
    cluster = "default"
    serverAddr = "http://localhost:2379"
  }
  sofa {
    serverAddr = "127.0.0.1:9603"
    application = "default"
    region = "DEFAULT_ZONE"
    datacenter = "DefaultDataCenter"
    cluster = "default"
    group = "SEATA_GROUP"
    addressWaitTime = "3000"
  }
  file {
    name = "file.conf"
  }
}

config {
    #在这里选择配置中心,这里我们选择file
  # file、nacos 、apollo、zk、consul、etcd3
  type = "file"

  nacos {
    serverAddr = "localhost"
    namespace = ""
    group = "SEATA_GROUP"
  }
  consul {
    serverAddr = "127.0.0.1:8500"
  }
  apollo {
    app.id = "seata-server"
    apollo.meta = "http://192.168.1.204:8801"
    namespace = "application"
  }
  zk {
    serverAddr = "127.0.0.1:2181"
    session.timeout = 6000
    connect.timeout = 2000
  }
  etcd3 {
    serverAddr = "http://localhost:2379"
  }
  file {
      #由于选择了file,所以这里生效了
    name = "file.conf"
  }
}
```

所以接下来看一下`file.conf`文件

```shell
## transaction log store, only used in seata-server
store {
  ## store mode: file、db
    #选择配置中心的存储模式,由于选择file存到文件里(性能高)会变为二进制流不好观察,所以选择数据库
     #复制之后一定要改一改
  mode = "db"

  ## file store property
  file {
    ## store location dir
    dir = "sessionStore"
    # branch session size , if exceeded first try compress lockkey, still exceeded throws exceptions
    maxBranchSessionSize = 16384
    # globe session size , if exceeded throws exceptions
    maxGlobalSessionSize = 512
    # file buffer size , if exceeded allocate new buffer
    fileWriteBufferCacheSize = 16384
    # when recover batch read size
    sessionReloadReadSize = 100
    # async, sync
    flushDiskMode = async
  }

  ## database store property
  db {
      #选择了数据库必定要做出一些配置,数据库里一定要有这3张表
    ## the implement of javax.sql.DataSource, such as DruidDataSource(druid)/BasicDataSource(dbcp) etc.
    datasource = "dbcp"
    ## mysql/oracle/h2/oceanbase etc.
    dbType = "mysql"
    driverClassName = "com.mysql.jdbc.Driver"
    url = "jdbc:mysql://192.168.206.99:3306/seata"
    user = "root"
    password = "root"
    minConn = 1
    maxConn = 10
    globalTable = "global_table"
    branchTable = "branch_table"
    lockTable = "lock_table"
    queryLimit = 100
  }
}
```

建表SQL如下:

```sql
CREATE TABLE IF NOT EXISTS `global_table`
(
    `xid`                       VARCHAR(128) NOT NULL,
    `transaction_id`            BIGINT,
    `status`                    TINYINT      NOT NULL,
    `application_id`            VARCHAR(32),
    `transaction_service_group` VARCHAR(32),
    `transaction_name`          VARCHAR(128),
    `timeout`                   INT,
    `begin_time`                BIGINT,
    `application_data`          VARCHAR(2000),
    `gmt_create`                DATETIME,
    `gmt_modified`              DATETIME,
    PRIMARY KEY (`xid`),
    KEY `idx_gmt_modified_status` (`gmt_modified`, `status`),
    KEY `idx_transaction_id` (`transaction_id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8;

-- the table to store BranchSession data
CREATE TABLE IF NOT EXISTS `branch_table`
(
    `branch_id`         BIGINT       NOT NULL,
    `xid`               VARCHAR(128) NOT NULL,
    `transaction_id`    BIGINT,
    `resource_group_id` VARCHAR(32),
    `resource_id`       VARCHAR(256),
    `branch_type`       VARCHAR(8),
    `status`            TINYINT,
    `client_id`         VARCHAR(64),
    `application_data`  VARCHAR(2000),
    `gmt_create`        DATETIME,
    `gmt_modified`      DATETIME,
    PRIMARY KEY (`branch_id`),
    KEY `idx_xid` (`xid`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8;

-- the table to store lock data
CREATE TABLE IF NOT EXISTS `lock_table`
(
    `row_key`        VARCHAR(128) NOT NULL,
    `xid`            VARCHAR(96),
    `transaction_id` BIGINT,
    `branch_id`      BIGINT       NOT NULL,
    `resource_id`    VARCHAR(256),
    `table_name`     VARCHAR(32),
    `pk`             VARCHAR(36),
    `gmt_create`     DATETIME,
    `gmt_modified`   DATETIME,
    PRIMARY KEY (`row_key`),
    KEY `idx_branch_id` (`branch_id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8;
```

### 1.3 启动

如果是linux环境（要有JRE），执行`seata-server.sh`

如果是windows环境，执行`seata-server.bat`

## 2 改造微服务

只要是需要用到seata(分布式事务)的服务,都要做类似的配置.

### 2.1 引入依赖

我这里是springboot项目,所以我先在父pom中声明了.如下

```xml
    <properties>    
        <alibaba.seata.version>2.1.0.RELEASE</alibaba.seata.version>
        <seata.version>1.1.0</seata.version>
    </properties>

    <dependencyManagement>
        <dependencies>
            <!--seata-->
            <dependency>
                <groupId>com.alibaba.cloud</groupId>
                <artifactId>spring-cloud-alibaba-seata</artifactId>
                <version>${alibaba.seata.version}</version>
                <exclusions>
                    <exclusion>
                        <artifactId>seata-all</artifactId>
                        <groupId>io.seata</groupId>
                    </exclusion>
                </exclusions>
            </dependency>
            <dependency>
                <artifactId>seata-all</artifactId>
                <groupId>io.seata</groupId>
                <version>${seata.version}</version>
            </dependency>
        </dependencies>
    </dependencyManagement>
```

接下来只要在需要seata的微服务里添加依赖就好了.

```xml
<dependency>
    <groupId>com.alibaba.cloud</groupId>
    <artifactId>spring-cloud-alibaba-seata</artifactId>
</dependency>
<dependency>
    <groupId>io.seata</groupId>
    <artifactId>seata-all</artifactId>
</dependency>
```

### 2.2 添加配置

```yml
spring:
  cloud:
    alibaba:
      seata:
        tx-service-group: test_tx_group # 定义事务组的名称
```

### 2.3 在resources目录下添加2个文件`file.conf`和`registry.conf`

`registry.conf`和前面的一样,直接复制过来就好.

file.conf里的内容不同了,新的内容如下:

```shell
transport {
  # tcp udt unix-domain-socket
  type = "TCP"
  #NIO NATIVE
  server = "NIO"
  #enable heartbeat
  heartbeat = true
  # the client batch send request enable
  enableClientBatchSendRequest = true
  #thread factory for netty
  threadFactory {
    bossThreadPrefix = "NettyBoss"
    workerThreadPrefix = "NettyServerNIOWorker"
    serverExecutorThread-prefix = "NettyServerBizHandler"
    shareBossWorker = false
    clientSelectorThreadPrefix = "NettyClientSelector"
    clientSelectorThreadSize = 1
    clientWorkerThreadPrefix = "NettyClientWorkerThread"
    # netty boss thread size,will not be used for UDT
    bossThreadSize = 1
    #auto default pin or 8
    workerThreadSize = "default"
  }
  shutdown {
    # when destroy server, wait seconds
    wait = 3
  }
  serialization = "seata"
  compressor = "none"
}
service {
#这里注意,等号前后都是配置,前面是yml里配置的事务组,后面是register.conf里定义的seata-server
  vgroupMapping.test_tx_group = "seata_tc_server"
  #only support when registry.type=file, please don't set multiple addresses
  seata_tc_server.grouplist = "127.0.0.1:8091"
  #degrade, current not support
  enableDegrade = false
  #disable seata
  disableGlobalTransaction = false
}

client {
  rm {
    asyncCommitBufferLimit = 10000
    lock {
      retryInterval = 10
      retryTimes = 30
      retryPolicyBranchRollbackOnConflict = true
    }
    reportRetryCount = 5
    tableMetaCheckEnable = false
    reportSuccessEnable = false
  }
  tm {
    commitRetryCount = 5
    rollbackRetryCount = 5
  }
  undo {
    dataValidation = true
    logSerialization = "jackson"
    logTable = "undo_log"
  }
  log {
    exceptionRate = 100
  }
}
```

配置解读：

- `transport`：与TC交互的一些配置
  - `heartbeat`：client和server通信心跳检测开关
  - `enableClientBatchSendRequest`：客户端事务消息请求是否批量合并发送
- `service`：TC的地址配置，用于获取TC的地址
  - `vgroupMapping.test_tx_group = "seata_tc_server"`：
    - `test_tx_group`：是事务组名称，要与application.yml中配置一致，
    - `seata_tc_server`：是TC服务端集群的名称，将来通过注册中心获取TC地址
    - `enableDegrade`：服务降级开关，默认关闭。如果开启，当业务重试多次失败后会放弃全局事务
    - `disableGlobalTransaction`：全局事务开关，默认false。false为开启，true为关闭
  - `default.grouplist`：这个当注册中心为file的时候，才用到
- `client`：客户端配置
  - `rm`：资源管理器配
    - `asynCommitBufferLimit`：二阶段提交默认是异步执行，这里指定异步队列的大小
    - `lock`：全局锁配置
      - `retryInterval`：校验或占用全局锁重试间隔，默认10，单位毫秒
      - `retryTimes`：校验或占用全局锁重试次数，默认30次
      - `retryPolicyBranchRollbackOnConflict`：分支事务与其它全局回滚事务冲突时锁策略，默认true，优先释放本地锁让回滚成功
    - `reportRetryCount`：一阶段结果上报TC失败后重试次数，默认5次
  - `tm`：事务管理器配置
    - `commitRetryCount`：一阶段全局提交结果上报TC重试次数，默认1
    - `rollbackRetryCount`：一阶段全局回滚结果上报TC重试次数，默认1
  - `undo`：undo_log的配置
    - `dataValidation`：是否开启二阶段回滚镜像校验，默认true
    - `logSerialization`：undo序列化方式，默认Jackson
    - `logTable`：自定义undo表名，默认是`undo_log`
  - `log`：日志配置
    - `exceptionRate`：出现回滚异常时的日志记录频率，默认100，百分之一概率。回滚失败基本是脏数据，无需输出堆栈占用硬盘空间

### 2.4 代理DataSource

由于在一阶段是通过拦截sql分析语义来生成回滚策略,原来的数据源已经不够用了,得换个牛逼的.在服务里新建一个配置类.

- 如果是使用的是mybatis

```java
import io.seata.rm.datasource.DataSourceProxy;
import org.apache.ibatis.session.SqlSessionFactory;
import org.mybatis.spring.SqlSessionFactoryBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import javax.sql.DataSource;

@Configuration
public class DataSourceProxyConfig {

    @Bean
    public SqlSessionFactory sqlSessionFactoryBean(DataSource dataSource) throws Exception {
        // 因为使用的是mybatis，这里定义SqlSessionFactoryBean
        SqlSessionFactoryBean sqlSessionFactoryBean = new SqlSessionFactoryBean();
        // 配置数据源代理
        sqlSessionFactoryBean.setDataSource(new DataSourceProxy(dataSource));
        return sqlSessionFactoryBean.getObject();
    }
}
```

如果使用的是mybatis-plus

```java
import com.baomidou.mybatisplus.extension.spring.MybatisSqlSessionFactoryBean;
import io.seata.rm.datasource.DataSourceProxy;
import org.apache.ibatis.session.SqlSessionFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import javax.sql.DataSource;

@Configuration
public class DataSourceProxyConfig {

    @Bean
    public SqlSessionFactory sqlSessionFactoryBean(DataSource dataSource) throws Exception {
        // 订单服务中引入了mybatis-plus，所以要使用特殊的SqlSessionFactoryBean
        MybatisSqlSessionFactoryBean sqlSessionFactoryBean = new MybatisSqlSessionFactoryBean();
        // 代理数据源
        sqlSessionFactoryBean.setDataSource(new DataSourceProxy(dataSource));
        // 生成SqlSessionFactory
        return sqlSessionFactoryBean.getObject();
    }
}
```

### 2.5 加上注解

给事务发起者的方法上加上`@GlobalTransactional`即可,其它的参与者只要加`@Transactional`就好了

```java
@GlobalTransactional(rollbackFor = Exception.class)
@Transactional(rollbackFor = Exception.class)
public RModel saveOrUpdate(JSONObject data) {

}
```

## 3.踩坑记录

1.由于更换了数据源,不知道为什么我在yml里给mybatis配置的驼峰映射失效了,导致我查到的数据缺少了某些字段.不知道这个问题在mybatis-plus中会不会出现.

解决办法:单独给数据源配置映射规则就好了.所以我把上面的配置类加了一个设置,修改后的代码如下.

```
import io.seata.rm.datasource.DataSourceProxy;
import org.apache.ibatis.session.SqlSessionFactory;
import org.mybatis.spring.SqlSessionFactoryBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import javax.sql.DataSource;

@Configuration
public class DataSourceProxyConfig {

    @Bean
    public SqlSessionFactory sqlSessionFactoryBean(DataSource dataSource) throws Exception {
        // 因为使用的是mybatis，这里定义SqlSessionFactoryBean
        SqlSessionFactoryBean sqlSessionFactoryBean = new SqlSessionFactoryBean();
        // 配置数据源代理
        sqlSessionFactoryBean.setDataSource(new DataSourceProxy(dataSource));
        SqlSessionFactory object = sqlSessionFactoryBean.getObject();
        assert object != null;　　　　　// 单独给数据源设置驼峰映射
        object.getConfiguration().setMapUnderscoreToCamelCase(true);
        return object;
    }
}
```

 