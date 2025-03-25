 	如果希望在不改动挂载目录、端口映射等配置的情况下，为现有容器添加 `--restart=always` 参数，可以通过以下步骤实现：

------

### **1. 使用 `docker update` 命令**

从 Docker 1.13 版本开始，`docker update` 命令支持直接修改容器的配置，包括 `--restart` 策略。

#### **步骤**

1. 查看容器的当前状态：

```sh
docker ps -a | grep mysql57
```

2. 使用 `docker update` 命令修改容器的重启策略：

```sh
docker update --restart=always mysql57
```

3. 验证是否生效：

```sh
docker inspect mysql57 --format '{{.HostConfig.RestartPolicy.Name}}'
```

​	如果输出为 `always`，说明配置成功。



4. 重启

```sh
systemctl restart docker
```

