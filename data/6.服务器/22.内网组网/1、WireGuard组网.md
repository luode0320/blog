# WireGuard

WireGuard **默认对所有流量进行端到端加密**，即使数据在私有网络（如 `10.0.0.0/24`）中传输也会加密。

注意: WireGuard 会被中国防火墙干扰, 可能会跑不通。



**在3台服务器上安装WireGuard**：

```sh
# Ubuntu/Debian
sudo apt update && sudo apt install -y wireguard
```



**生成密钥对**（分别在3台服务器执行）：

```sh
wg genkey | tee privatekey | wg pubkey > publickey
cat privatekey
cat publickey
```



**配置服务器端（例如香港服务器）**

- 香港的服务器要开放8333端口

- [Peer]就是客户端的节点, 如果需要多多, 就继续加[Peer]

```sh
tee /etc/wireguard/wg0.conf <<-'EOF'
[Interface]
Address = 10.0.0.1/24
PrivateKey = <香港服务器的privatekey>
ListenPort = 8333
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
PublicKey = <河北服务器的publickey>
AllowedIPs = 10.0.0.2/32
PersistentKeepalive = 10
EOF

[Peer]
PublicKey = <上海服务器的publickey>
AllowedIPs = 10.0.0.3/32
PersistentKeepalive = 10
EOF
```

```sh
# 服务端需启用ip转发
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl --system
```



**配置客户端（河北和上海服务器）**

```sh
# 河北
tee /etc/wireguard/wg0.conf <<-'EOF'
[Interface]
Address = 10.0.0.2/24
PrivateKey = <河北服务器的privatekey>

[Peer]
PublicKey = <香港服务器的publickey>
AllowedIPs = 10.0.0.0/24
Endpoint = 香港服务器公网IP:8333
PersistentKeepalive = 10
EOF
```

```sh
# 上海
tee /etc/wireguard/wg0.conf <<-'EOF'
[Interface]
Address = 10.0.0.3/24
PrivateKey = <上海服务器的privatekey>

[Peer]
PublicKey = <香港服务器的publickey>
AllowedIPs = 10.0.0.0/24
Endpoint = 香港服务器公网IP:8333
PersistentKeepalive = 10
EOF
```



**启动WireGuard**：

```sh
sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0
sudo systemctl status wg-quick@wg0

# 重启使用
sudo systemctl restart wg-quick@wg0
# 停止当前运行的 WireGuard 服务
sudo systemctl stop wg-quick@wg0
# 禁用开机自启
sudo systemctl disable wg-quick@wg0
```



**测试连通性**：

```sh
ping 10.0.0.1  # 从河北服务器测试香港服务器
ping 10.0.0.2  # 从香港服务器测试河北服务器
ping 10.0.0.3  # 从香港服务器测试上海服务器
ping 10.0.0.3  # 从河北服务器测试上海服务器
```



**在服务端监听端口**（临时测试):

```sh
# 香港服务器监听
root@CT121:~# nc -lvnp 5555 -s 10.0.0.1
Listening on 10.0.0.1 5555
Connection received on 10.0.0.2 44654
```

**从客户端尝试连接**：

```sh
# 河北服务器验证端口
root@CT1775:~# telnet 10.0.0.1 5555
Trying 10.0.0.1...
Connected to 10.0.0.1.
Escape character is '^]'.
```

**查看流量传输路径**：

```sh
# 安装
apt install -y traceroute

# 河北服务器测试流量: 本机 -> 10.0.0.1 -> 10.0.0.3
traceroute -n 10.0.0.3
```

```
traceroute to 10.0.0.3 (10.0.0.3), 30 hops max, 60 byte packets
 1  10.0.0.1  40.393 ms  40.311 ms  40.278 ms
 2  10.0.0.3  87.372 ms  87.329 ms  87.352 ms
```

**抓包测试:**

```sh
# 香港服务器执行
sudo tcpdump -i wg0 -nn icmp
17:52:37.370720 IP 10.0.0.2 > 10.0.0.3: ICMP echo request, id 24553, seq 1, length 64

# 上海客户端服务器执行
ping 10.0.0.3
```

```sh
# 香港服务器执行, 数据都是加密传输的
sudo tcpdump -i wg0 -nn -X
17:57:23.721882 IP 10.0.0.3 > 10.0.0.2: ICMP echo reply, id 24564, seq 3, length 64
	0x0000:  4500 0054 0663 0000 3f01 6142 0a00 0003  E..T.c..?.aB....
	0x0010:  0a00 0002 0000 3c01 5ff4 0003 837d 4468  ......<._....}Dh
	0x0020:  0000 0000 d54e 0800 0000 0000 1011 1213  .....N..........
	0x0030:  1415 1617 1819 1a1b 1c1d 1e1f 2021 2223  .............!"#
	0x0040:  2425 2627 2829 2a2b 2c2d 2e2f 3031 3233  $%&'()*+,-./0123
	0x0050:  3435 3637                                4567

```

