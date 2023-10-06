# 卸载旧nginx

```shell
find  /  -name nginx 
```

```shell
[root@luode src]# rm -rf /var/log/nginx
[root@luode src]# rm -rf /var/cache/nginx
[root@luode src]# rm -rf /usr/sbin/nginx
[root@luode src]# rm -rf /usr/lib64/nginx
[root@luode src]# rm -rf /etc/nginx
```



#  安装源

```shell
rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
```

# 安装

```shell
yum install -y nginx-1.18.0
```

# 启动Nginx 设置开机自启

```shell
# 启动nginx
# 设置开机自启
systemctl start nginx.service
systemctl enable nginx.service
systemctl daemon-reload
```

