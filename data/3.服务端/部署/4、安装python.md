# 配置epel源

```shell
yum install -y epel-release
```

# 安装

```shell
yum install -y python3
```

# 查询版本

```shell
[root@rod ~]# python -V # 系统默认
Python 2.7.5
[root@rod ~]# python3 -V # 最新安装
Python 3.6.8
```

# 修改系统默认的python 命令

```shell
cd /usr/bin
mv python python.bak
ln -s python3 python
```

# 最新版本

```shell
[root@rod bin]# python -V
Python 3.6.8
```

# 修改命令

```shell
# 两文件修改方式相同：
vim /usr/bin/yum
vim /usr/libexec/urlgrabber-ext-down

将第一行"#!/usr/bin/python" 改为 "#!/usr/bin/python2"即可
```

