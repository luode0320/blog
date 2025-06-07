### 1. 在香港服务器上确保 Shadowsocks 正常运行

```sh
docker run -d \
  --restart=always \
  --name shadowsocks \
  -p 8300:8388/tcp \
  -p 8300:8388/udp \
  -e SERVER_ADDR=0.0.0.0 \
  -e SERVER_PORT=8388 \
  -e PASSWORD=Ld@588588 \
  -e METHOD=aes-256-gcm \
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
    server: 192.238.204.29 # 香港服务器ip
    port: 8300 # 香港服务器端口
    type: ss
    password: Ld@588588 # 香港服务器vpn密码
    cipher: aes-256-gcm # 香港服务器vpn加密算法
    udp: true  # 允许 UDP 流量
  - name: "美国住宅代理"  # 代理名称（可自定义）
    type: socks5
    server: static-us8-gate.ipweb.cc  # 代理服务器地址
    port: 7778  # 端口
    username: lelaniyona2694_US_LosAngeles_kk2art51  # 用户名
    password: mhvuv2  # 密码
    udp: true  # 如果需要UDP支持
    
proxy-groups:
  - name: Proxy
    type: url-test      # 自动选择延迟最低的可用节点
    url: http://www.gstatic.com/generate_204
    interval: 10      # 每10s测试一次
    tolerance: 100      # 延迟相差100ms以内不切换
    proxies:
      - vpn
      - "美国住宅代理"
  - name: Direct
    type: select
    proxies:
      - DIRECT
  - name: Reject
    type: select
    proxies:
      - REJECT

rules:
  # ======== 基础规则 ========
  - IP-CIDR,192.168.0.0/16,Direct
  - IP-CIDR,10.0.0.0/8,Direct
  - IP-CIDR,172.16.0.0/12,Direct
  - GEOIP,CN,Direct
  
  # ======== 国内域名后缀直连 ========
  - DOMAIN-SUFFIX,cn,DIRECT
  - DOMAIN-SUFFIX,com.cn,DIRECT
  - DOMAIN-SUFFIX,gov.cn,DIRECT
  - DOMAIN-SUFFIX,edu.cn,DIRECT
  - DOMAIN-SUFFIX,net.cn,DIRECT
  - DOMAIN-SUFFIX,org.cn,DIRECT

  # ======== 你提供的域名规则（已分类） ========
  ## 百度系
  - DOMAIN-SUFFIX,baidu.com,DIRECT
  - DOMAIN-SUFFIX,baidubcr.com,DIRECT
  - DOMAIN-SUFFIX,bdstatic.com,DIRECT
  - DOMAIN-SUFFIX,yunjiasu-cdn.net,DIRECT

  ## 阿里系
  - DOMAIN-SUFFIX,taobao.com,DIRECT
  - DOMAIN-SUFFIX,alicdn.com,DIRECT
  - DOMAIN-SUFFIX,alibaba.com,DIRECT
  - DOMAIN-SUFFIX,alipay.com,DIRECT
  - DOMAIN-SUFFIX,aliyun.com,DIRECT
  - DOMAIN-SUFFIX,amap.com,DIRECT

  ## 腾讯系
  - DOMAIN-SUFFIX,qq.com,DIRECT
  - DOMAIN-SUFFIX,wechat.com,DIRECT
  - DOMAIN-SUFFIX,tencent.com,DIRECT
  - DOMAIN-SUFFIX,tenpay.com,DIRECT
  - DOMAIN-SUFFIX,qcloud.com,DIRECT
  - DOMAIN-SUFFIX,gtimg.com,DIRECT

  ## 网易系
  - DOMAIN-SUFFIX,163.com,DIRECT
  - DOMAIN-SUFFIX,126.net,DIRECT
  - DOMAIN-SUFFIX,netease.com,DIRECT
  - DOMAIN-SUFFIX,ydstatic.com,DIRECT

  ## 字节跳动（抖音/头条）
  - DOMAIN-SUFFIX,bytedance.com,DIRECT
  - DOMAIN-SUFFIX,douyin.com,DIRECT
  - DOMAIN-SUFFIX,ixigua.com,DIRECT
  - DOMAIN-SUFFIX,toutiao.com,DIRECT
  - DOMAIN-SUFFIX,pstatp.com,DIRECT

  ## 常用服务
  - DOMAIN-SUFFIX,jd.com,DIRECT       # 京东
  - DOMAIN-SUFFIX,bilibili.com,DIRECT # B站
  - DOMAIN-SUFFIX,zhihu.com,DIRECT    # 知乎
  - DOMAIN-SUFFIX,weibo.com,DIRECT    # 微博
  - DOMAIN-SUFFIX,xiaomi.com,DIRECT   # 小米
  - DOMAIN-SUFFIX,meituan.com,DIRECT  # 美团
  - DOMAIN-SUFFIX,didiglobal.com,DIRECT # 滴滴

  ## 其他高频域名（从你的列表中精选）
  - DOMAIN-SUFFIX,acgvideo.com,DIRECT
  - DOMAIN-SUFFIX,douban.com,DIRECT
  - DOMAIN-SUFFIX,iqiyi.com,DIRECT
  - DOMAIN-SUFFIX,youku.com,DIRECT
  - DOMAIN-SUFFIX,ximalaya.com,DIRECT
  - DOMAIN-SUFFIX,smzdm.com,DIRECT
  - DOMAIN-SUFFIX,sspai.com,DIRECT
  - DOMAIN-SUFFIX,tianyancha.com,DIRECT
  - DOMAIN-SUFFIX,xiachufang.com,DIRECT
  - DOMAIN-SUFFIX,zimuzu.tv,DIRECT
  
  # ======== 最终兜底规则 ========
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