# 一个已经启动的容器

binance-save



# 进入容器查看原文件

```sh
docker exec -it binance-save cat /app/luode/main.py
```



# 备份

```sh
# 执行备份命令（容器名称为 binance-save）
docker exec binance-save cp /app/luode/main.py /app/luode/main.py.bak
```



# 拷贝需要修改的文件到容器

```sh
# 直接执行拷贝，若目标文件存在会自动覆盖
docker cp /usr/local/src/binance-save/main.py binance-save:/app/luode/main.py
```



# 进入容器查看

```sh
docker exec -it binance-save cat /app/luode/main.py
```



# 将更新后的容器打包为新镜像

```sh
docker commit binance-save luode0320/binance-save:latest
```



# 新镜像

```sh
docker images
```

