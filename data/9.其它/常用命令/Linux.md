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
firewall-cmd --zone=public --permanent --add-port=443/tcp
firewall-cmd --add-port=80/tcp --permanent
firewall-cmd --permanent --add-port=22/tcp
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

# 网络配置

cat /etc/sysconfig/network-scripts/ifcfg-ens32

```
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=dhcp
DEFROUTE=yes
#IPV4_FAILURE_FATAL=no
$IPV6INIT=yes
$IPV6_AUTOCONF=yes
$IPV6_DEFROUTE=yes
$IPV6_FAILURE_FATAL=no
$IPV6_ADDR_GEN_MODE=stable-privacy
NAME=ens32
DEVICE=ens32
ONBOOT=yes
IPV6_PRIVACY=no
IPADDR=192.168.2.22
NETWASK=255.255.255.0
GATEWAY=192.168.2.2
DNS1=114.114.114.114
DNS2=8.8.8.8
```



# 磁盘

```
df -h
du -h -d 0 /usr/local/src/sdk
```

