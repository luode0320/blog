# 查询要安装 JDK 的版本

```shell
yum -y list java*
```

```shell
[root@rod ~]# yum -y list java*
可安装的软件包
java-1.6.0-openjdk.x86_64                              1:1.6.0.41-1.13.13.1.el7_3                 base
```

# 安装 JDK1.8 版本

```shell
yum install -y java-1.8.0-openjdk.x86_64
```

# 安装完成后查看 JDK 版本信息

```shell
[root@rod ~]# java -version
openjdk version "1.8.0_382"
OpenJDK Runtime Environment (build 1.8.0_382-b05)
OpenJDK 64-Bit Server VM (build 25.382-b05, mixed mode)
```

