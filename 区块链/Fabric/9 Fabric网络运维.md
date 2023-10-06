# Fabric网络运维

# Fabric查询命令

```bash
# 查询指定peer节点上已经安装的链码
peer lifecycle chaincode queryinstalled

# 查看链码是否就绪，检查链码是否可以向通道提交
peer lifecycle chaincode checkcommitreadiness --channelID mychannel --name hyperledger-fabric-contract-java-demo --version 1 --sequence 2 --output json --init-required

# 查看同一组织已经安装的链码
peer lifecycle chaincode queryapproved -C mychannel -n contract-java

# 按通道查询已经提交的链码定义
peer lifecycle chaincode querycommitted --channelID mychannel --name contract-java

# 从peer节点获取已经安装的链码包
peer lifecycle chaincode getinstalledpackage --package-id hyperledger-fabric-contract-java-demo_1:56155589e9cf9d99a90e2250accb1f0052954ccce9fcd8958e6d3a95e0f51d25

# 获取第0个区块
peer channel fetch 0 mychannel.block -o orderer0.xinhe.com:7050 -c mychannel --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/xinhe.com/orderers/orderer0.xinhe.com/msp/tlscacerts/tlsca.xinhe.com-cert.pem

# 查看当前channel信息
peer channel getinfo -c mychannel

# 查看mychannel中的第1个块的信息
peer chaincode query -C "mychannel" -n qscc -c '{"Args":["GetBlockByNumber","myrchannel","0"]}' | more
```

# discover工具

```bash
# 显示通道中的 Peer 节点信息，包括它们的 MSP ID、gRPC 服务监听地址和身份证书。
discover peers --channel mychannel \
--peerTLSCA /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.xinhe.com/msp/cacerts/ca-immediate-xinhe-com-7055.pem \
--userKey /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.xinhe.com/users/Admin\@org1.xinhe.com/msp/keystore/priv_sk \
--userCert /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.xinhe.com/users/Admin\@org1.xinhe.com/msp/signcerts/cert.pem \
--MSP Org1MSP --server peer0.org1.xinhe.com:7051

discover --configFile discover_config.yaml peers --channel mychannel --server peer0.org1.xinhe.com:7051

# 显示网络中的通道配置信息
discover config --channel mychannel \
--peerTLSCA /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.xinhe.com/msp/cacerts/ca-immediate-xinhe-com-7055.pem \
--userKey /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.xinhe.com/users/Admin\@org1.xinhe.com/msp/keystore/priv_sk \
--userCert /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.xinhe.com/users/Admin\@org1.xinhe.com/msp/signcerts/cert.pem \
--MSP Org1MSP --tlsCert /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.xinhe.com/peers/peer0.org1.xinhe.com/tls/server.crt \
--tlsKey /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.xinhe.com/peers/peer0.org1.xinhe.com/tls/server.key \
--server peer0.org1.xinhe.com:7051

discover --configFile discover_config.yaml config --channel mychannel --server peer0.org1.xinhe.com:7051

# 显示网络中的背书节点信息，包括它们的 MSP ID、账本高度、服务地址和身份证书等。
discover --peerTLSCA \
/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.xinhe.com/msp/cacerts/ca-immediate-xinhe-com-7055.pem \
--userKey /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.xinhe.com/users/Admin\@org1.xinhe.com/msp/keystore/priv_sk \
--userCert /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.xinhe.com/users/Admin\@org1.xinhe.com/msp/signcerts/cert.pem \
--MSP Org1MSP --tlsCert /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.xinhe.com/peers/peer0.org1.xinhe.com/tls/server.crt \
--tlsKey /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.xinhe.com/peers/peer0.org1.xinhe.com/tls/server.key \
endorsers \
--channel mychannel \
--chaincode hyperledger-fabric-contract-java-demo \
--server peer0.org1.xinhe.com:7051

discover --configFile discover_config.yaml endorsers --channel mychannel --chaincode hyperledger-fabric-contract-java-demo --server peer0.org1.xinhe.com:7051

# 该命令并不与 Peer 节点打交道，它将由参数指定的变量信息保存为本地文件。这样用户在执行后续命令时可以指定该文件，而无须再指定各个参数值。需要通过 --conf igFile=CONFIGFILE 来指定所存放的参数信息文件路径。例如，保存指定的参数信息到本地的 discover_config.yaml 文件，可以执行如下命令：

discover saveConfig --configFile discover_config.yaml \
--peerTLSCA /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.xinhe.com/msp/cacerts/ca-immediate-xinhe-com-7055.pem \
--userKey /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.xinhe.com/users/Admin\@org1.xinhe.com/msp/keystore/priv_sk \
--userCert /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.xinhe.com/users/Admin\@org1.xinhe.com/msp/signcerts/cert.pem \
--MSP Org1MSP --tlsCert /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.xinhe.com/peers/peer0.org1.xinhe.com/tls/server.crt \
--tlsKey /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.xinhe.com/peers/peer0.org1.xinhe.com/tls/server.key
```

# 网络中添加通道

```bash
#生成通道文件 (外面)
configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel-1.tx -channelID channel-1

# 创建通道，并生成配置文件
peer channel create -o orderer.example.com:7050 -c mychannel-1 -f ./channel-artifacts/channel-1.tx --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

peer channel create -o orderer0.rod.com:7051 -c twochannel -f ./channel-artifacts/twochannel.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/rod.com/msp/tlscacerts/tlsca.rod.com-cert.pem

# 加入通道
peer channel join -b mychannel-1.block

# 查看改组织的通道列表
peer channel list
```

# peer节点上安装链码

## go的链码

## java的链码

```bash
# 进入 cli 容器：
docker exec -it fabric-cli bash
# 在宿主机和 docker cli 容器挂载的 chaincodes 目录下下载合约代码：
git clone https://gitee.com/kernelHP/hyperledger-fabric-contract-java-demo.git
cd hyperledger-fabric-contract-java-demo/
# 编译打包源码：
mvn compile package -DskipTests -Dmaven.test.skip=true
mv target/chaincode.jar $PWD

# 删除编译后产生的 target 目录； src 源代码目录； pom.xml
rm -rf target/ src pom.xml
# 得到如下结构目录:
hyperledger-fabric-contract-java-demo/
├── chaincode.jar
├── collections_config.json
├── META-INF
│   └── statedb
│       └── couchdb
│           └── indexes
│               └── indexNameColor.json

# **打包链码**
peer lifecycle chaincode package hyperledger-fabric-contract-java-demo.tar.gz --path ./hyperledger-fabric-contract-java-demo/ --lang java --label hyperledger-fabric-contract-java-demo_1

# 在 peer 节点安装链码
peer lifecycle chaincode install hyperledger-fabric-contract-java-demo.tar.gz

# 检查peer节点上安装的链码
peer lifecycle chaincode queryinstalled

# 调用链码
# 调用 createCat 函数
peer chaincode invoke -o orderer0.example.com:7050 --ordererTLSHostnameOverride orderer0.example.com --tls --cafile /etc/hyperledger/fabric/crypto-config/ordererOrganizations/example.com/orderers/orderer0.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C businesschannel -n hyperledger-fabric-contract-java-demo --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /etc/hyperledger/fabric/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:7051 --tlsRootCertFiles /etc/hyperledger/fabric/crypto-config/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"function":"createCat","Args":["cat-0" , "tom" ,  "3" , "蓝色" , "大懒猫"]}'

# 调用 queryCat 函数
peer chaincode query -C businesschannel -n hyperledger-fabric-contract-java-demo -c '{"Args":["queryCat" , "cat-0"]}'
```

# peer节点上升级链码

[Fabric2.0中如何升级智能合约](https://www.yisu.com/zixun/522671.html)

```bash
#打包链码
peer lifecycle chaincode package mycc_new.tar.gz --path github.com/hyperledger/fabric-samples/chaincode/mycc/go/ --lang golang --label mycc_1

#安装链码
peer lifecycle chaincode install mycc_new.tar.gz

#查询已安装链码
peer lifecycle chaincode queryinstalled

#提交到通道
peer lifecycle chaincode approveformyorg --channelID mychannel --name mycc \
--version 2.0  --package-id mycc_1:65ea30cc6efcd0d44b14e0ac1b9f971334ead973dc463651e4d826a32529276e --sequence 2 --tls true \
--cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

#查询通道的审核情况
peer lifecycle chaincode checkcommitreadiness --channelID mychannel --name mycc --version 2.0 --sequence  2 --output json
```

# Fabric搭建常用命令

```bash
#使用以下命令生成创世区块。
configtxgen -profile TwoOrgsOrdererGenesis -channelID fabric-channel -outputBlock ./channel-artifacts/genesis.block
#使用以下命令生成通道文件。
configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID mychannel
#使用以下命令为 Org1 定义锚节点。
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID mychannel -asOrg Org1MSP
#使用以下命令为 Org2 定义锚节点。
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx -channelID mychannel -asOrg Org2MSP

docker cp cli:/opt/gopath/src/github.com/hyperledger/fabric/peer/mychannel.block ./

sshpass -p Xinhe12#$ scp mychannel.block root@192.168.1.136:/root/FABRIC/org-fabric

docker cp mychannel.block cli:/opt/gopath/src/github.com/hyperledger/fabric/peer/

docker exec -it cli bash

# 使用以下命令在客户端容器中创建通道，并生成配置文件（在Org1容器上操作）
peer channel create -o orderer0.xinhe.com:7050 -c mychannel -f ./channel-artifacts/channel.tx --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/xinhe.com/msp/tlscacerts/tls-ca-immediate-xinhe-com-7055.pem

# 加入通道
peer channel join -b mychannel.block

# 更新苗节点
#使用以下命令来更新锚节点（在org1容器上操作）。
peer channel update -o orderer0.xinhe.com:7050 -c mychannel -f ./channel-artifacts/Org1MSPanchors.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/xinhe.com/orderers/orderer0.xinhe.com/msp/tlscacerts/tls-ca-immediate-xinhe-com-7055.pem

#使用以下命令来更新锚节点（在org2容器上操作）
peer channel update -o orderer0.xinhe.com:7050 -c mychannel -f ./channel-artifacts/Org2MSPanchors.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/xinhe.com/orderers/orderer0.xinhe.com/msp/tlscacerts/tls-ca-immediate-xinhe-com-7055.pem

# 显示通道中的 Peer 节点信息，包括它们的 MSP ID、gRPC 服务监听地址和身份证书。
discover peers --channel mychannel --peerTLSCA /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.xinhe.com/users/Admin\@org1.xinhe.com/msp/tlscacerts/tlsca.org1.xinhe.com-cert.pem --userKey /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.xinhe.com/users/Admin@org1.xinhe.com/msp/keystore/priv_sk --userCert /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.xinhe.com/users/Admin\@org1.xinhe.com/msp/signcerts/cert.pem --MSP Org1MSP --server peer0.org1.xinhe.com:7051

cp channel-artifacts/hyperledger-fabric-contract-java-demo.tar.gz ./

docker run --name ui -d -p 9000:9000 --privileged -v /var/run/docker.sock:/var/run/docker.sock uifd/ui-for-docker

# 打包链码
peer lifecycle chaincode package hyperledger-fabric-contract-java-demo.tar.gz --path ./channel-artifacts/hyperledger-fabric-contract-java/ --lang java --label hyperledger-fabric-contract-java-demo_1

# 安装链码
peer lifecycle chaincode install channel-artifacts/hyperledger-fabric-contract-java-demo.tar.gz

# 批准链码定义 Org1和Org2的虚拟机中都要进行以下操作
peer lifecycle chaincode approveformyorg --channelID mychannel --name hyperledger-fabric-contract-java-demo --version 1.0 --init-required --package-id hyperledger-fabric-contract-java-demo_1:ed2f2e83b516ca0070dfa42a01cab096c0d783b939401aa57b275cdec6146359 --sequence 2 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/xinhe.com/orderers/orderer0.xinhe.com/msp/tlscacerts/tls-ca-immediate-xinhe-com-7055.pem

#使用以下命令查看链码是否就绪（Org1和Org2的虚拟机中都要进行以下操作）。
peer lifecycle chaincode checkcommitreadiness --channelID mychannel --name hyperledger-fabric-contract-java-demo --version 1.0 --init-required --sequence 2 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/xinhe.com/orderers/orderer0.xinhe.com/msp/tlscacerts/tls-ca-immediate-xinhe-com-7055.pem --output json

#使用以下命令提交链码（在组织一或者组织二上）。
peer lifecycle chaincode commit -o orderer0.xinhe.com:7050 --channelID mychannel --name hyperledger-fabric-contract-java-demo --version 1.0 --sequence 2 --init-required --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/xinhe.com/orderers/orderer0.xinhe.com/msp/tlscacerts/tls-ca-immediate-xinhe-com-7055.pem --peerAddresses peer0.org1.xinhe.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.xinhe.com/peers/peer0.org1.xinhe.com/tls/ca.crt --peerAddresses peer0.org2.xinhe.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.xinhe.com/peers/peer0.org2.xinhe.com/tls/ca.crt

peer lifecycle chaincode querycommitted --channelID mychannel --name hyperledger-fabric-contract-java-demo --cafile /etc/hyperledger/fabric/crypto-config/ordererOrganizations/xinhe.com/orderers/orderer0.xinhe.com/msp/tlscacerts/tls-ca-immediate-xinhe-com-7055.pem

#使用以下命令将链码初始化，连码只能初始化一次
peer chaincode invoke -o orderer0.xinhe.com:7050 --isInit --ordererTLSHostnameOverride orderer0.xinhe.com --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/xinhe.com/orderers/orderer0.xinhe.com/msp/tlscacerts/tls-ca-immediate-xinhe-com-7055.pem -C mychannel -n hyperledger-fabric-contract-java-demo --peerAddresses peer0.org1.xinhe.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.xinhe.com/peers/peer0.org1.xinhe.com/tls/ca.crt --peerAddresses peer0.org2.xinhe.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.xinhe.com/peers/peer0.org2.xinhe.com/tls/ca.crt -c '{"function":"createCat","Args":["cat-0" , "tom" ,  "3" , "蓝色" , "大懒猫"]}'

# 添加数据
peer chaincode invoke -o orderer3.xinhe.com:7350 --ordererTLSHostnameOverride orderer3.xinhe.com --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/xinhe.com/msp/tlscacerts/tls-ca-immediate-xinhe-com-7055.pem -C mychannel -n hyperledger-fabric-contract-java-demo --peerAddresses peer0.org1.xinhe.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.xinhe.com/peers/peer0.org1.xinhe.com/tls/ca.crt --peerAddresses peer0.org2.xinhe.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.xinhe.com/peers/peer0.org2.xinhe.com/tls/ca.crt --peerAddresses peer0.org3.xinhe.com:7251 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.xinhe.com/peers/peer0.org3.xinhe.com/tls/ca.crt  -c '{"function":"createCat","Args":["cat-1" , "tom2" ,  "5" , "1绿色" , "1大绿猫"]}'

--peerAddresses peer0.org3.xinhe.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.xinhe.com/peers/peer0.org3.xinhe.com/tls/ca.crt

#使用以下命令查询数据。
peer chaincode query -C mychannel -n sacc -c '{"Args":["query","a"]}'

peer chaincode query -C mychannel -n hyperledger-fabric-contract-java-demo -c '{"Args":["queryCat" , "cat-6"]}'

官方											新赫

hyperledger/fabric-orderer:2.4.6				xinhe/xinhe-orderer:2.4.6
hyperledger/fabric-peer:2.4.6					xinhe/xinhe-peer:2.4.6
hyperledger/fabric-tools:2.4.6					xinhe/xinhe-tools:2.4.6
couchdb:2.1.1									xinhe/couchdb:2.1.1
hyperledger/explorer-db:latest					xinhe/explorer-db:latest
hyperledger/explorer:1.1.5						xinhe/explorer:1.1.5

58.249.1.220:2000/fabric/xinhe/fabric-peer
# docker推送镜像到harbor

​```bash
# docker tag 镜像ID:版本号 harbor地址端口/库名/自定义镜像名
docker tag docker.io/hyperledger/explorer-db:latest 192.168.1.200:85/fabric/xinhe/explorer-db:latest

# 推送镜像
docker push 192.168.1.200:85/fabric/xinhe/explorer-db:latest
```
```

# 组织中添加peer节点

1. 加入通道
2. 安装链码
3. 使用链码

# Fabric网络中添加联盟

在fabric中联盟不能为空，必须包含一个组织机构，所有在创建联盟的时候必须有一个组织机构，能够添加进去，

fabric中的联盟和通道是一对一的关系，联盟必须和通道channel并存，而所有的配置都是记录在区块中的，包括有哪些联盟，有哪些org，所以要添加联盟就必须修改区块中的数据，更新配置。

向`configtx.yaml`的`Section: Profile`中创建Orderer创世区块的配置profile中添加新联盟（以TestConsortium联盟为例）

​```yaml
TwoOrgsOrdererGenesis:
  <<: *ChannelDefaults
  Orderer:
     <<: *OrdererDefaults
     Organizations:
        - *OrdererOrg
     Capabilities:
        <<: *OrdererCapabilities
  Consortiums:
     SampleConsortium:
     	Organizations:
           - *Org1
           - *Org2
     TestConsortium:
     	Organizations:
           - *Org1

```

- 以JSON格式输出**新联盟**的配置材料

```bash
# 生成包含新联盟的新创世区块
configtxgen -profile TwoOrgsOrdererGenesis -channelID byfn-sys-channel -outputBlock ./channel-artifacts/sys-channel.block
# 将其内容转换成JSON并抽取出新联盟的配置材料
configtxlator proto_decode --input ./channel-artifacts/sys-channel.block --type common.Block | jq .data.data[0].payload.data.config.channel_group.groups.Consortiums.groups.TestConsortium > ./channel-artifacts/TestConsortium.json

```

1. 获取系统通道的创世区块
    - （可选）设置了`ORDERER_CA`变量：
      
        ```
        docker exec -it cli bash
        export ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
        
        ```
        
    - 切换到`OrdererOrgs`的admin用户
      
        ```
        export CORE_PEER_LOCALMSPID="OrdererMSP"
        export CORE_PEER_TLS_ROOTCERT_FILE=$ORDERER_CA
        export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/users/Admin@example.com/msp
        
        ```
        
        原因：系统通道的相关操作必须由`OrdererOrgs`的admin用户来执行
        
    - 使用`peer channel fetch`命令获取系统通道的创世区块
      
        ```
        peer channel fetch config ./channel-artifacts/sys_config_block.pb -o orderer.example.com:7050 -c byfn-sys-channel --tls --cafile $ORDERER_CA
        
        ```
        
        其中`-c`参数是`--channelID`的简写，此处需要使用系统通道ID，即在调用`configtxgen`创建orderer创世区块时所指定的channelID。
        
    - 将创世区块中的内容转换成JSON并对其进行修剪
      
        ```
        exit
        configtxlator proto_decode --input ./channel-artifacts/sys_config_block.pb --type common.Block | jq .data.data[0].payload.data.config > ./channel-artifacts/sys_config.json
        
        ```
        
    - 将新联盟TestConsortium配置定义`TestConsortium.json`添加到channel的`Consortiums`的`TestConsortium`中，并将其写入`sys_updated_config.json`
      
        ```
        jq -s '.[0] * {"channel_group":{"groups":{"Consortiums":{"groups": {"TestConsortium": .[1]}}}}}' ./channel-artifacts/sys_config.json ./channel-artifacts/TestConsortium.json >& ./channel-artifacts/sys_updated_config.json
        
        ```
        
    - **创建Config Update**
        - 配置增量计算
          
            ```
            # 将原始的配置sys_config.json编码成protobuf
            configtxlator proto_encode --input ./channel-artifacts/sys_config.json --type common.Config --output ./channel-artifacts/sys_config.pb
            # 将更新后的配置sys_updated_config.json编码成protobuf
            configtxlator proto_encode --input ./channel-artifacts/sys_updated_config.json --type common.Config --output ./channel-artifacts/sys_updated_config.pb
            # 配置增量计算
            configtxlator compute_update --channel_id byfn-sys-channel --original ./channel-artifacts/sys_config.pb --updated ./channel-artifacts/sys_updated_config.pb --output ./channel-artifacts/sys_config_update.pb
            
            ```
            
        - Generating config update and wrapping it in an envelope
          
            ```
            # 将sys_config_update.pb编码成json
            configtxlator proto_decode --input ./channel-artifacts/sys_config_update.pb --type common.ConfigUpdate | jq . > ./channel-artifacts/sys_config_update.json
            # 生成sys_config_update_in_envelope.json
            echo '{"payload":{"header":{"channel_header":{"channel_id":"byfn-sys-channel", "type":2}},"data":{"config_update":'$(cat ./channel-artifacts/sys_config_update.json)'}}}' | jq . > ./channel-artifacts/sys_config_update_in_envelope.json
            # 将sys_config_update_in_envelope.json编码成protobuf
            configtxlator proto_encode --input ./channel-artifacts/sys_config_update_in_envelope.json --type common.Envelope --output ./channel-artifacts/sys_config_update_in_envelope.pb
            
            ```
        
    - **向orderer发送配置更新（<u>必须使用OrdererOrg的admin用户</u>）**
      
        ```
        docker exec -it cli bash
        
        export ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
        export CORE_PEER_LOCALMSPID="OrdererMSP"
        export CORE_PEER_TLS_ROOTCERT_FILE=$ORDERER_CA
        export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/users/Admin@example.com/msp
        
        peer channel update -f ./channel-artifacts/sys_config_update_in_envelope.pb -c byfn-sys-channel -o orderer.example.com:7050 --tls true --cafile $ORDERER_CA
        
        ```
        

（可选）测试联盟，创建channel，只要是联盟的成员的admin都可以创建channel

编辑configtx.yaml找到channel创建的配置文件的位置，编写channel配置文件

```yaml
TestChannel:
        Consortium: TestConsortium
        Application:
            <<: *ApplicationDefaults
            Organizations:
                - *Org1
            Capabilities:
                <<: *ApplicationCapabilities

```

```bash
configtxgen -profile TestChannel -outputCreateChannelTx ./channel-artifacts/testchannel.tx -channelID testchannel
```

```
docker exec -it cli bash

```

此处我们testConsortium里面的是org1，所有无需切换环境变量，如果是其他org,则必须切换到该org的admin用户

```
export ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

peer channel create -o orderer.example.com:7050 -c testchannel -f ./channel-artifacts/testchannel.tx --tls --cafile $ORDERER_CA

peer channel fetch 0 testchannel.block -o orderer.example.com:7050 -c testchannel --tls --cafile $ORDERER_CA

peer channel join -b testchannel.block
peer channel list #查看

export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=peer1.org1.example.com:7051

peer channel join -b testchannel.block
peer channel list #查看

```

# Fabric网络中添加排序节点

向Raft集群添加新节点的操作如下（官方解释）:

1.  通过通道配置更新事务将新节点的TLS证书添加到通道中。注意:新节点必须加入到系统通道中，才能加入到一个或多个应用通道中。
2. 从系统通道的一部分orderer节点获取系统通道的最新配置块。
3. 通过检查获取的配置块是否包含(即将添加的)添加节点的证书，确保将要添加的节点是系统通道的一部分。
4. 使用General中的配置块路径启动新的Raft节点。GenesisFile配置参数。
5. 等待Raft节点为其证书已添加到的所有通道从现有节点复制块。完成此步骤后，节点开始为通道提供服务。
6. 将新添加的Raft节点的端点添加到所有通道的通道配置。

操作流程：

1. 生成orderer证书
2. 获取系统通道配置
3. 修改系统通道配置，将新增的orderer证书添加到系统通道配置
4. 提交修改后的系统通道配置
5. 获取应用通道配置
6. 修改原因通道配置，修改内容与系统通道配置一致
7. 提交应用通道配置
8. 将新增的orderer节点添加到所有应用通道

注意事项：

1. 需要使用orderer管理员的身份进行获取系统通道的配置文件：

例子

```bash
# orderer----------------
export CORE_PEER_LOCALMSPID=OrdererMSP
export CORE_PEER_ADDRESS=orderer0.xinhe.com:7050
CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/xinhe.com/orderers/orderer0.xinhe.com/tls/server.crt
CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/xinhe.com/orderers/orderer0.xinhe.com/tls/server.key
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/xinhe.com/orderers/orderer0.xinhe.com/tls/ca.crt
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/xinhe.com/users/Admin\@xinhe.com/msp/
```

```bash
#1 获取系统通道配置文件:
peer channel fetch config config_block.pb -o orderer0.xinhe.com:7050 -c mychannel --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/xinhe.com/orderers/orderer0.xinhe.com/msp/tlscacerts/tlsca.xinhe.com-cert.pem

#2 解码该配置文件:
configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config > channel-artifacts/config.json

#3 将证书文件添加到配置文件中
#退出容器，可以在channel-artifacts文件内找到config.json文件。将该文件复制一份并在channel-artifacts文件夹下保存为update_config.json,使用编辑工具打开，并搜索.example.com字段如下：
"Endpoints": {
    "mod_policy": "Admins",
    "value": {
      "addresses": [
        "orderer0.xinhe.com:7050",
        "orderer1.xinhe.com:7150",
        "orderer2.xinhe.com:7250",
        "orderer3.xinhe.com:7350"
      ]
    },
    "version": "0"
  },
# 以及匹配到的第二部分的字段:
 {
    "client_tls_cert": "一连串的字符串",
    "host": "orderer1.example.com",
    "port": 7050,
    "server_tls_cert": "一连串的字符串"
  }
  
# 以及匹配到的第三部分的字段:
  "OrdererAddresses": {
        "mod_policy": "/Channel/Orderer/Admins",
        "value": {
          "addresses": [
            "orderer1.example.com:7050",
            "orderer2.example.com:8050",
            "orderer3.example.com:9050",
            "orderer4.example.com:10050"
          ]
        },
        "version": "0"
    }
	

# 在字段一部分，需要将我们生成的新的节点的证书添加上去，其中证书文件地址为:
crypto-config/ordererOrganizations/example.com/orderers/orderer5.example.com/tls/server.crt
# 使用BASE64转码:
cat crypto-config/ordererOrganizations/aoa.com/orderers/orderer3.aoa.com/tls/server.crt | base64 > cert.txt

# 在update_config.json文件中字段一的部分下面按照字段一的格式添加相同的代码块，并进行修改：
# 将cert.txt文件中的内容复制到字段一的client_tls_cert,server_tls_cert对应部分，并修改host对应部分为orderer5.example.com，port为11050.

#4 更新配置文件
#对原有的配置文件与更新的配置文件进行编码:
configtxlator proto_encode --input channel-artifacts/config.json --type common.Config > channel-artifacts/config.pb
configtxlator proto_encode --input channel-artifacts/update_config.json --type common.Config > channel-artifacts/config_update.pb

#5 计算出两个文件的差异:
configtxlator compute_update --channel_id mychannel --original channel-artifacts/config.pb --updated channel-artifacts/config_update.pb > channel-artifacts/updated.pb

#6 对该文件进行解码，并添加用于更新配置的头部信息:
configtxlator proto_decode --input channel-artifacts/updated.pb --type common.ConfigUpdate > channel-artifacts/updated.json
echo '{"payload":{"header":{"channel_header":{"channel_id":"mychannel", "type":2}},"data":{"config_update":'$(cat channel-artifacts/updated.json)'}}}' | jq . > channel-artifacts/updated_envelope.json

#7 编码为Envelope格式的文件:
configtxlator proto_encode --input channel-artifacts/updated_envelope.json --type common.Envelope > channel-artifacts/updated_envelope.pb

#8 对该文件进行签名操作，用于更新配置:
peer channel signconfigtx -f channel-artifacts/updated_envelope.pb

#9 提交更新通道配置交易:
peer channel update -f channel-artifacts/updated_envelope.pb -c mychannel -o orderer0.xinhe.com:7050 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/xinhe.com/users/Admin\@xinhe.com/msp/tlscacerts/tlsca.xinhe.com-cert.pem

# 如果没有错误的话，新的Orderer节点证书已经成功添加到网络配置中，接下来可以启动新的节点了: 
# 注意新增的orderer需要绑定最新的创世区块配置文件
#10 从系统通道中获取最新的创世区块配置文件
peer channel fetch config channel-artifacts/genesis_updated.block -o orderer0.xinhe.com:7050 -c fabric-channel --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/xinhe.com/users/Admin\@xinhe.com/msp/tlscacerts/tlsca.xinhe.com-cert.pem
```

将系统通道配置添加后，要拉取最新的系统配置文件，新orderer需要携带启动

![Untitled](Fabric%E7%BD%91%E7%BB%9C%E8%BF%90%E7%BB%B4%208a29e56285354c21a872bb7b7b3297d7/Untitled.png)

# Fabric通道中添加组织

1. 生成组织证书
2. 修改confgitx.yaml文件，添加新组织配置，并通过configtxgen 命令生成组织更新文件
3. 获取通道配置文件
4. 将新组织配置添加到通道配置中
5. 通道内组织签名
6. 提交通道配置
7. 将新组织添加到联盟中

```bash
#1 生成证书
cryptogen generate --config=./org3-crypto.yaml

#2 生成org3的json字符串
configtxgen -printOrg Org3MSP > ./channel-artifacts/org3.json

#3 拷贝order证书到org3目录下
cp -r crypto-config/ordererOrganizations org3-artifacts/crypto-config/
docker exec -it cli bash

#4 获取mychannel的配置区块
peer channel fetch config config_block.pb -o orderer0.xinhe.com:7051 -c onechannel --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/xinhe.com/orderers/orderer0.xinhe.com/msp/tlscacerts/tlsca.xinhe.com-cert.pem

#5 转为json
configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config > config.json

#6 将org3加入到此json中
jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups": {"Org3MSP":.[1]}}}}}' config.json ./channel-artifacts/org3.json > modified_config.json

# 删除组织
# jq 'del(.channel_group.groups.Application.groups.Org3)'  ./channel-artifacts/config.json > ./channel-artifacts/modified_config.json

#7 将旧配置文件转为pb
configtxlator proto_encode --input config.json --type common.Config --output config.pb

#8 将新配置文件转为pb
configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb

#9 计算pb之间的增量
configtxlator compute_update --channel_id mychannel --original config.pb --updated modified_config.pb --output org3_update.pb

#10 将增量文件转为json
configtxlator proto_decode --input org3_update.pb --type common.ConfigUpdate | jq . > org3_update.json

#11 将增量文件添加header信息
echo '{"payload":{"header":{"channel_header":{"channel_id":"mychannel", "type":2}},"data":{"config_update":'$(cat org3_update.json)'}}}' | jq . > org3_update_in_envelope.json

#12 将增量文件转为pb
configtxlator proto_encode --input org3_update_in_envelope.json --type common.Envelope --output ./channel-artifacts/org3_update_in_envelope.pb

#13 组织签名
# org1签名
peer channel signconfigtx -f ./channel-artifacts/org3_update_in_envelope.pb
# peer channel signconfigtx -f ./channel-artifacts/org3_update_in_envelope.pb -o ./channel-artifacts/org3_update_in_envelope_signed.pb


# org2签名
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.xinhe.com/peers/peer0.org2.xinhe.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.xinhe.com/users/Admin@org2.xinhe.com/msp
export CORE_PEER_ADDRESS=peer0.org2.xinhe.com:7051

#14 上传新配置
peer channel update -f ./channel-artifacts/org3_update_in_envelope.pb -c mychannel -o orderer0.xinhe.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/xinhe.com/orderers/orderer0.xinhe.com/msp/tlscacerts/tlsca.xinhe.com-cert.pem
# peer channel update -f mychannel-addorg-Org3-signed.pb -c mychannel -o orderer.example.com:7050 --tls --cafile $ORDERER_CA

# 编写docker-compose文件
docker-compose -f docker-compose-org3.yaml up -d

# 进入容器
docker exec -it Org3cli bash

# 获取第0个区块
peer channel fetch 0 mychannel.block -o orderer0.xinhe.com:7050 -c mychannel --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/xinhe.com/orderers/orderer0.xinhe.com/msp/tlscacerts/tlsca.xinhe.com-cert.pem

# 加入到channel里边
peer channel join -b mychannel.block

# 切换到另一peer
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org3.xinhe.com/peers/peer1.org3.xinhe.com/tls/ca.crt && export CORE_PEER_ADDRESS=peer1.org3.xinhe.com:7051

# 加入到channel里边
peer channel join -b mychannel.block

# 配置锚节点（可选）
peer channel fetch config config_block.pb -o orderer0.xinhe.com:7050 -c mychannel --tls --cafile $ORDERER_CA

configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config > config.json

jq '.channel_group.groups.Application.groups.Org3MSP.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "peer0.org3.xinhe.com","port": 11051}]},"version": "0"}}' config.json > modified_anchor_config.json

configtxlator proto_encode --input config.json --type common.Config --output config.pb

configtxlator proto_encode --input modified_anchor_config.json --type common.Config --output modified_anchor_config.pb

configtxlator compute_update --channel_id $CHANNEL_NAME --original config.pb --updated modified_anchor_config.pb --output anchor_update.pb

configtxlator proto_decode --input anchor_update.pb --type common.ConfigUpdate | jq . > anchor_update.json

echo '{"payload":{"header":{"channel_header":{"channel_id":"mychannel", "type":2}},"data":{"config_update":'$(cat anchor_update.json)'}}}' | jq . > anchor_update_in_envelope.json

configtxlator proto_encode --input anchor_update_in_envelope.json --type common.Envelope --output anchor_update_in_envelope.pb

# 所有新组织Admin用户提交
peer channel update -f anchor_update_in_envelope.pb -c mychannel -o orderer0.xinhe.com:7050 --tls --cafile $ORDERER_CA
```

# Fabric联盟中添加组织

- 初始的时候 部署区块链在configtx.yaml 文件的Profiles: 策略配置中联盟 只配置了Org1 和Org2 当以全新组织Org3 去创建通道（当然这里是指org1 和 org2 不加入新通道） 会报错：提示org3 不是联盟成员 没有权限创建 此篇文章教会怎么解决问题

![Untitled](Fabric%E7%BD%91%E7%BB%9C%E8%BF%90%E7%BB%B4%208a29e56285354c21a872bb7b7b3297d7/Untitled%201.png)

```bash
#1. 修改configtx.yaml文件，并将有关Org3MSP的配置输出到json文件中
configtxgen -printOrg Org3MSP > ./channel-artifacts/org3.json

#2. 执行获取配置创世区块命令
# 需要使用orderer admin身份获取
peer channel fetch config config_block.pb -o orderer0.xinhe.com:7050 -c  fabric-channel --tls  --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/xinhe.com/orderers/orderer0.xinhe.com/msp/tlscacerts/tlsca.xinhe.com-cert.pem

#解析配置块 获取配置信息
configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config >config.json

#3. 向联盟中添加组织
此处Org3MSP根据自己需求的组织MSPID更改相对应名称 这里有注意地方 SampleConsortium是文章开头要记住地方 可能有改动的化 这里也需要改动

 jq -s '.[0] * {"channel_group":{"groups":{"Consortiums":{"groups":{"SampleConsortium":{"groups":{"Org3MSP":.[1]}}}}}}}' config.json channel-artifacts/org3.json >modified_config.json

#4. 将上面两步产生的 json文件 重新编码成pb文件
configtxlator proto_encode --input config.json --type common.Config --output config.pb
configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb

#5. 计算两个pb文件差异 输出新的pb文件
configtxlator compute_update --channel_id fabric-channel --original config.pb --updated modified_config.pb --output sys_Org3MSP_update.pb

#6. 把上一步pb转json 为了封装信封使用   wd
configtxlator proto_decode --input sys_Org3MSP_update.pb --type common.ConfigUpdate | jq . > sys_Org3MSP_update.json

#7. 封装信封
echo '{"payload":{"header":{"channel_header":{"channel_id":"'fabric-channel'", "type":2}},"data":{"config_update":'$(cat sys_Org3MSP_update.json)'}}}' | jq . >sys_Org3MSP_update_in_envelope.json

#8. json 转pb 最后生成准备提交文件
configtxlator proto_encode --input sys_Org3MSP_update_in_envelope.json --type common.Envelope --output sys_Org3MSP_update_in_envelope.pb

#9. 提交新配置
peer channel update -f sys_Org3MSP_update_in_envelope.pb -c fabric-channel -o orderer0.xinhe.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/xinhe.com/orderers/orderer0.xinhe.com/msp/tlscacerts/tlsca.xinhe.com-cert.pem
```

# ****fabric 用户证书吊销操作流程****

```bash
#1 使用peer channel fetch命令获取应用通道的信息
 peer channel fetch config ./channel-artifacts/config_block.pb -o orderer0.xinhe.com:7050 -c mychannel --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/xinhe.com/orderers/orderer1.xinhe.com/msp/tlscacerts/tlsca.xinhe.com-cert.pem
 
#2 将通道文件中的内容转换成JSON并对其进行修剪
 configtxlator proto_decode --input ./channel-artifacts/config_block.pb --type common.Block | jq .data.data[0].payload.data.config > ./channel-artifacts/sys_config.json

#3 cp ./channel-artifacts/sys_config.json ./channel-artifacts/sys_config_new.json

#4 将sys_config_new.json中的 channel_group.groups.Application.groups.ShenzhenMSP下的revocation_list字段值改为CRL的base64编码字符串
 
#5 将上面两步产生的 JSON文件 重新编码成PB文件
 configtxlator proto_encode --input ./channel-artifacts/sys_config.json --type common.Config --output ./channel-artifacts/sys_config.pb
 
configtxlator proto_encode --input ./channel-artifacts/sys_config_new.json --type common.Config --output ./channel-artifacts/sys_modified_config.pb

#6 计算两个PB文件差异 输出新的PB文件
configtxlator compute_update --channel_id mychannel --original ./channel-artifacts/sys_config.pb --updated ./channel-artifacts/sys_modified_config.pb --output ./channel-artifacts/sys_crl_update.pb

#7 把上一步PB转JSON 为了封装信封使用
configtxlator proto_decode --input ./channel-artifacts/sys_crl_update.pb --type common.ConfigUpdate | jq . > sys_crl_update.json

#8 封装信封
echo '{"payload":{"header":{"channel_header":{"channel_id":"'mychannel'", "type":2}},"data":{"config_update":'$(cat sys_crl_update.json)'}}}' | jq . > ./channel-artifacts/sys_crl_update_in_envelope.json

#9  JSON 转PB 最后生成准备提交文件
configtxlator proto_encode --input ./channel-artifacts/sys_crl_update_in_envelope.json --type common.Envelope --output ./channel-artifacts/sys_crl_update_in_envelope.pb

#10 完成最后签名的组织可执行交易提案至order
peer channel update -f ./channel-artifacts/sys_crl_update_in_envelope.pb -c mychannel -o orderer0.xinhe.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/xinhe.com/orderers/orderer1.xinhe.com/msp/tlscacerts/tlsca.xinhe.com-cert.pem
```

![Untitled](Fabric%E7%BD%91%E7%BB%9C%E8%BF%90%E7%BB%B4%208a29e56285354c21a872bb7b7b3297d7/Untitled%202.png)

提交成功如下图

![Untitled](Fabric%E7%BD%91%E7%BB%9C%E8%BF%90%E7%BB%B4%208a29e56285354c21a872bb7b7b3297d7/Untitled%203.png)

# Fabric 无系统通道配置

[Hyperledger Fabric2.3创建通道（无系统通道）文档翻译_寒木的博客-程序员ITS404_fabric通道 - 程序员ITS404](https://www.its404.com/article/u010145988/112388107)

Fabric无系统通道，以及删除系统通道参考文档

## configtx.yaml

```yaml
---
# 重复的内容在 YAML 中可以使用&来完成锚点定义，使用*来完成锚点引用
# 在这六个部分中，Profile 部分，主要是引用其余五个部分的参数。configtxgen 通过调用 Profile 参数，可以实现生成特定的区块文件。
#组织机构配置：定义了不同的组织标志，这些标志将在 Profile 部分被引用。
Organizations:       #组织信息

    - &OrdererOrg    #配置orderer的信息

        Name: OrdererOrg    # 组织名称
        ID: OrdererMSP      # 组织ID，ID是引用组织的关键
        MSPDir: ./crypto-config/ordererOrganizations/xinhe.com/msp    # 组织的MSP证书路径
        # 定义本层级的组织策略，其权威路径为 /Channel/<Application|Orderer>/<OrgName>/<PolicyName>
        Policies:    # 组织策略
            Readers:     #可读
                Type: Signature # 策略类型：签名策略，验证签名数据是否符合规则。
                Rule: "OR('OrdererMSP.member')"       #具体策略：允许OrdererMSP中所有member读操作
                # Rule: "OR('SampleOrg.admin', 'SampleOrg.peer', 'SampleOrg.client')"
            Writers:    #可写
                Type: Signature
                Rule: "OR('OrdererMSP.member')"
            Admins:    #admin
                Type: Signature
                Rule: "OR('OrdererMSP.admin')"
        # orderer节点列表，用来推送事务和接收块
        # 定义排序节点（可多个），客户端和对等点可以分别连接到这些orderer以推送transactions和接收区块。
        OrdererEndpoints:
            - orderer0.xinhe.com:7050
            - orderer1.xinhe.com:7150
            - orderer2.xinhe.com:7250

    #其中策略中包含以下的用户身份
    #Org1.admin : org1的admin用户
    #Org1.client： org1中的任意client（admin、user）
    #Org1.peer：org1中的任意peer
    #Org1.member: 以上三种任意身份都可以

    - &Org1      #配置组织一的信息

        Name: Org1MSP   #定义组织一的名称
        ID: Org1MSP     #定义组织一的ID
        MSPDir: ./crypto-config/peerOrganizations/org1.xinhe.com/msp    #指定MSP的文件目录
        Policies:   #定义相关策略
            Readers:    #可读
                Type: Signature
                Rule: "OR('Org1MSP.admin', 'Org1MSP.peer', 'Org1MSP.client')"   #Org1MSP中的admin，peer，client均可进行读操作
            Writers:    #可写
                Type: Signature
                Rule: "OR('Org1MSP.admin', 'Org1MSP.client')"    #Org1MSP中的admin，client均可进行读操作
            Admins:     #admin
                Type: Signature
                Rule: "OR('Org1MSP.admin')"
            Endorsement:
                Type: Signature
                Rule: "OR('Org1MSP.peer')"
        #指定Org1的锚节点，只有锚节点可以与另一个组织进行通信
        AnchorPeers:
            - Host: peer0.org1.xinhe.com  # 锚节点的host地址
              Port: 7051        # 锚节点开放的端口号

    - &Org2

        Name: Org2MSP
        ID: Org2MSP
        MSPDir: ./crypto-config/peerOrganizations/org2.xinhe.com/msp
        Policies:
            Readers:
                Type: Signature
                Rule: "OR('Org2MSP.admin', 'Org2MSP.peer', 'Org2MSP.client')"
            Writers:
                Type: Signature
                Rule: "OR('Org2MSP.admin', 'Org2MSP.client')"
            Admins:
                Type: Signature
                Rule: "OR('Org2MSP.admin')"
            Endorsement:
                Type: Signature
                Rule: "OR('Org2MSP.peer')"

        AnchorPeers:
            - Host: peer0.org2.xinhe.com
              Port: 7051

    - &Org3

        Name: Org3MSP
        ID: Org3MSP
        MSPDir: ./crypto-config/peerOrganizations/org3.xinhe.com/msp
        Policies:
            Readers:
                Type: Signature
                Rule: "OR('Org3MSP.admin', 'Org3MSP.peer', 'Org3MSP.client')"
            Writers:
                Type: Signature
                Rule: "OR('Org3MSP.admin', 'Org3MSP.client')"
            Admins:
                Type: Signature
                Rule: "OR('Org3MSP.admin')"
            Endorsement:
                Type: Signature
                Rule: "OR('Org3MSP.peer')"

        AnchorPeers:
            - Host: peer0.org3.xinhe.com
              Port: 7251

#该部分用户定义 Fabric 网络的功能。
#Capabilities段定义了fabric程序要加入网络所必须支持的特性。
#例如，如果添加了一个新的MSP类型，那么更新的程序可能会根据该类型识别并验证签名，
#    但是老版本的程序就没有办法验证这些交易。这可能导致不同版本的fabric程序中维护的世界状态不一致。
##########################################################################################
#Capabilities配置段，capability直接翻译是能力，这里可以理解为对Fabric网络中组件版本的控制， 通过版本进#而控制相应的特性。新更新的特性旧版本的组件不支持，
#    就可能无法验证或提交transaction从而导致不同版本的节点#上有不同的账本，因此使用Capabilities来使不支持特性的旧组件终止处理transaction直到其更新升级Channel表#示orderers和peers同时都要满足，
#    Orderer只需要orderers满足，Application只需要peers满足即可。
##########################################################################################
Capabilities:   #这一区域主要是定义版本的兼容情况
    # Channel配置同时应用于orderer节点与peer节点，并且必须被两种节点同时支持
    # 将该配置项设置为ture表明要求节点具备该能力,false则不要求该节点具备该能力
    Channel: &ChannelCapabilities

        V2_0: true  # 要求Channel上的所有Orderer节点和Peer节点达到v2.0.0或更高版本

    # Orderer功能仅适用于orderers，可以安全地操作，而无需担心升级peers
    # 将该配置项设置为ture表明要求节点具备该能力,false则不要求该节点具备该能力
    Orderer: &OrdererCapabilities

        V2_0: true  # 要求所有Orderer节点升级到v2.0.0或更高版本

    # 应用程序功能仅适用于Peer网络，可以安全地操作，而无需担心升级或更新orderers
    # 将该配置项设置为ture表明要求节点具备该能力,false则不要求该节点具备该能力
    Application: &ApplicationCapabilities   # 指定初始加入通道的组织

        V2_0: true  # # Application配置仅应用于对等网络，不需考虑排序节点的升级

#  应用配置：Application配置段用来定义要写入创世区块或配置交易的应用参数。
#  该部分定义了交易配置相关的值，以及包含和创世区块相关的值。
#Application 定义了应用内的访问控制策略和参与组织。
Application: &ApplicationDefaults

    # Organizations配置列出参与到网络中的机构清单
    # 默认为空，在 Profiles 中定义
    Organizations:

    # 定义本层级的应用控制策略，其权威路径为 /Channel/Application/<PolicyName>
    Policies:
        Readers:
            Type: ImplicitMeta  # 策略类型：隐含元策略。在SignaturePolicy的基础上 支持大多数组织管理员，这种策略只适合于通道管理
            Rule: "ANY Readers"
        Writers:
            Type: ImplicitMeta
            Rule: "ANY Writers"
        Admins:
            Type: ImplicitMeta
            Rule: "MAJORITY Admins"
        LifecycleEndorsement:
            Type: ImplicitMeta
            Rule: "MAJORITY Endorsement"
        Endorsement:
            Type: ImplicitMeta
            Rule: "MAJORITY Endorsement"

        # Capabilities配置描述应用层级的能力需求，这里直接引用
        # 前面Capabilities配置段中的ApplicationCapabilities配置项
    Capabilities:
        <<: *ApplicationCapabilities

#排序节点配置：定义了排序服务的相关参数，这些参数将用于创建创世区块。
#Orderer配置段用来定义要编码写入创世区块或通道交易的排序节点参数
#    定义了排序服务的相关参数，这些参数将用于创建创世区块或交易。
Orderer: &OrdererDefaults

    # 排序节点类型用来指定要启用的排序节点实现，不同的实现对应不同的共识算法。
    # 目前可用的类型为：
#    solo：在Hyperledger Fabric中的solo模式的共识算法，是最简单的一种共识算法，只有一个排序节点（order）接收客户端peer节点消息，并完成排序，按照order节点的排序结果进行生成区块和上链处理。此种模式只能在测试环境中使用，不适合生产环境大规模使用。
#    kafka：由一组orderer节点组成排序服务节点，与Kafka集群进行对接，利用Kafka完成消息的共识功能。
#       客户端peer节点向Orderer节点集群发送消息后，经过Orderer节点组的背书后，封装成Kafka消息格式，然后发往Kafka集群，
#       完成交易信息的统一排序。如果联盟链中有多个channel，在Kafka中实现就是按照每个channel一个topic的设定，每个channel都有一条链。
#    etcdraft：在Raft的机制下最终只有一个Orderer节点进行排序，所以其性能非常的高，并不需要多个节点之间同步状态的拜占庭问题。当领导节点存活的情况下，其他Orderer节点的功能相当于Commit peer的功能，只是不断的同步区块文件，维持网络内部的稳定性，当领导节点宕机之后，及时进行二次的重新选举，保障交易可以正常完成。
    OrdererType: etcdraft
    # Orderer服务地址列表,这个地方很重要，一定要配正确
    Addresses:
        - orderer0.xinhe.com:7050
        - orderer1.xinhe.com:7150
        - orderer2.xinhe.com:7250
    # 定义了 etcdRaft 排序类型被选择时的配置
    EtcdRaft:
        Consenters:  # 定义投票节点
            - Host: orderer0.xinhe.com
              Port: 7050
              ClientTLSCert: ./crypto-config/ordererOrganizations/xinhe.com/orderers/orderer0.xinhe.com/tls/server.crt
              ServerTLSCert: ./crypto-config/ordererOrganizations/xinhe.com/orderers/orderer0.xinhe.com/tls/server.crt
            - Host: orderer1.xinhe.com
              Port: 7150
              ClientTLSCert: ./crypto-config/ordererOrganizations/xinhe.com/orderers/orderer1.xinhe.com/tls/server.crt
              ServerTLSCert: ./crypto-config/ordererOrganizations/xinhe.com/orderers/orderer1.xinhe.com/tls/server.crt
            - Host: orderer2.xinhe.com
              Port: 7250
              ClientTLSCert: ./crypto-config/ordererOrganizations/xinhe.com/orderers/orderer2.xinhe.com/tls/server.crt
              ServerTLSCert: ./crypto-config/ordererOrganizations/xinhe.com/orderers/orderer2.xinhe.com/tls/server.crt

#            动态添加组织后，加入下面的配置，创建的新通道不需要修改通道配置
#            - Host: orderer3.xinhe.com
#              Port: 7350
#              ClientTLSCert: ./crypto-config/ordererOrganizations/xinhe.com/orderers/orderer3.xinhe.com/tls/server.crt
#              ServerTLSCert: ./crypto-config/ordererOrganizations/xinhe.com/orderers/orderer3.xinhe.com/tls/server.crt

    # 区块打包的最大超时时间 (到了该时间就打包区块)
    BatchTimeout: 2s
    # 区块打包的最大包含交易数（orderer端切分区块的参数）
    BatchSize:
        MaxMessageCount: 10         # 一个区块里最大的交易数
        AbsoluteMaxBytes: 99 MB     # 一个区块的最大字节数，任何时候都不能超过
        PreferredMaxBytes: 512 KB   # 一个区块的建议字节数，如果一个交易消息的大小超过了这个值, 就会被放入另外一个更大的区块中
    # 【可选项】表示Orderer允许的最大通道数， 默认0表示没有最大通道数
    MaxChannels: 0
    # 参与维护Orderer的组织，默认为空（通常在 Profiles 中再配置）
    Organizations:

    # 定义本层级的排序节点策略，其权威路径为 /Channel/Orderer/<PolicyName>
    Policies:
        Readers:
            Type: ImplicitMeta
            Rule: "ANY Readers"
        Writers:
            Type: ImplicitMeta
            Rule: "ANY Writers"
        Admins:
            Type: ImplicitMeta
            Rule: "MAJORITY Admins"

        # BlockValidation配置项指定了哪些签名必须包含在区块中，以便对等节点进行验证
        BlockValidation:
            Type: ImplicitMeta
            Rule: "ANY Writers"

#通道配置：Channel配置段用来定义要写入创世区块或配置交易的通道参数。
#该部分定义了交易配置相关的值，以及包含和创世区块相关的值。
Channel: &ChannelDefaults
    # 定义本层级的通道访问策略，其权威路径为 /Channel/<PolicyName>
    Policies:
        #定义谁可以调用交付区块的API
        Readers:
            Type: ImplicitMeta
            Rule: "ANY Readers"
        # Writes策略定义了调用Broadcast API提交交易的许可规则
        Writers:
            Type: ImplicitMeta
            Rule: "ANY Writers"
        # Admin策略定义了修改本层级配置的许可规则
        Admins:
            Type: ImplicitMeta
            Rule: "MAJORITY Admins"

    # Capabilities配置描通道层级的能力需求，这里直接引用
    # 前面Capabilities配置段中的ChannelCapabilities配置项
    Capabilities:
        <<: *ChannelCapabilities

#配置入口：Profiles配置段用来定义用于configtxgen工具的配置入口。包含委员会（consortium）的配置入口可以用来生成排序节点的创世区块。
# 如果在排序节点的创世区块中正确定义了consortium的成员，那么可以仅使用机构成员名称和委员会的名称来生成通道创建请求。
Profiles:

# fabric无系统通道的配置，不需要生成创世区块
#    # TwoOrgsOrdererGenesis用来生成orderer启动时所需的block，用于生成创世区块，名字可以任意
#    # 需要包含Orderer和Consortiums两部分
#    TwoOrgsOrdererGenesis:
#        <<: *ChannelDefaults    # 通道为默认配置，这里直接引用上面channel配置段中的ChannelDefaults
#        Orderer:
#            <<: *OrdererDefaults    # Orderer为默认配置，这里直接引用上面orderer配置段中的OrdererDefaults
#            #  排序节点的维护组织
#            Organizations:      # 这里直接引用上面Organizations配置段中的OrdererOrg
#                - *OrdererOrg
#            Capabilities:       # 这里直接引用上面Capabilities配置段中的OrdererCapabilities
#                <<: *OrdererCapabilities
#        # 联盟为默认的 SampleConsortium 联盟，添加了两个组织，表示orderer所服务的联盟列表
#        Consortiums:
#            #  创建更多应用通道时的联盟引用 TwoOrgsChannel 所示
#            SampleConsortium:
#                # 联盟中包含的组织
#                Organizations:
#                    - *Org1
#                    - *Org2
#                    - *Org3
    # TwoOrgsChannel用来生成channel配置信息，名字可以任意
    # 需要包含Consortium和Applicatioon两部分。
    TwoOrgsChannel:
        # 通道所关联的联盟名称
#        Consortium: SampleConsortium
        <<: *ChannelDefaults    # 通道为默认配置，这里直接引用上面channel配置段中的ChannelDefaults
        Orderer:
            <<: *OrdererDefaults    # Orderer为默认配置，这里直接引用上面orderer配置段中的OrdererDefaults
            #  排序节点的维护组织
            Organizations: # 这里直接引用上面Organizations配置段中的OrdererOrg
                - *OrdererOrg
            Capabilities: # 这里直接引用上面Capabilities配置段中的OrdererCapabilities
                <<: *OrdererCapabilities
        Application:
            <<: *ApplicationDefaults    # 这里直接引用上面Application配置段中的ApplicationDefaults
            # 通道中包含的组织
            Organizations:
                - *Org1
                - *Org2
#                - *Org3        # 在fabric网络中新增组织后，加上这个配置，新增的通道就不要需要修改通道配置加入通道了
            Capabilities:
                <<: *ApplicationCapabilities    # 这里直接引用上面Capabilities配置段中的ApplicationCapabilities

```

## orderer.yaml文件

```yaml
version: '3'

services:
    orderer0.xinhe.com:
        container_name: orderer0.xinhe.com
        image: 58.249.1.220:2000/fabric/xinhe/xinhe-orderer:2.4.6
        environment:
            - FABRIC_LOGGING_SPEC=INFO
            - ORDERER_GENERAL_LISTENADDRESS=0.0.0.0
            - ORDERER_GENERAL_LISTENPORT=7050
#            - ORDERER_GENERAL_GENESISMETHOD=file
#            - ORDERER_GENERAL_GENESISFILE=/var/hyperledger/orderer/orderer.genesis.block
            - ORDERER_GENERAL_LOCALMSPID=OrdererMSP
            - ORDERER_GENERAL_LOCALMSPDIR=/var/hyperledger/orderer/msp
            - ORDERER_GENERAL_TLS_ENABLED=true
            - ORDERER_GENERAL_TLS_PRIVATEKEY=/var/hyperledger/orderer/tls/server.key
            - ORDERER_GENERAL_TLS_CERTIFICATE=/var/hyperledger/orderer/tls/server.crt
            - ORDERER_GENERAL_TLS_ROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]
            - ORDERER_KAFKA_TOPIC_REPLICATIONFACTOR=1
            - ORDERER_KAFKA_VERBOSE=true
            - ORDERER_GENERAL_CLUSTER_CLIENTCERTIFICATE=/var/hyperledger/orderer/tls/server.crt
            - ORDERER_GENERAL_CLUSTER_CLIENTPRIVATEKEY=/var/hyperledger/orderer/tls/server.key
            - ORDERER_GENERAL_CLUSTER_ROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]
#           配置无系统通道
            - ORDERER_GENERAL_BOOTSTRAPMETHOD=none
            - ORDERER_ADMIN_LISTENADDRESS=0.0.0.0:9443
            - ORDERER_ADMIN_TLS_ENABLED=true
            - ORDERER_ADMIN_TLS_PRIVATEKEY=/var/hyperledger/orderer/tls/server.key
            - ORDERER_ADMIN_TLS_CERTIFICATE=/var/hyperledger/orderer/tls/server.crt
            - ORDERER_ADMIN_TLS_CLIENTAUTHREQUIRED=true
            - ORDERER_ADMIN_TLS_CLIENTROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]
            - ORDERER_CHANNELPARTICIPATION_ENABLED=true
        working_dir: /opt/gopath/src/github.com/hyperledger/fabric
        command: orderer
        volumes:
            - /etc/localtime:/etc/localtime
            - ./channel-artifacts/genesis.block:/var/hyperledger/orderer/orderer.genesis.block
            - ./crypto-config/ordererOrganizations/xinhe.com/orderers/orderer0.xinhe.com/msp:/var/hyperledger/orderer/msp
            - ./crypto-config/ordererOrganizations/xinhe.com/orderers/orderer0.xinhe.com/tls/:/var/hyperledger/orderer/tls
        ports:
            - 7050:7050
            - 9443:9443
        extra_hosts:
            - "orderer0.xinhe.com:192.168.1.135"
            - "orderer1.xinhe.com:192.168.1.135"
            - "orderer2.xinhe.com:192.168.1.135"
            - "orderer3.xinhe.com:192.168.1.135"
            - "peer0.org1.xinhe.com:192.168.1.135"
            - "peer1.org1.xinhe.com:192.168.1.135"
            - "peer2.org1.xinhe.com:192.168.1.135"
            - "peer0.org2.xinhe.com:192.168.1.136"
            - "peer1.org2.xinhe.com:192.168.1.136"
            - "peer0.org3.xinhe.com:192.168.1.136"
            - "peer1.org3.xinhe.com:192.168.1.136"

    orderer1.xinhe.com:
        container_name: orderer1.xinhe.com
        image: 58.249.1.220:2000/fabric/xinhe/xinhe-orderer:2.4.6
        environment:
            - FABRIC_LOGGING_SPEC=INFO
            - ORDERER_GENERAL_LISTENADDRESS=0.0.0.0
            - ORDERER_GENERAL_LISTENPORT=7150
#            - ORDERER_GENERAL_GENESISMETHOD=file
#            - ORDERER_GENERAL_GENESISFILE=/var/hyperledger/orderer/orderer.genesis.block
            - ORDERER_GENERAL_LOCALMSPID=OrdererMSP
            - ORDERER_GENERAL_LOCALMSPDIR=/var/hyperledger/orderer/msp
            - ORDERER_GENERAL_TLS_ENABLED=true
            - ORDERER_GENERAL_TLS_PRIVATEKEY=/var/hyperledger/orderer/tls/server.key
            - ORDERER_GENERAL_TLS_CERTIFICATE=/var/hyperledger/orderer/tls/server.crt
            - ORDERER_GENERAL_TLS_ROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]
            - ORDERER_KAFKA_TOPIC_REPLICATIONFACTOR=1
            - ORDERER_KAFKA_VERBOSE=true
            - ORDERER_GENERAL_CLUSTER_CLIENTCERTIFICATE=/var/hyperledger/orderer/tls/server.crt
            - ORDERER_GENERAL_CLUSTER_CLIENTPRIVATEKEY=/var/hyperledger/orderer/tls/server.key
            - ORDERER_GENERAL_CLUSTER_ROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]
            #           配置无系统通道
            - ORDERER_GENERAL_BOOTSTRAPMETHOD=none
            - ORDERER_ADMIN_LISTENADDRESS=0.0.0.0:9444
            - ORDERER_ADMIN_TLS_ENABLED=true
            - ORDERER_ADMIN_TLS_PRIVATEKEY=/var/hyperledger/orderer/tls/server.key
            - ORDERER_ADMIN_TLS_CERTIFICATE=/var/hyperledger/orderer/tls/server.crt
            - ORDERER_ADMIN_TLS_CLIENTAUTHREQUIRED=true
            - ORDERER_ADMIN_TLS_CLIENTROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]
            - ORDERER_CHANNELPARTICIPATION_ENABLED=true
        working_dir: /opt/gopath/src/github.com/hyperledger/fabric
        command: orderer
        volumes:
            - /etc/localtime:/etc/localtime
            - ./channel-artifacts/genesis.block:/var/hyperledger/orderer/orderer.genesis.block
            - ./crypto-config/ordererOrganizations/xinhe.com/orderers/orderer1.xinhe.com/msp:/var/hyperledger/orderer/msp
            - ./crypto-config/ordererOrganizations/xinhe.com/orderers/orderer1.xinhe.com/tls/:/var/hyperledger/orderer/tls
        ports:
            - 7150:7150
            - 9444:9444
        extra_hosts:
            - "orderer0.xinhe.com:192.168.1.135"
            - "orderer1.xinhe.com:192.168.1.135"
            - "orderer2.xinhe.com:192.168.1.135"
            - "orderer3.xinhe.com:192.168.1.135"
            - "peer0.org1.xinhe.com:192.168.1.135"
            - "peer1.org1.xinhe.com:192.168.1.135"
            - "peer2.org1.xinhe.com:192.168.1.135"
            - "peer0.org2.xinhe.com:192.168.1.136"
            - "peer1.org2.xinhe.com:192.168.1.136"
            - "peer0.org3.xinhe.com:192.168.1.136"
            - "peer1.org3.xinhe.com:192.168.1.136"

    orderer2.xinhe.com:
        container_name: orderer2.xinhe.com
        image: 58.249.1.220:2000/fabric/xinhe/xinhe-orderer:2.4.6
        environment:
            - FABRIC_LOGGING_SPEC=INFO
            - ORDERER_GENERAL_LISTENADDRESS=0.0.0.0
            - ORDERER_GENERAL_LISTENPORT=7250
#            - ORDERER_GENERAL_GENESISMETHOD=file
#            - ORDERER_GENERAL_GENESISFILE=/var/hyperledger/orderer/orderer.genesis.block
            - ORDERER_GENERAL_LOCALMSPID=OrdererMSP
            - ORDERER_GENERAL_LOCALMSPDIR=/var/hyperledger/orderer/msp
            - ORDERER_GENERAL_TLS_ENABLED=true
            - ORDERER_GENERAL_TLS_PRIVATEKEY=/var/hyperledger/orderer/tls/server.key
            - ORDERER_GENERAL_TLS_CERTIFICATE=/var/hyperledger/orderer/tls/server.crt
            - ORDERER_GENERAL_TLS_ROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]
            - ORDERER_KAFKA_TOPIC_REPLICATIONFACTOR=1
            - ORDERER_KAFKA_VERBOSE=true
            - ORDERER_GENERAL_CLUSTER_CLIENTCERTIFICATE=/var/hyperledger/orderer/tls/server.crt
            - ORDERER_GENERAL_CLUSTER_CLIENTPRIVATEKEY=/var/hyperledger/orderer/tls/server.key
            - ORDERER_GENERAL_CLUSTER_ROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]
          #           配置无系统通道
            - ORDERER_GENERAL_BOOTSTRAPMETHOD=none
            - ORDERER_ADMIN_LISTENADDRESS=0.0.0.0:9445
            - ORDERER_ADMIN_TLS_ENABLED=true
            - ORDERER_ADMIN_TLS_PRIVATEKEY=/var/hyperledger/orderer/tls/server.key
            - ORDERER_ADMIN_TLS_CERTIFICATE=/var/hyperledger/orderer/tls/server.crt
            - ORDERER_ADMIN_TLS_CLIENTAUTHREQUIRED=true
            - ORDERER_ADMIN_TLS_CLIENTROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]
            - ORDERER_CHANNELPARTICIPATION_ENABLED=true
        working_dir: /opt/gopath/src/github.com/hyperledger/fabric
        command: orderer
        volumes:
            - /etc/localtime:/etc/localtime
            - ./channel-artifacts/genesis.block:/var/hyperledger/orderer/orderer.genesis.block
            - ./crypto-config/ordererOrganizations/xinhe.com/orderers/orderer2.xinhe.com/msp:/var/hyperledger/orderer/msp
            - ./crypto-config/ordererOrganizations/xinhe.com/orderers/orderer2.xinhe.com/tls/:/var/hyperledger/orderer/tls
        ports:
            - 7250:7250
            - 9445:9445
        extra_hosts:
            - "orderer0.xinhe.com:192.168.1.135"
            - "orderer1.xinhe.com:192.168.1.135"
            - "orderer2.xinhe.com:192.168.1.135"
            - "orderer3.xinhe.com:192.168.1.135"
            - "peer0.org1.xinhe.com:192.168.1.135"
            - "peer1.org1.xinhe.com:192.168.1.135"
            - "peer2.org1.xinhe.com:192.168.1.135"
            - "peer0.org2.xinhe.com:192.168.1.136"
            - "peer1.org2.xinhe.com:192.168.1.136"
            - "peer0.org3.xinhe.com:192.168.1.136"
            - "peer1.org3.xinhe.com:192.168.1.136"

```

## peer.yaml文件

不需要调整，与有系统通道一致

```yaml
version: '3'

services:
    couchdb1.org1.xinhe.com:
        container_name: couchdb1.org1.xinhe.com
        image: 58.249.1.220:2000/fabric/xinhe/couchdb:2.1.1
        environment:
            - COUCHDB_USER=admin
            - COUCHDB_PASSWORD=adminpw
        ports:
            - 5985:5984
        volumes:
            - /etc/localtime:/etc/localtime

    peer1.org1.xinhe.com:
        container_name: peer1.org1.xinhe.com
        image: 58.249.1.220:2000/fabric/xinhe/xinhe-peer:2.4.6
        environment:
            - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
            - CORE_PEER_ID=peer1.org1.xinhe.com
            - CORE_PEER_ADDRESS=peer1.org1.xinhe.com:7151
            - CORE_PEER_LISTENADDRESS=0.0.0.0:7151
            - CORE_PEER_CHAINCODEADDRESS=peer1.org1.xinhe.com:7152
            - CORE_PEER_CHAINCODELISTENADDRESS=0.0.0.0:7152
            - CORE_PEER_GOSSIP_BOOTSTRAP=peer1.org1.xinhe.com:7151
            - CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer1.org1.xinhe.com:7151
            - CORE_PEER_LOCALMSPID=Org1MSP
            - FABRIC_LOGGING_SPEC=INFO
            - CORE_PEER_TLS_ENABLED=true
            - CORE_PEER_GOSSIP_USELEADERELECTION=true
            - CORE_PEER_GOSSIP_ORGLEADER=false
            - CORE_PEER_PROFILE_ENABLED=true
            - CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/fabric/tls/server.crt
            - CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/fabric/tls/server.key
            - CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/tls/ca.crt
            - CORE_CHAINCODE_EXECUTETIMEOUT=300s
            - CORE_LEDGER_STATE_STATEDATABASE=CouchDB
            - CORE_LEDGER_STATE_COUCHDBCONFIG_COUCHDBADDRESS=couchdb1.org1.xinhe.com:5984
            - CORE_LEDGER_STATE_COUCHDBCONFIG_USERNAME=admin
            - CORE_LEDGER_STATE_COUCHDBCONFIG_PASSWORD=adminpw
        depends_on:
            - couchdb1.org1.xinhe.com
        working_dir: /opt/gopath/src/github.com/hyperledger/fabric/peer
        command: peer node start
        volumes:
            - /etc/localtime:/etc/localtime
            - /var/run/:/host/var/run/
            - ./crypto-config/peerOrganizations/org1.xinhe.com/peers/peer1.org1.xinhe.com/msp:/etc/hyperledger/fabric/msp
            - ./crypto-config/peerOrganizations/org1.xinhe.com/peers/peer1.org1.xinhe.com/tls:/etc/hyperledger/fabric/tls
        ports:
            - 7151:7151
            - 7152:7152
            - 7153:7153
        extra_hosts:
            - "orderer0.xinhe.com:192.168.1.135"
            - "orderer1.xinhe.com:192.168.1.135"
            - "orderer2.xinhe.com:192.168.1.135"
            - "orderer3.xinhe.com:192.168.1.135"
            - "peer0.org1.xinhe.com:192.168.1.135"
            - "peer1.org1.xinhe.com:192.168.1.135"
            - "peer2.org1.xinhe.com:192.168.1.135"
            - "peer0.org2.xinhe.com:192.168.1.136"
            - "peer1.org2.xinhe.com:192.168.1.136"
            - "peer0.org3.xinhe.com:192.168.1.136"
            - "peer1.org3.xinhe.com:192.168.1.136"

```

## osnadmin命令

![Untitled](Fabric%E7%BD%91%E7%BB%9C%E8%BF%90%E7%BB%B4%208a29e56285354c21a872bb7b7b3297d7/Untitled%204.png)

```bash
# 创建通道区块文件，注意：动态向网络中添加了组织或者orderer后需要相应的调整configtx.yaml文件，否则创建的新通道是不会包含新增的组织和orderer的
# 通过configtx.yaml文件中TwoOrgsChannel配置生成通道tx文件
configtxgen -profile TwoOrgsChannel -outputCreateChannelTx mychannel.tx -channelID mychannel
# 根据通道tx文件以及configtx.yaml文件生成通道block配置文件
configtxgen -profile TwoOrgsChannel -outputBlock ./channel-artifacts/mychannel.block -channelID mychannel

# 设置orderer组织管理员环境变量
export ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/xinhe.com/msp/tlscacerts/tls-ca-immediate-xinhe-com-7055.pem
export ORDERER_ADMIN_TLS_SIGN_CERT=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/xinhe.com/users/Admin\@xinhe.com/msp/signcerts/cert.pem
export ORDERER_ADMIN_TLS_PRIVATE_KEY=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/xinhe.com/users/Admin\@xinhe.com/msp/keystore/priv_sk

# 查看指定orderer加入的通道
osnadmin channel list -o orderer0.xinhe.com:9443 --ca-file $ORDERER_CA --client-cert $ORDERER_ADMIN_TLS_SIGN_CERT --client-key $ORDERER_ADMIN_TLS_PRIVATE_KEY

osnadmin channel list --channelID mychannel -o orderer0.xinhe.com:9443 --ca-file $ORDERER_CA --client-cert $ORDERER_ADMIN_TLS_SIGN_CERT --client-key $ORDERER_ADMIN_TLS_PRIVATE_KEY

# 根据创世区块加入通道：
osnadmin channel join --channelID mychannel -o orderer0.xinhe.com:9443 --config-block ./channel-artifacts/mychannel.block --ca-file $ORDERER_CA --client-cert $ORDERER_ADMIN_TLS_SIGN_CERT --client-key $ORDERER_ADMIN_TLS_PRIVATE_KEY

# 将指定orderer从通道中删除
osnadmin channel remove --channelID mychannel -o orderer0.xinhe.com:9443 --ca-file $ORDERER_CA --client-cert $ORDERER_ADMIN_TLS_SIGN_CERT --client-key $ORDERER_ADMIN_TLS_PRIVATE_KEY
```