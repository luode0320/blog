## 1、进入cli容器

```shell
docker exec -it cli bash
```

## 2、查询a的余额

```shell
peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'
```

## 3、节点环境变量

```shell
# 切换到peer0.org1节点
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
CORE_PEER_ADDRESS=peer0.org1.example.com:7051
CORE_PEER_LOCALMSPID="Org1MSP"
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt


# 切换到peer1.org1节点


# 切换到peer0.org2节点
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
CORE_PEER_ADDRESS=peer0.org2.example.com:9051 
CORE_PEER_LOCALMSPID="Org2MSP" 
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt 


# 切换到peer1.org2节点
CORE_PEER_LOCALMSPID="Org2MSP" 
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer1.org2.example.com/tls/ca.crt 
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp 
CORE_PEER_ADDRESS=peer1.org2.example.com:10051

# 切换到peer2.org1节点
CORE_PEER_LOCALMSPID="Org1MSP"
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer2.org1.example.com/tls/ca.crt CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
CORE_PEER_ADDRESS=peer2.org1.example.com:11051


```

## 4、Peer加入mychanne

```shell
peer channel join -b mychannel.block
```

## 5、查看节点加入的通道

```shell
peer channel list
```

## ca容器

```shell
docker pull hyperledger/fabric-ca:1.5
```

## 6、生成通道命令

```shell
#生成通道文件 (外面)
configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/preschannel.tx -channelID preschannel

常见错误：
2022-05-12 10:39:11.784 CST [common.tools.configtxgen.localconfig] Load -> PANI 002 Error reading configuration:  Unsupported Config Type ""
2022-05-12 10:39:11.784 CST [common.tools.configtxgen] func1 -> PANI 003 Error reading configuration:  Unsupported Config Type ""
panic: Error reading configuration:  Unsupported Config Type "" [recovered]

解决：export FABRIC_CFG_PATH=/root/FABRIC/fabric-samples/first-network



#创建通道
peer channel create -o orderer.example.com:7050 -c preschannel -f ./channel-artifacts/preschannel.tx --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/orderer/tlscacerts/tls-0-0-0-0-7054.pem

或者

peer channel fetch oldest testchannel.block -c testchannel -o orderer.example.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrga nizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tls ca.example.com-cert.pem

```

## 7、添加新节点

```shell
参考地址：https://blog.csdn.net/u013137970/article/details/112606730
```

## 8、检查节点上的链码安装情况

```shell
peer lifecycle chaincode queryinstalled
```

## 9、打包链码

```shell
peer lifecycle chaincode package mychaincode.tar.gz --path ../chaincode/fabcar/go/ --lang java --label mychaincode



peer chaincode invoke -o orderer.example.com:7050 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
-C mychannel -n marblesp -c '{"Args":["initMarble"]}' --transient "{\"marble\":\"$MARBLE\"}"
```

## 10、交易

```shell
peer  chaincode invoke -o orderer.example.com:7050 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem  -C mychannel --name mycc --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt   -c '{"Args":["invoke","a","b","10"]}'
```

## 11.java安装链码

```shell
#打包
peer lifecycle chaincode package hyperledger-fabric-contract-java-demo.tar.gz --path ./hyperledger-fabric-contract-java-demo --lang java --label hyperledger-fabric-contract-java-demo_1

#初始化

peer chaincode instantiate -o orderer.example.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n hyperledger-fabric-contract-java-demo -v 1.0 -P "AND ('Org1MSP.member', 'Org2MSP.member')" -c '{"Args":["init","a","100","b","200"]}'


peer lifecycle chaincode approveformyorg \
    --tls \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
    --channelID mychannel --name hyperledger-fabric-contract-java-demo --version 1 \
     --init-required --sequence 1 --waitForEvent --package-id hyperledger-fabric-contract-java-demo_1:8fc03af5b705479b9dece5803b119c1b6cc6ad15b8c92a00f2c9ea9bdb62c501
     


peer chaincode invoke -o orderer.example.com:7050 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n hyperledger-fabric-contract-java-demo  --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt --isInit -c '{"Args":["Init","a","100","b","100"]}
```

## 11、链码升级

```shell
#切换到org1
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
CORE_PEER_ADDRESS=peer0.org1.example.com:7051
CORE_PEER_LOCALMSPID="Org1MSP"
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt

#切换到org2
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
CORE_PEER_ADDRESS=peer0.org2.example.com:9051
CORE_PEER_LOCALMSPID="Org2MSP"
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt

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


peer lifecycle chaincode commit -o orderer.example.com:7050 --tls true \
--cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --channelID mychannel --name mycc \
--peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt \
--peerAddresses peer0.org2.example.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt --version 2.0 --sequence 2
```

## 12、弹珠命令

```shell

peer  chaincode invoke -o orderer.example.com:7050 --tls true \
--cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
-C mychannel --name mycc --peerAddresses peer0.org1.example.com:7051 \
--tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt  \
--peerAddresses peer0.org2.example.com:9051  \
 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt  \
 -c '{"Args":["initMarble","marble1","blue","35","tom"]}'
 
 
 peer  chaincode invoke -o orderer.example.com:7050 --tls true \
--cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
-C mychannel --name mycc --peerAddresses peer0.org1.example.com:7051 \
--tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt  \
--peerAddresses peer0.org2.example.com:9051  \
 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt  \
 -c '{"Args":["initMarble","marble2","red","50","tom"]}'
 
 
 
 peer  chaincode invoke -o orderer.example.com:7050 --tls true \
--cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
-C mychannel --name mycc --peerAddresses peer0.org1.example.com:7051 \
--tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt  \
--peerAddresses peer0.org2.example.com:9051  \
 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt  \
 -c '{"Args":["initMarble","marble3","blue","70","tom"]}'
 
 
 peer  chaincode invoke -o orderer.example.com:7050 --tls true \
--cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
-C mychannel --name mycc --peerAddresses peer0.org1.example.com:7051 \
--tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt  \
--peerAddresses peer0.org2.example.com:9051  \
 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt  \
 -c '{"Args":["initMarble","marble1","blue","35","tom"]}'
 
 
 peer chaincode query -C mychannel -n mycc -c '{"Args":["readMarble","marble1"]}'
 
 peer chaincode query -C mychannel -n mycc -c '{"Args":["getHistoryForMarble","marble1"]}'
 
 
 peer chaincode query -C mychannel -n mycc -c '{"Args":["getMarblesByRange","marble1","marble3"]}'
 
 
 
  peer chaincode invoke -o orderer.example.com:7050 --tls true \
  --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  -C mychannel -n mycc -c '{"Args":["transferMarble","marble2","jerry"]}'
 
 
  peer chaincode invoke -o orderer.example.com:7050 --tls true \
  --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  -C mychannel -n mycc -c '{"Args":["delete","marble1"]}'
  
 
 peer chaincode query -C mychannel -n mycc -c '{"Args":["getMarblesByRange","marble1","marble3"]}'
 
 
 
 peer chaincode query -C mychannel -n mycc -c '{"Args":["queryMarblesWithPagination", "{\"selector\":{\"docType\":\"marble\",\"owner\":\"tom\"}, \"use_index\":[\"_design/indexOwnerDoc\", \"indexOwner\"]}","3",""]}'
 
 
 
#根据条件查询 
peer chaincode query -C mychannel -n mycc -c '{"Args":["queryMarbles", "{\"selector\":{\"integralId\":\"1\"}, \"use_index\":[\"_design/indexOwnerDoc\", \"indexOwner\"]}"]}'
 
 #模糊查询
 peer chaincode query -C mychannel -n mycc -c  \
 '{"Args":["queryValues", "{\"selector\":{\"nodeName\":{\"$regex\":\"室\"}}, \"use_index\":[\"_design/indexOwnerDoc\", \"indexOwner\"]}"]}'
 
 #queryValues
 peer chaincode query -C mychannel -n mycc -c  \
 '{"Args":["queryValues", "{\"selector\":{\"nodeName\":{\"$regex\":\"室\"}}}","3",""]}'
 
```

## 清除

```shell
docker-compose -f docker-compose-cli.yaml down --volumes --remove-orphans

docker rm -f $(docker ps -a | grep "hyperledger/*" |  awk "{print \$1}")

docker volume prune
```

## 启动CounchDB

```shell
./byfn.sh -m down

2. 生成新的配置
./byfn.sh -m generate -s couchdb

3.启动
./byfn.sh -m up -s couchdb
```

## fabric--explorer 证书文件拷贝

```shell
8、删除/fabric-explorer/organizations 目录下的 ordererOrganizations
文件：
rm -rf /root/FABRIC/fabric-explorer/organizations/ordererOrganizations

拷贝动态文件 ordererOrganizations：
cp -r /root/FABRIC/fabric-samples/first-network/crypto-config/ordererOrganizations /root/FABRIC/fabric-explorer/organizations

9、删除/fabric-explorer/organizations 目录下的 peerOrganizations 文件：
rm -rf /root/FABRIC/fabric-explorer/organizations/peerOrganizations

拷贝动态文件 peerOrganizations：
cp -r /root/FABRIC/fabric-samples/first-network/crypto-config/peerOrganizations /root/FABRIC/fabric-explorer/organizations
```

## 链码qscc

```shell
peer chaincode invoke -o orderer.example.com:7050 --tls true \
  --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  -C mychannel -n qscc \
-c '{"function":"GetTransactionByID","Args":["mychannel", "0bcbb3e668374fc8d23d7e8a4f2ac291f6d9b47596e5ebf23ee1d5c1493aff00"]}'


peer chaincode invoke -o orderer.example.com:7050 --tls true \
  --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  -C mychannel -n qscc \
-c '{"function":"GetBlockByNumber","Args":["40"]}'

peer chaincode invoke -o orderer.example.com:7050 --tls true \
  --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  -C mychannel -n qscc \
-c '{"function":"GetBlockByHash","Args":["mychannel","a0861faee0b4bb1f8ae3f0939de8a7191f1ce7d72bd7d0ca7d447518a52fb825"]}'


```

## 查询区块的高度和内容

```shell
参考：https://blog.51cto.com/shijianfeng/2914724


docker exec  cli peer channel getinfo -c mychannel

docker exec cli peer channel fetch 1000 -c mychannel

peer channel fetch newest -o orderer.example.com:7050 -c mychannel  last.block
```

## 安装链码

```shell
#切换到org1
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
CORE_PEER_ADDRESS=peer0.org1.example.com:7051
CORE_PEER_LOCALMSPID="Org1MSP"
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt


#切换到org2
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
CORE_PEER_ADDRESS=peer0.org2.example.com:9051
CORE_PEER_LOCALMSPID="Org2MSP"
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt

#打包
peer lifecycle chaincode package prescc.tar.gz --path github.com/hyperledger/fabric-samples/chaincode/prescc/go --lang golang --label prescc_1 

#安装
peer lifecycle chaincode install prescc.tar.gz


#通道审核
peer lifecycle chaincode approveformyorg --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --channelID preschannel --name prescc --version 1 --init-required --package-id prescc_1:35ae6c6a2024300d18593d20f93ecfd313f2b27ba11281f5a9e61f706af58530 --sequence 1 --waitForEvent


#查询通道的审核情况
peer lifecycle chaincode checkcommitreadiness --channelID taskchannel --name taskcc --version 1 --sequence 1 --output json --init-required


#提交
peer lifecycle chaincode commit -o orderer.example.com:7050 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --channelID preschannel --name pres1cc --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt --version 1 --sequence 1 --init-required


#实例化  (报异常多执行一下，问题未知)
peer chaincode invoke -o orderer.example.com:7050 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C preschannel -n prescc --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt --isInit -c '{"Args":["Init","a","100","b","100"]}'


#交易
peer chaincode invoke -o orderer.example.com:7050 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n mycc --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"Args":["invoke","a","b","10"]}'


peer chaincode instantiate -o orderer.example.com:7050 -C mychannel -n yourcc -l golang -v 1.0 -c '{"Args":[]}' -P 'AND ('\''Org1MSP.peer'\'','\''Org2MSP.peer'\'')'

```

## linux系统文件传输到[docker](https://so.csdn.net/so/search?q=docker&spm=1001.2101.3001.7020)容器内命令

```shell
docker cp 本地文件 容器ID:容器目录
如docker cp /root/test.sh cli:/opt/gopath/src/github.com/hyperledger/fabric/peer
```

```shell
peer chaincode install -n ecctest -v 1.0 -l golang -p github.com/hyperledger/fabric-samples/chaincode/abstore/go/

peer chaincode instantiate -o orderer.example.com:7050 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n ecctest -l golang -v 1.0 -c '{"Args":["invoke","a","b","10"]}'

peer chaincode invoke -o orderer.example.com:7050 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n mycc --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"Args":["invoke","a","b","10"]}'

```

## 查看docker 容器的环境变量

```shell
docker exec {containerID} env



docker run --env a=b -d -p 8888:8888 balance
```

## 推送docker 镜像Harbor

```shell
修改docker配置文件
/etc/docker/daemon.json
内容：
{
  "registry-mirrors": ["https://k1ktap5m.mirror.aliyuncs.com"],
  "insecure-registries":["192.168.1.206:85"]
}

命令：systemctl daemon-reload
     systemctl restart docker


1、在项目中标记镜像：
   命令： docker tag SOURCE_IMAGE[:TAG] 192.168.1.206:85/block/REPOSITORY[:TAG]
   例：docker tag docker.io/hyperledger/fabric-orderer:2.0.0  192.168.1.206:85/block/fabric-orderer:2.0.0
2、推送镜像到当前项目：
   命令：docker push 192.168.1.206:85/block/REPOSITORY[:TAG]
   例：docker push 192.168.1.206:85/block/fabric-orderer:2.0.0
   

```



# 命令第二部分

## admin和adminmax用户信息

```
Name: admin, Type: client, Affiliation: , Max Enrollments: -1, Attributes: [{Name:hf.AffiliationMgr Value:1 ECert:false} {Name:hf.Registrar.Roles Value:* ECert:false} {Name:hf.Registrar.DelegateRoles Value:* ECert:false} {Name:hf.Revoker Value:1 ECert:false} {Name:hf.IntermediateCA Value:1 ECert:false} {Name:hf.GenCRL Value:1 ECert:false} {Name:hf.Registrar.Attributes Value:* ECert:false}]

Name: adminmax, Type: client, Affiliation: , Max Enrollments: -1, Attributes: [{Name:hf.Registrar.Roles Value:* ECert:false} {Name:hf.Registrar.Attributes Value:* ECert:false} {Name:hf.AffiliationMgr Value:true ECert:false} {Name:hf.IntermediateCA Value:true ECert:false} {Name:hf.Revoker Value:true ECert:false} {Name:hf.GenCRL Value:true ECert:false} {Name:hf.Registrar.DelegateRoles Value:true ECert:false} {Name:hf.EnrollmentID Value:adminmax ECert:true} {Name:hf.Type Value:client ECert:true} {Name:hf.Affiliation Value: ECert:true}

Name: adminmax7, Type: client, Affiliation: , Max Enrollments: -1, Attributes: [{Name:hf.Registrar.Roles Value:* ECert:false} {Name:hf.Registrar.Attributes Value:* ECert:false} {Name:hf.AffiliationMgr Value:true ECert:false} {Name:hf.IntermediateCA Value:true ECert:false} {Name:hf.Revoker Value:true ECert:false} {Name:hf.GenCRL Value:true ECert:false} {Name:hf.Registrar.DelegateRoles Value:true ECert:false}    {Name:hf.EnrollmentID Value:adminmax7 ECert:true} {Name:hf.Type Value:client ECert:true} {Name:hf.Affiliation Value: ECert:true}
```

## 创建adminmax用户（用于联盟的创建和删除）

```
fabric-ca-client register -d --id.name adminmax7 --id.secret adminmax7 --id.type client --id.attrs "hf.Registrar.Roles=*,hf.IntermediateCA=true,hf.Registrar.DelegateRoles=true,hf.Registrar.Attributes=*,hf.Revoker=true,hf.AffiliationMgr=true,hf.GenCRL=true" -u http://0.0.0.0:7054
```

## 登录admin用户

```
fabric-ca-client enroll -d -u http://admin:adminpw@0.0.0.0:7054
```

## 登录amdinmax用户

```
fabric-ca-client enroll -d -u http://adminmax:adminmax@0.0.0.0:7054
```

## 创建我们需要的联盟：

```
fabric-ca-client affiliation add com
fabric-ca-client affiliation add com.xinhe
fabric-ca-client affiliation add com.xinhe.orderer
fabric-ca-client affiliation add com.xinhe.org1
fabric-ca-client affiliation add com.xinhe.org2

```

## 注册身份

### 注册orderer组织的orderer节点

```
fabric-ca-client register -d  --id.name orderer.xinhe.com  --id.secret adminpw  --id.type orderer --id.affiliation  com.xinhe.orderer  --id.attrs "hf.Registrar.Roles=orderer,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true" -u http://0.0.0.0:7054
```

### 注册 orderer组织的Admin用户

```
fabric-ca-client register -d  \
--id.name admin@orderer.xinhe.com  \
--id.secret adminpw  \
--id.affiliation com.xinhe.orderer  \
--id.type admin  \
--id.attrs "hf.Registrar.Roles=admin,hf.Revoker=true,hf.GenCRL=true" -u http://0.0.0.0:7054
```

### 注册org1组织的peer0节点

```
 fabric-ca-client register -d \
 --id.name peer0.org1.xinhe.com \
 --id.secret adminpw \
 --id.type peer \
 --id.affiliation  com.xinhe.org1 \
 --id.attrs "hf.Registrar.Roles=peer,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true" -u http://0.0.0.0:7054
```

### 注册 org1组织的Admin用户 

```
fabric-ca-client register -d  \
--id.name admin@org1.xinhe.com  \
--id.secret adminpw  \
--id.affiliation com.xinhe.org1  \
--id.type admin  \
--id.attrs "hf.Registrar.Roles=admin,hf.Revoker=true,hf.GenCRL=true" -u http://0.0.0.0:7054

```

## 登录获取证书

### 登录 orderer组织的orderer用户获取msp

```
fabric-ca-client enroll -d -u http://orderer.xinhe.com:adminpw@0.0.0.0:7054 -M /usr/local/fabric-ca-client/NETWORK/MSP/com/xinhe/orderer
```

### 登录 orderer组织的Admin用户获取msp

```
fabric-ca-client enroll -d -u http://admin@orderer.xinhe.com:adminpw@0.0.0.0:7054 -M /usr/local/fabric-ca-client/NETWORK/MSP/com/xinhe/orderer/admincerts
```

### 登录 org1组织的peer0用户获取msp

```
fabric-ca-client enroll -d -u http://peer0.org1.xinhe.com:adminpw@0.0.0.0:7054 -M /usr/local/fabric-ca-client/NETWORK/MSP/com/xinhe/org1/peer0
```

### 登录 org1组织的Admin用户获取msp

```
fabric-ca-client enroll -d -u http://admin@org1.xinhe.com:adminpw@0.0.0.0:7054 -M /usr/local/fabric-ca-client/NETWORK/MSP/com/xinhe/org1/peer0/admincerts
```

## 获取`TLS CA`

### 登录管理员用户用于之后的节点身份注册

```
#设置环境变量指定根证书的路径(如果工作目录不同的话记得指定自己的工作目录,以下不再重复说明)
export FABRIC_CA_CLIENT_TLS_CERTFILES=/usr/local/fabric-ca-   client/NETWORK/MSP/com/xinhe/orderer/ca-cert.pem
#登录管理员用户用于之后的节点身份注册
fabric-ca-client enroll -d -u https://tls-ca-admin:tls-ca-adminpw@0.0.0.0:7055 
```

### TLS-CA上注册orderer组织的orderer节点

```
fabric-ca-client register -d --id.name orderer.xinhe.com  --id.secret adminpw  --id.type orderer  -u https://0.0.0.0:7055
```

### 配置环境变量

```
export FABRIC_CA_CLIENT_MSPDIR=/usr/local/fabric-ca-client/NETWORK/MSP/com/xinhe/orderer/tls-msp

export FABRIC_CA_CLIENT_TLS_CERTFILES=/usr/local/fabric-ca-client/NETWORK/MSP/com/xinhe/orderer/ca-cert.pem
```

### 登录`orderer`节点到`TLS CA`服务器上：

```
fabric-ca-client enroll -d -u https://orderer.xinhe.com:adminpw@0.0.0.0:7055 --enrollment.profile tls --csr.hosts orderer.xinhe.com -M /usr/local/fabric-ca-client/NETWORK/MSP/com/xinhe/orderer/tls-msp
```

### 登录`peer0-org1节点到`TLS CA服务器上

```
fabric-ca-client enroll -d -u http://peer0.org1.xinhe.com:adminpw@0.0.0.0:7054 --enrollment.profile tls --csr.hosts peer0-org1 -M /usr/local/fabric-ca-client/NETWORK/MSP/com/xinhe/org1/peer0/tls-msp
```

## 生成通道配置信息

```
FABRIC_CFG_PATH指定configtx.yaml的目录下
FABRIC_CFG_PATH=/usr/local/fabric-ca-client/NETWORK

configtxgen -profile XINHEDEVCHANNEL -outputCreateChannelTx /usr/local/fabric-ca-client/NETWORK/channel.tx -channelID xinhechannel 
```

## 生成创世区块

```
configtxgen -profile  XINHEDEVCHANNELGenesis  -outputBlock /usr/local/fabric-ca-client/NETWORK/genesis.block -channelID xinhechannel
```

## 创建通道

```
docker exec -it cli bash

sudo peer channel create -o orderer.example.com:7050 -c xinhechannel -f channel.tx --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
```



## 安装链码

```
peer chaincode install -n mycc -v 1.0 -p github.com/hyperledger/fabric-samples/chaincode/abstore/go
```

## 查询

### 查询身份

```
fabric-ca-client identity list
```

### 查询组织

```
fabric-ca-client affiliation list
```

### 添加组织(com)

```
fabric-ca-client  affiliation add com
```

### 删除组织(com)

```
注意：在默认情况下，Fabric CA服务器是禁用身份的删除的，但可以通过设置fabric-ca-server-config.yaml中的–cfg. affiliations.allowremove选项启动FabricCA服务器启用。

fabric-ca-client  affiliation remove --force  com
```

### 修改组织(com->com1)

```
fabric-ca-client  affiliation modify com --name com1
```



## 示例网络

### 示例网络的orderer的yaml内容

```
  orderer.example.com:
    container_name: orderer.example.com
	image: hyperledger/fabric-orderer:$IMAGE_TAG
    environment:
      - FABRIC_LOGGING_SPEC=INFO
      - ORDERER_GENERAL_LISTENADDRESS=0.0.0.0
      - ORDERER_GENERAL_BOOTSTRAPMETHOD=file
      - ORDERER_GENERAL_BOOTSTRAPFILE=/var/hyperledger/orderer/orderer.genesis.block
      - ORDERER_GENERAL_LOCALMSPID=OrdererMSP
      - ORDERER_GENERAL_LOCALMSPDIR=/var/hyperledger/orderer/msp
      # enabled TLS
      - ORDERER_GENERAL_TLS_ENABLED=true
      - ORDERER_GENERAL_TLS_PRIVATEKEY=/var/hyperledger/orderer/tls/server.key
      - ORDERER_GENERAL_TLS_CERTIFICATE=/var/hyperledger/orderer/tls/server.crt
      - ORDERER_GENERAL_TLS_ROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]
      - ORDERER_GENERAL_CLUSTER_CLIENTCERTIFICATE=/var/hyperledger/orderer/tls/server.crt
      - ORDERER_GENERAL_CLUSTER_CLIENTPRIVATEKEY=/var/hyperledger/orderer/tls/server.key
      - ORDERER_GENERAL_CLUSTER_ROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]
    working_dir: /opt/gopath/src/github.com/hyperledger/fabric
    command: orderer
	volumes:
	  - ../channel-artifacts/genesis.block:/var/hyperledger/orderer/orderer.genesis.block
	  - ../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp:/var/hyperledger/orderer/msp
	  - ../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/:/var/hyperledger/orderer/tls
      - orderer.example.com:/var/hyperledger/production/orderer
    ports:
      - 7050:7050
    networks:
      - byfn
```



## 问题

```
问题：
1、如何吊销用户？

2、为什么命名为genesis.block？其他命名可以？什么时候使用到？ 
```

