# 登录

```shell
docker login -u 用户名 -p 密码
```

# 查询用户仓库的镜像

```shell
docker search --user=用户名
```

# 进入容器

```shell
docker exec -it my-container bash
```

# 将容器打包为镜像

```shell
docker commit d5944567401a mssql-2019-with-cimb:1.0
```

