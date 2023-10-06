# 安装操作系统自带的版本

此版本是很旧的版本

## 查询可用版本

```shell
[root@rod bin]# yum list -y docker*
可安装的软件包
docker.x86_64                                     2:1.13.1-209.git7d71120.el7.centos          
```

## 安装docker

```shell
yum -y install docker.x86_64
```

## 查询版本

```shell
[root@rod bin]# docker -v
Docker version 1.13.1, build 7d71120/1.13.1
```

## 设置docker服务开机自启动

```shell
# docker 服务开机自启动命令
systemctl enable docker.service

# 关闭docker 服务开机自启动命令
systemctl disable docker.service
```

- 重启生效

```shell
reboot
```

# 使用阿里源下载新版本

## 安装需要的软件驱动

```shell
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
```

## 配置docker下载的yum源

```shell
wget -P /etc/yum.repos.d/ https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
```

## 查看yum源仓库支持的版本

```shell
[root@rod ~]# yum list docker-ce --showduplicates | sort -r
docker-ce.x86_64            3:24.0.6-1.el7                      docker-ce-stable
```

## 安装

```shell
yum -y install docker-ce-24.0.6-1.el7  docker-ce-cli-24.0.6-1.el7 
```

## 查询

```shell
[root@luode src]# docker -v
Docker version 24.0.6, build ed223bc
```

## 设置docker服务开机启动

```shell
#加载docker配置
#启动docker服务
#设置docker服务开机自启
systemctl daemon-reload
systemctl start docker
systemctl enable docker
```

