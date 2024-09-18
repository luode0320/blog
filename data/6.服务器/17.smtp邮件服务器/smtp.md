# 启动

```sh
docker run --restart=always -d \
-e "RELAY_NETWORKS=:0.0.0.0/0" \
--name smtp \
-p 1000:25 \
-v /etc/hosts:/etc/hosts \
luode0320/smtp-emix:latest \
exim -bd -q1m -v
```

## 说明

1. RELAY_NETWORKS 如果写 :0.0.0.0/0 表示任意客户端均可发送， 1000端口根据实际需要调整
2. 我们挂载了宿主机的hosts文件到容器, 如果你在测试中需要使用域名替换127.0.0.1, 则将对应的域名配置到hosts文件中

```conf
# 这样如果我们使用这个域名发送邮件, 会寻找本机启动的服务
127.0.0.1 smtp.luode.vip
```

3. 我们设置了 -q1m 检查发送邮件队列的时间间隔为1分钟

# 测试

编写测试文件:

```
vi smtp.py
```

```python
#!/usr/bin/python3

import smtplib
from email.header import Header
from email.mime.text import MIMEText

sender = 'luode@test.com'
receivers = ['luode0321@qq.com']

message = MIMEText('verification', 'plain', 'utf-8')

subject = 'verification'
message['Subject'] = Header(subject, 'utf-8')

try:
    smtpObj = smtplib.SMTP('smtp.luode.vip', 1000)
    smtpObj.sendmail(sender, receivers, message.as_string())
    print ("success")
except smtplib.SMTPException:
    print ("error")
```

执行测试:

```sh
python3 smtp.py
```