# centos

## 使用阿里源下载新版本

### 安装需要的软件驱动

```shell
yum install -y yum-utils device-mapper-persistent-data lvm2
```

### 配置docker下载的yum源

```shell
yum -y install wget
wget -P /etc/yum.repos.d/ https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
```

### 查看yum源仓库支持的版本

```shell
[root@rod ~]# yum list docker-ce --showduplicates | sort -r
docker-ce.x86_64            3:24.0.6-1.el7                      docker-ce-stable
```

### 安装

```shell
yum -y install docker-ce-24.0.6-1.el7  docker-ce-cli-24.0.6-1.el7
```

### 查询

```shell
[root@luode src]# docker -v
Docker version 24.0.6, build ed223bc
```

### 安装docker-compose

```shell
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/bin/docker-compose
```

添加执行权限

```shell
chmod +x /usr/bin/docker-compose
```

检查docker compose版本

```shell
docker-compose version
```

### 设置docker服务开机启动

```shell
#加载docker配置
#启动docker服务
#设置docker服务开机自启
systemctl daemon-reload
systemctl start docker
systemctl enable docker
```

### 配置镜像站

```sh
mkdir -p /etc/docker
cd /etc/docker
```

写入镜像地址:

```sh
sudo tee /etc/docker/daemon.json <<-'EOF'
{
    "registry-mirrors": ["https://dockerproxy.cn","https://docker.rainbond.cc","https://docker.udayun.com","https://docker.211678.top"]
}
EOF
```

```sh
 systemctl daemon-reload
 systemctl restart docker
```

# 登录

```sh
docker login -u 用户名 -p 密码
```

