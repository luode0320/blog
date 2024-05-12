# 登陆到Docker Hub

```shell
docker login -u 用户名 -p 密码
```

- 登出Docker Hub

```shell
docker logout
```

# 重命名镜像

```shell
docker tag 旧名称:旧tag版本 用户名/新名称:新tag版本
```

# 推送到私人仓库

```shell
docker push 用户名/新名称:新tag版本
```

# 查询私人仓库

```shell
docker search 用户名
```

# 将容器打包为镜像

```shell
docker commit d5944567401a mssql-2019-with-cimb:1.0
```

