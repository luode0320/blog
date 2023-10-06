# 防火墙

```shell
systemctl status firewalld # 查看防火墙状态 
systemctl start firewalld  # 开启防火墙  
systemctl stop firewalld # 关闭防火墙 
```

# 查看防火墙的开放的端口

```shell
firewall-cmd --permanent --list-ports
```

# 开放端口

```shell
# 添加指定需要开放的端口
# 重载入添加的端口
# 查询
sudo firewall-cmd --add-port=80/tcp --permanent
sudo firewall-cmd --zone=public --permanent --add-port=443/tcp
sudo firewall-cmd --permanent --add-port=32000/tcp
sudo firewall-cmd --permanent --add-port=32001/tcp
sudo firewall-cmd --permanent --add-port=32002/tcp
firewall-cmd --reload
firewall-cmd --permanent --list-ports
```

# 移除指定端口

```shell
firewall-cmd --permanent --remove-port=3306/tcp
```

# windos测试端口

```shell
[root@centos7-127 ~]# telnet 192.168.31.111 3306
Trying 192.168.87.128...
Connected to 192.168.87.128.  # 表示端口已经开放
```

