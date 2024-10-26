# 重置网络

```
./node.sh resetting
```

# 创建通道

```sh
./channel.sh init onechannel

```

# 加入通道

```sh
./channel.sh join onechannel
cli-org13-peer0
peer0.org13.luode.com orderer2.luode.com orderer1.luode.com orderer0.luode.com

```

# 安装链码

```sh
./chaincode.sh install onechannel onecc 1.0 1
cli-org13-peer0
orderer0.luode.com:7051

```

# 一键部署

```sh
./channel.sh init onechannel2


./channel.sh join onechannel2
cli-org13-peer0
peer0.org13.luode.com orderer2.luode.com orderer1.luode.com orderer0.luode.com


./chaincode.sh install onechannel2 onecc 1.0 1
cli-org13-peer0
orderer0.luode.com:7051


```

# 查询链码

```sh
./chaincode.sh query onechannel onecc [\"get\",\"cat\"]
cli-org13-peer0

```

# 调用链码

```sh
./chaincode.sh invoke onechannel onecc set [\"cat-1\",\"大懒猫\"]
cli-org13-peer0
orderer0.luode.com:7051

```

