# 项目地址
https://github.com/luode0320/nginx

# 创建目录
mkdir -p /usr/local/src/nginx
cd /usr/local/src/nginx

# 拷贝项目所有文件到服务器

# 解压
tar -xzvf nginx-1.24.0.tar.gz

# 安装命令

yum -y install epel-release gcc gcc-c++ make autoconf automake openssl openssl-devel zlib zlib-devel libtool pcre
pcre-devel kernel-headers kernel-devel patch

# 安装代理插件
cd /usr/local/src/nginx/nginx-1.24.0
patch -p1 < /usr/local/src/nginx/http_proxy/patch/proxy_connect_rewrite_102101.patch

# 编译安装nginx
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

# 如果已经安装nginx, 只需要make就好了
make && make install

# 进入安装目录

cd /usr/local/src/nginx

# 拷贝启动文件, 如果已经安装nginx需要重新拷贝
# cp objs/nginx /usr/local/src/nginx/sbin/nginx
/usr/local/src/nginx/sbin/nginx -V

# 配置systemctl
vi /usr/lib/systemd/system/nginx.service

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

systemctl daemon-reload
systemctl start nginx
systemctl enable nginx

# docker 安装可视化界面

看情况是否需要安装: 内存90M
docker pull luode0320/nginx-ui:latest

# 启动ui

docker run -itd \
--restart=always \
--net=host \
--name nginx-ui \
-v /usr/local/src/nginx-ui:/home/nginxWebUI \
-e BOOT_OPTIONS="--server.port=3000" \
luode0320/nginx-ui:latest

# 访问

http://IP:3000/

第一次登录会初始化管理员账户