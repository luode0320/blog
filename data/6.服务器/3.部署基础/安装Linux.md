# 下载ISO文件
- 阿里云盘
- 链接：[https://www.aliyundrive.com/s/iMUgwXqR8oF](https://www.aliyundrive.com/s/iMUgwXqR8oF)
- 「CentOS-7-x86_64-DVD-2009.iso.EXE」(重命名去掉后缀EXE)

# 新建虚拟机
- 打开VMware选择 > 文件 > 新建虚拟机
![在这里插入图片描述](../../picture/fd45a0dc264080ea16aa6f851d975917.png)
![在这里插入图片描述](../../picture/041939d72f346f3d3fd6a8065d23b0f2.png)
![在这里插入图片描述](../../picture/728c97d302e1edaa0d1d84eb30921dac.png)
![在这里插入图片描述](../../picture/aea55a51b9fa18ae168f0c502239416f.png)
![在这里插入图片描述](../../picture/b35366d433d74e6a4b8ecbd4280a7c04.png)
![在这里插入图片描述](../../picture/23af7c4243ae064cb0186dcffb477fa1.png)
![在这里插入图片描述](../../picture/48b5fe7ab8fe4cb9e072dbbd530dd4ca.png)
![在这里插入图片描述](../../picture/3157c4c10391cee84cad148734578134.png)
![在这里插入图片描述](../../picture/d137d2bc2b9c55d0cca4be5d6abad607.png)
![在这里插入图片描述](../../picture/c927d609fd808b6bb42725eeb592f9a1.png)
![在这里插入图片描述](../../picture/dd69c1fe1d3bab212347d359a24cb85a.png)
![在这里插入图片描述](../../picture/61e8319c5fc9f605e44e02b39da423ea.png)
![在这里插入图片描述](../../picture/015023919fad491244fd08eb406fd22f.png)
![在这里插入图片描述](../../picture/e477b5378b36de0541305bc12f381e43.png)
![在这里插入图片描述](../../picture/b27bebaf18ff20936ca545aa1feacf63.png)
![在这里插入图片描述](../../picture/ff480086e13caa37b4a2a0c71664e721.png)
# 安装Linux系统
![在这里插入图片描述](../../picture/b336f8a3298334368ad8fd34c7b52b6d.png)
![在这里插入图片描述](../../picture/c8feed542c63ee47e7618e09dc06e7db.png)
![在这里插入图片描述](../../picture/1e94297aa5a65512eda57cab786f5e63.png)
![在这里插入图片描述](../../picture/598907ad3db16878f374f4babe0de07f.png)
![在这里插入图片描述](../../picture/880277bd070837dcacaa4a86196ca40f.png)
![在这里插入图片描述](../../picture/f9d7335143763113871132b50bac9af5.png)
![在这里插入图片描述](../../picture/318da8dcda7b991c997297d55fa92b88.png)
![在这里插入图片描述](../../picture/3a2e4fa992238d007903dfffd3a9e20a.png)
![在这里插入图片描述](../../picture/6df1a4b67d72ee0f6f4f4ca10233f323.png)

![在这里插入图片描述](../../picture/3ca7b80eda22def8b9621eac62a67207.png)
![在这里插入图片描述](../../picture/3455589e55a370ebcd4ab13929791aaf.png)
![在这里插入图片描述](../../picture/44a3f7316df05d8b3c1d5a376733decd.png)
![在这里插入图片描述](../../picture/6b184fdbfdd9a370dfefa4058bbae0e0.png)
![在这里插入图片描述](../../picture/5971dda10aed591a7d1572cce851b651.png)
![在这里插入图片描述](../../picture/b060b16e6f4dfc3a27dcb4ebcfb1d06c.png)
![在这里插入图片描述](../../picture/3687b0badc1d333fea78ee11b5bb392d.png)
![在这里插入图片描述](../../picture/aab21576f2a3a0c99fd1eba3b3411bb2.png)
![在这里插入图片描述](../../picture/f8a2e79534481f3fd7cd5e14a6e4ce9e.png)
- root密码过于简单需要按两次完成
![在这里插入图片描述](../../picture/d22faa671863aac19c290986ecf4593e.png)
![在这里插入图片描述](../../picture/4f3c53921f3957c6c0086c6f1abdadbf.png)
![在这里插入图片描述](../../picture/f9b68c280698f12859f448e556f89f96.png)
![在这里插入图片描述](../../picture/1c66af9d14476444c68ec3de9cd5c9ed.png)
# xshell连接
- ip addr => `192.168.9.25`
![在这里插入图片描述](../../picture/3e99da5ed16ad9577961cfe1387d80de.png)
![在这里插入图片描述](../../picture/eb5e4f26d606586d1eed70ab63bbef67.png)
![在这里插入图片描述](../../picture/5429ebfcd46e0e3fa62ae7258724bbf8.png)
![在这里插入图片描述](../../picture/134b57fd28a2682233f6f86e97b1cff7.png)
![在这里插入图片描述](../../picture/87d4b64238fb9408f5a65f7181a9316c.png)
![在这里插入图片描述](../../picture/65834831f6fe0e6f52b5fd3f66f14274.png)
![在这里插入图片描述](../../picture/3b3af0d22759df633dfb8a1e3a38de4a.png)



# 更新ip地址

```sh
# 查看ip所在网络
ip addr
ens32: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 00:0c:29:e5:1e:8f brd ff:ff:ff:ff:ff:ff
    inet 192.168.2.22/24 brd 192.168.2.255 scope global noprefixroute ens32
    valid_lft forever preferred_lft forever
    inet6 fe80::20c:29ff:fee5:1e8f/64 scope link
    valid_lft forever preferred_lft forever


# 修改文件ifcfg-ens32文件
cd /etc/sysconfig/network-scripts
vi ifcfg-ens32
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=static
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
IPADDR=192.168.3.3
NETWASK=255.255.255.0
GATEWAY=192.168.3.2
DNS1=114.114.114.114
DNS2=8.8.8.8

# 重启网络
service network restart
# 重启
reboot
```

# 更新vm配置

1. 配置网段

![image-20250412135804370](../../picture/image-20250412135804370.png)

2. 配置网关

![image-20250412135837261](../../picture/image-20250412135837261.png)



# 配置路由

根据前面NAT设置查看网络: vmnet8

![image-20250412135918365](../../picture/image-20250412135918365.png)



右键属性, 点击ipv4

![image-20250412140043605](../../picture/image-20250412140043605.png)

# 清理虚拟机磁盘

有时候虚拟机的磁盘已经清理了, 但是windwos的磁盘还是被占用, 需要清理

```sh
sudo /usr/bin/vmware-toolbox-cmd disk list
sudo /usr/bin/vmware-toolbox-cmd disk shrink /
```

