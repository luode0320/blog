#!/bin/bash

echo "拉取最新代码..."
git pull git@gitee.com:luode0320/blog.git

echo "停止并移除旧容器（如果存在）..."
docker rm -f blog

echo "删除旧镜像（如果存在）..."
docker rmi luode0320/blog:latest

echo "构建镜像 luode0320/blog:latest..."
docker build -t luode0320/blog:latest .

echo "清理数据卷目录.."
rm -Rf /usr/local/src/blog/data

echo "运行新的容器..."
docker run \
    --restart=always \
    --name blog \
    -d \
    -p 4000:4000 \
    -v /usr/local/src/blog/data:/app/data \
    luode0320/blog:latest
