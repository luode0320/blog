<div align="center">
<img src="./favicon.ico" alt="预览"/>

<h1 align="center">Blog</h1>

欧皇小德子的个人博客。

[导航页](https://luode.vip) / [QQ群 542544997]()


![index](Static/png/index.png)

</div>

# 启动

## 安装依赖

```shell
npm install
```

## 执行
```shell
node index.js 
```

# 提交

项目提供自动打包docker一键部署到公网服务器

如不需要, 请注释/删除该文件
```txt
.github/workflows/main.yml
```

# dokcer启动

## latest 版本

```shell
docker pull luode0320/blog:latest
```

启动:

```shell
docker run --restart=always --name blog -d -p 4000:4000 luode0320/blog:latest
```
