# 项目地址
https://github.com/luode0320/nginx

# 创建目录
```sh
mkdir -p /usr/local/src/nginx
cd /usr/local/src/nginx
```



# docker 安装nginx

```sh
# 创建挂载目录
mkdir -p /usr/local/src/nginx/conf
mkdir -p /usr/local/src/nginx/ssl
mkdir -p /usr/local/src/nginx/log
mkdir -p /usr/local/src/nginx/html
mkdir -p /usr/local/src/nginx/public
cd /usr/local/src/nginx
```

```sh
# 生成临时容器
docker run --name nginx -p 9001:80 -d luode0320/nginx:latest
# 将容器nginx.conf文件复制到宿主机
docker cp nginx:/etc/nginx/nginx.conf /usr/local/src/nginx/conf/nginx.conf
# 将容器conf.d文件夹下内容复制到宿主机
docker cp nginx:/etc/nginx/conf.d /usr/local/src/nginx/conf
# 将容器中的html文件夹复制到宿主机
docker cp nginx:/usr/share/nginx/html /usr/local/src/nginx
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
-v /usr/local/src/nginx/public:/usr/share/nginx/public \
luode0320/nginx:latest
```

