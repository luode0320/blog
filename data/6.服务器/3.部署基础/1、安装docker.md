# centos安装

安装需要的软件驱动

```shell
# 下载阿里云镜像源配置
sudo mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
sudo curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
# 清除缓存并重建
sudo yum clean all
sudo yum makecache
yum install -y yum-utils device-mapper-persistent-data lvm2
```

配置docker下载的yum源

```shell
yum -y install wget
wget -P /etc/yum.repos.d/ https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
```

查看yum源仓库支持的版本

```shell
[root@rod ~]# yum list docker-ce --showduplicates | sort -r
docker-ce.x86_64            3:24.0.6-1.el7                      docker-ce-stable
```

安装

```shell
# 安装
yum -y install docker-ce-24.0.6-1.el7  docker-ce-cli-24.0.6-1.el7
```



# Ubuntu安装

安装需要的软件驱动

```sh
apt update
apt-get install -y ca-certificates curl gnupg lsb-release
apt install -y apt-transport-https ca-certificates curl software-properties-common
```

配置docker下载的源

```sh
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

安装

```sh
apt-get install -y containerd
apt-get update
apt-get install -y docker-ce docker-ce-cli docker-compose-plugin
```



### 查询

```shell
docker -v
#加载docker配置
#启动docker服务
#设置docker服务开机自启
systemctl daemon-reload
systemctl start docker
systemctl enable docker
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

### 配置镜像站

```sh
mkdir -p /etc/docker
cd /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
    "registry-mirrors": [
        "https://docker.registry.cyou",
        "https://docker-cf.registry.cyou",
        "https://dockercf.jsdelivr.fyi",
        "https://docker.jsdelivr.fyi",
        "https://dockertest.jsdelivr.fyi",
        "https://mirror.aliyuncs.com",
        "https://dockerproxy.com",
        "https://mirror.baidubce.com",
        "https://docker.m.daocloud.io",
        "https://docker.nju.edu.cn",
        "https://docker.mirrors.sjtug.sjtu.edu.cn",
        "https://docker.mirrors.ustc.edu.cn",
        "https://mirror.iscas.ac.cn",
        "https://docker.rainbond.cc",
        "https://do.nark.eu.org",
        "https://dc.j8.work",
        "https://dockerproxy.com",
        "https://gst6rzl9.mirror.aliyuncs.com",
        "https://registry.docker-cn.com",
        "http://hub-mirror.c.163.com",
        "http://mirrors.ustc.edu.cn/",
        "https://mirrors.tuna.tsinghua.edu.cn/",
        "http://mirrors.sohu.com/"
    ]
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

# 更新容器的资源限制

```sh
docker update --restart=always kafka
```

