#### 一、下载二进制文件

网址：https://nodejs.org/zh-cn/download/prebuilt-binaries

![image-20241028171545959](../../picture/image-20241028171545959.png)

#### 二、解压

- 拷贝到服务器

![image-20241028171729297](../../picture/image-20241028171729297.png)

- 解压

```bash
cd /root/luode/zip
tar xf node-v20.18.0-linux-x64.tar.xz
```

![image-20241028171900870](../../picture/image-20241028171900870.png)

#### 三、设置软连接

```bash
ln -s /root/luode/zip/node-v20.18.0-linux-x64/bin/npm   /usr/local/bin/ 
ln -s /root/luode/zip/node-v20.18.0-linux-x64/bin/node   /usr/local/bin/
```

![image-20241028172122790](../../picture/image-20241028172122790.png)