# 启动

* **13、16服务器都启动**

```
./node_start_stop_restart_list_log_open.sh start

./node_start_stop_restart_list_log_open.sh list
```

# 13服务器创建通道

* **注意配置通道文件 -> 查看附件**

```
./channel_init_join_list_json_addorg_sign_update_config.sh init onechannel


```

# 13节点加入通道

```
./channel_init_join_list_json_addorg_sign_update_config.sh join onechannel

 orderer0.xinhe.com orderer1.xinhe.com orderer2.xinhe.com

```

## 查询加入的节点

```
./channel_init_join_list_json_addorg_sign_update.sh list mychannel



```

# 安装链码

```
./chaincode_install_commit_invoke_query_info.sh install onechannel onecc 1.0 1


```

## 提交一条记录

```

./chaincode_install_commit_invoke_query_info.sh invoke mychannel mycc createCat  [\"sync\",\"tom\",\"3\",\"红色\",\"同步\"]
```

## 查询提交记录

```
./chaincode_install_commit_invoke_query_info.sh query mychannel mycc [\"queryCat\",\"sync\"]



```

# 更新通道

## 获取通道最新区块json

```
./channel_init_join_list_json_addorg_sign_update.sh json mychannel


```

## 拷贝区块文件到16服务器

```
scp ./channel-artifacts/mychannel.block root@192.168.1.16:/data/hyperledger/channel-artifacts/mychannel.block
```

```
scp ./channel-artifacts/mychannel.json root@192.168.1.16:/data/hyperledger/channel-artifacts/mychannel.json
```

## 通道配置: 16组织

* **详细查看附件 -> 16通道配置**

```
    - &Org16
        Name: Org16
        ID: Org16MSP
        MSPDir: ./crypto-config/peerOrganizations/org16.bob.com/msp
        Policies:
            Readers:
                Type: Signature
                Rule: "OR('Org16MSP.member')"
            Writers:
                Type: Signature
                Rule: "OR('Org16MSP.member')"
            Admins:
                Type: Signature
                Rule: "OR('Org16MSP.admin')"
            # 背书策略, 只有经过身份验证的 Peer 节点才能对交易进行背书，从而保证了交易的安全性和可信度
            Endorsement:
                Type: Signature
                Rule: "OR('Org16MSP.peer')"
        AnchorPeers:
            -   Host: peer0.org16.bob.com  # 锚节点的host地址
                Port: 7150        # 锚节点开放的端口号
```

## 生成更新通道json

* **在16服务器执行addorg**

```
./channel_init_join_list_json_addorg_sign_update.sh addorg mychannel
16
```

## 拷贝更新通道json到13服务器

```
scp ./channel-artifacts/mychannel-addorg-Org16.json root@192.168.1.13:/data/hyperledger/channel-artifacts/mychannel-addorg-Org16.json
```

## 背书签名验证

* **在13服务器上执行验证签名**
* **如果在背书节点在同一台服务器, 脚本可以生成json后继续执行背书验证**
  * **可以不用手动执行**

```
./channel_init_join_list_json_addorg_sign_update.sh sign mychannel ./channel-artifacts/mychannel-addorg-Org16.json



```

# 16节点加入通道

* **在16服务器执行join**

```
./channel_init_join_list_json_addorg_sign_update.sh join mychannel
```

## 查询加入的节点

```
./channel_init_join_list_json_addorg_sign_update.sh list mychannel



```

## 安装链码

```
./chaincode_install_commit_invoke_query_info.sh install mychannel mycc 1.0 1

orderer0.xinhe.com:7051
```

## 查询链码初始记录

```
./chaincode_install_commit_invoke_query_info.sh query mychannel mycc [\"queryCat\",\"cat-1\"]


```

## 查询同步记录

```
./chaincode_install_commit_invoke_query_info.sh query mychannel mycc [\"queryCat\",\"sync\"]



```

# 验证证书

```
# 根证书验证中间证书 可以
openssl verify -verbose -CAfile /data/hyperledger/crypto-config/ordererOrganizations/xinhe.com/orderers/orderer0.xinhe.com/tls/ca.crt /data/hyperledger/crypto-config/ordererOrganizations/xinhe.com/orderers/orderer0.xinhe.com/tls/server.crt
```

# 查看证书

```
openssl x509 -in /data/hyperledger/crypto-config/peerOrganizations/org13.aoa.com/peers/peer0.org13.aoa.com/msp/signcerts/peer0.org13.aoa.com-cert.pem -text -noout

openssl x509 -in /data/hyperledger/crypto-config/peerOrganizations/org1.xinhe.com/peers/peer0.org1.xinhe.com/msp/signcerts/cert.pem -text -noout

```

# 获取证书序列号

```
openssl x509 -in /data/hyperledger/crypto-config/ordererOrganizations/bob.com/orderers/orderer0.bob.com/msp/signcerts/cert.pem -serial -noout | cut -d "=" -f 2
```

# 查看密钥

```
openssl ec -in /data/hyperledger/tls-ca/crypto/msp/keystore/31b3209f423b5b762f6ad0f84a4372304fab1870bbea9e5b4b001786573a4fcc_sk -pubout
openssl ec -in /data/hyperledger/tls-ca/crypto/msp/keystore/93ea0a31bb408816b93dc92ca05d7c6c0af2c02c55f9b76028b0bab2ca750332_sk -pubout

openssl x509 -in /data/hyperledger/tls-ca/crypto/ca-cert.pem -noout -pubkey
openssl x509 -in /data/hyperledger/tls-ca/crypto/ca-chain.pem -noout -pubkey
openssl x509 -in /data/hyperledger/tls-ca/crypto/tls-cert.pem -noout -pubkey

```
