### 1. 在香港服务器上确保 Shadowsocks 正常运行

```sh
docker run -d \
  --restart=always \
  --name shadowsocks \
  -p 8388:8388/tcp \
  -p 8388:8388/udp \
  -e SERVER_ADDR=0.0.0.0 \
  -e SERVER_PORT=8388 \
  -e PASSWORD=Ld@588588 \
  -e METHOD=aes-128-gcm \
  luode0320/shadowsocks
```



### 2. 国内服务器配置

```sh
mkdir -p /usr/local/src/clash
tee /usr/local/src/clash/config.yaml <<-'EOF'
port: 7897 # http 代理端口
allow-lan: true # 是否允许局域网其他设备通过本机代理
mode: Rule
log-level: info

proxies:
  - name: vpn
    server: 10.10.10.10 # 香港服务器ip
    port: 8388 # 香港服务器端口
    type: ss
    password: Ld@588588 # 香港服务器vpn密码
    cipher: aes-128-gcm # 香港服务器vpn加密算法
    udp: true  # 允许 UDP 流量

proxy-groups:
  - name: Proxy
    type: url-test      # 自动选择延迟最低的可用节点
    url: http://www.gstatic.com/generate_204
    interval: 10      # 每10s测试一次
    tolerance: 50      # 延迟相差50ms以内不切换
    proxies:
      - vpn
  - name: Direct
    type: select
    proxies:
      - DIRECT
  - name: Reject
    type: select
    proxies:
      - REJECT

rules:
  - IP-CIDR,192.168.0.0/16,Direct
  - IP-CIDR,10.0.0.0/8,Direct
  - IP-CIDR,172.16.0.0/12,Direct
  - GEOIP,CN,Direct
  - GEOIP,US,Proxy
  - MATCH,Proxy
EOF
```

### 3. 国内服务器启动

```sh
docker run -d \
  --restart always \
  --name clash \
  --network host \
  -v /usr/local/src/clash/config.yaml:/root/.config/clash/config.yaml \
  luode0320/clash:latest
```



### 4. 测试流量是否走代理

```sh
# 当前公网
curl http://ip.sb
# 测试 HTTP 代理公网
curl -x http://127.0.0.1:7897 http://ip.sb

# 无代理不通
curl -s https://api.binance.com/api/v3/exchangeInfo
# 代理通
curl -x http://127.0.0.1:7897  -s https://api.binance.com/api/v3/exchangeInfo
```

配置全局代理

```sh
# 1. [可选]本机全局永久配置(192.10.10.19)
echo -e '\n# Set Proxy\nexport http_proxy="http://127.0.0.1:7897"\nexport https_proxy="http://127.0.0.1:7897"\nexport all_proxy="socks5://127.0.0.1:7897"' >> ~/.bashrc && source ~/.bashrc
# 2. [可选]内网服务器全局永久配置(192.10.10.44)
echo -e '\n# Set Proxy\nexport http_proxy="http://192.10.10.19:7897"\nexport https_proxy="http://192.10.10.19:7897"\nexport all_proxy="socks5://192.10.10.19:7897"' >> ~/.bashrc && source ~/.bashrc
# 3. [可选]外网服务器全局永久配置(192.10.10.44)
echo -e '\n# Set Proxy\nexport http_proxy="http://10.10.10.10:7897"\nexport https_proxy="http://10.10.10.10:7897"\nexport all_proxy="socks5://10.10.10.10:7897"' >> ~/.bashrc && source ~/.bashrc
# 3. 取消配置
# echo -e '\n# Set Proxy\nexport http_proxy=\nexport https_proxy=\nexport all_proxy=' >> ~/.bashrc && source ~/.bashrc

# 查看所有代理相关的环境变量
env | grep -i proxy

# 无显示配置代理通
curl -s https://api.binance.com/api/v3/exchangeInfo
```

