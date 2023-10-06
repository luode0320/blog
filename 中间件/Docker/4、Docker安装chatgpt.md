# chatgpt聊天室

https://github.com/Rod0320/chatgpt-node

 如果CODE为空, 则表示任何人都可以访问。并且OPENAI_API_KEY是必填的。

# 1.0版本

- 此版本可以填写一个指定的key和多个访问密码code
- 多个访问密码code逗号隔开

```shell
docker pull luode0320/chatgpt:1.0
```

启动:

```shell
docker run -d -p 3000:3000 \
   -e OPENAI_API_KEY="open ai key" \
   -e CODE="luode,ld,luochen,lc,zhouyishan,zys,tangyan,ty" \
   luode0320/chatgpt:1.0
```

# 2.0版本

- 此版本可以填写多个指定的key和多个访问密码code
- 多个访问密码code逗号隔开
- 多个key由逗号分开, 根据请求的ip做key的映射

```shell
docker pull luode0320/chatgpt:2.0
```

启动:

```shell
docker run -d -p 3000:3000 \
   -e OPENAI_API_KEY="open ai key,open ai key" \
   -e CODE="luode,ld,luochen,lc,zhouyishan,zys,tangyan,ty" \
   luode0320/chatgpt:2.0
```


# 3.0版本

- 此版本可以填写多个指定的key和多个访问密码code
- 多个访问密码code逗号隔开
- 多个key由逗号分开, 多个key会随机选择一个请求

```shell
docker pull luode0320/chatgpt:3.0
```

启动:

```shell
docker run -d -p 3000:3000 \
   -e OPENAI_API_KEY="open ai key,open ai key" \
   -e CODE="luode,ld,luochen,lc,zhouyishan,zys,tangyan,ty" \
   luode0320/chatgpt:3.0
```

# 4.0版本

- 此版本可以填写多个指定的key和多个访问密码code
- 多个访问密码code逗号隔开
- 多个key由逗号分开, 多个key会轮询选择一个请求

```shell
docker pull luode0320/chatgpt:4.0
```

启动:

```shell
docker run -d -p 3000:3000 \
   -e OPENAI_API_KEY="open ai key,open ai key" \
   -e CODE="luode,ld,luochen,lc,zhouyishan,zys,tangyan,ty" \
   luode0320/chatgpt:4.0
```

# latest版本

- 此版本可以填写多个指定的key和多个访问密码code
- 多个访问密码code逗号隔开
- 多个key由逗号分开, 根据请求的ip做key的映射

```shell
docker pull luode0320/chatgpt:latest
```

启动:

```shell
docker run -d -p 3000:3000 --restart=always  --name chatgpt\
   -e OPENAI_API_KEY="open ai key,open ai key" \
   -e CODE="luode,ld,luochen,lc,zhouyishan,zys,tangyan,ty" \
   luode0320/chatgpt:latest
```