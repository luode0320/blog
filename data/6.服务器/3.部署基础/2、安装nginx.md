# 项目地址
https://github.com/luode0320/nginx

# 创建目录
```sh
mkdir -p /usr/local/src/nginx
cd /usr/local/src/nginx
```



# 拷贝项目所有文件到服务器

# 解压
```
tar -xzvf nginx-1.24.0.tar.gz
```



# 安装命令

```
yum -y install epel-release gcc gcc-c++ make autoconf automake openssl openssl-devel zlib zlib-devel libtool pcre
pcre-devel kernel-headers kernel-devel patch
```



# 安装代理插件
```
cd /usr/local/src/nginx/nginx-1.24.0
patch -p1 < /usr/local/src/nginx/http_proxy/patch/proxy_connect_rewrite_102101.patch
```



# 编译安装nginx
```
./configure --prefix=/usr/local/src/nginx \
--with-http_stub_status_module \
--with-http_ssl_module \
--with-http_v2_module \
--with-http_realip_module \
--with-threads \
--with-stream \
--with-stream_ssl_preread_module \
--with-stream_ssl_module \
--add-module=/usr/local/src/nginx/http_proxy
```



# 如果已经安装nginx, 只需要make就好了
```
make && make install
```



# 进入安装目录

```
cd /usr/local/src/nginx
```



# 拷贝启动文件, 如果已经安装nginx需要重新拷贝
```
@cp objs/nginx /usr/local/src/nginx/sbin/nginx

/usr/local/src/nginx/sbin/nginx -V

```

# 配置systemctl

```
vi /usr/lib/systemd/system/nginx.service
```



```shell
[Unit]
Description=nginx
After=network.target remote-fs.target nss-lookup.target
[Service]
Type=forking
PIDFile=/usr/local/src/nginx/logs/nginx.pid
ExecStartPre=/usr/local/src/nginx/sbin/nginx -t -c /usr/local/src/nginx/conf/nginx.conf
ExecStart=/usr/local/src/nginx/sbin/nginx -c /usr/local/src/nginx/conf/nginx.conf
ExecReload=/usr/local/src/nginx/sbin/nginx -s reload
ExecStop=/usr/local/src/nginx/sbin/nginx -s stop
ExecQuit=/usr/local/src/nginx/sbin/nginx -s quit
PrivateTmp=true
[Install]
WantedBy=multi-user.target
```

# systemctl启动

```
systemctl daemon-reload
systemctl start nginx
systemctl enable nginx
```



# docker 安装nginx

```sh
docker pull luode0320/nginx:latest
```

```sh
# 创建挂载目录
mkdir -p /usr/local/src/nginx/conf
mkdir -p /usr/local/src/nginx/log
mkdir -p /usr/local/src/nginx/html
cd /usr/local/src/nginx
```

```sh
# 生成临时容器
docker run --name nginx -p 9001:80 -d luode0320/nginx:latest
# 将容器nginx.conf文件复制到宿主机
docker cp nginx:/etc/nginx/nginx.conf /usr/local/src/nginx/conf/nginx.conf
# 将容器conf.d文件夹下内容复制到宿主机
docker cp nginx:/etc/nginx/conf.d /usr/local/src/nginx/conf/conf.d
# 将容器中的html文件夹复制到宿主机
docker cp nginx:/usr/share/nginx/html /home/nginx/
# 删除临时容器
docker rm -f nginx
```

```sh
docker run -d \
--restart always \
--network host \
--name nginx \
-v /usr/local/src/nginx/conf/nginx.conf:/etc/nginx/nginx.conf \
-v /usr/local/src/nginx/conf/conf.d:/etc/nginx/conf.d \
-v /usr/local/src/nginx/ssl:/etc/nginx/ssl \
-v /usr/local/src/nginx/log:/var/log/nginx \
-v /usr/local/src/nginx/html:/usr/share/nginx/html \
luode0320/nginx:latest
```
