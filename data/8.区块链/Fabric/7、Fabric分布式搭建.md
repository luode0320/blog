# Fabric分布式搭建

[](https://gitee.com/helloxmz/fabric-test-network-construct)

[Hyperledger Fabric Docker 方式多机部署生产网络](https://my.oschina.net/j4love/blog/5454098)

# 多机搭建前准备

所需要的环境包括 `docker`的安装 `golang`的安装 `fabric`的安装等。

# 网络结构

我们要搭建一个多机多节点的网络，结构如下。网络中有两个组织分别为 `org1`、`org2`，每个组织各有一个 `peer`节点，同时还有一个 `orderer`节点

| 名称      | IP            | hosts                          | 组织结构 |
| --------- | ------------- | ------------------------------ | -------- |
| Orderer   | 192.168.1.171 | http://orderer.example.com/    | orderer  |
| Org1peer0 | 192.168.1.171 | http://peer0.org1.example.com/ | org1     |
| Org2peer0 | 192.168.1.172 | http://peer0.org2.example.com/ | org2     |

# 设置网络host

配置所有服务器网络host,在三台虚拟机中都进行以下操作。

```bash
cat >> /etc/hosts << EOF
192.168.1.171 orderer.example.com
192.168.1.172 peer0.org1.example.com
192.168.1.173 peer0.org2.example.com
EOF
```

# 创建项目目录

在三台虚拟机上使用以下命令创建相同的项目目录（三台虚拟机项目路径要相同）。

# 生成Fabric证书

```bash
mkdir -p ~/hyperledgermkdir/multinodes
```

## 编写证书文件

```bash
cd ~/hyperledger/multinodes
# 使用以下命令将模板文件复制到当前目录下
cryptogen showtemplate > crypto-config.yaml
```

将配置文件进行修改，修改如下。

```bash
# 排序节点
OrdererOrgs:

    - Name: Orderer     #  定义Orderer组织结构
      Domain: example.com   #  组织的命名域
      EnableNodeOUs: true   # 如果设置了EnableNodeOUs，就在msp下生成config.yaml文件

#    Specs 规范条目。每个规范条目由两个字段组成：Hostname 和 CommonName
#    Hostname 表示组织中节点的主机名称。CommonName 是一个可选参数，可以通过重写来指定节点的名称。如果不指定 CommonName，则其节点默认的名称为{{.Hostname}}.{{.Domain}}
      Specs:
          # 表示组织中节点的主机名称
          - Hostname: orderer
# 对等节点
PeerOrgs:

    # 。Template 下的 Count 指的是该组织下组织节点的个数.Users 指的是该组织中除了 Admin 之外的用户的个数。
    - Name: org1
      # 域名
      Domain: org1.example.com
      # true 表示在msp目录下生成config.yaml文件
      EnableNodeOUs: true
      Template:
          # 组织下peer节点个数
          Count: 2
      #  表示生成几个 普通User
      Users:
          Count: 1

    - Name: org2
      Domain: org2.example.com
      EnableNodeOUs: true
      Template:
          Count: 1
      Users:
          Count: 1
```

## 生成证书文件

```bash
# 使用以下命令生成证书文件。
cryptogen generate --config=crypto-config.yaml
```

使用 `ls`命令查看生成的文件，可以看到生成了 `crypto-config`文件，这里存放所有的证书文件。

![Untitled](Fabric%E5%88%86%E5%B8%83%E5%BC%8F%E6%90%AD%E5%BB%BA%2045ac46874038437cbc5fd3e2a4a44073/Untitled%201.png)

使用 `scp`命令将证书文件复制到其他两台虚拟机中

```bash
scp -r ./crypto-config root@172.17.0.11:~/hyperledger/multinodes/
```

![Untitled](Fabric%E5%88%86%E5%B8%83%E5%BC%8F%E6%90%AD%E5%BB%BA%2045ac46874038437cbc5fd3e2a4a44073/Untitled%202.png)

# 生成通道文件

## **创世块文件的编写**

首先回到orderer节点的虚拟机。

首先我们可以参考官方示例项目 `test-network`中的 `configtx.yaml`配置文件。

将 `configtx.yaml`改为以下内容。

```bash
---
# 重复的内容在 YAML 中可以使用&来完成锚点定义，使用*来完成锚点引用
# 在这六个部分中，Profile 部分，主要是引用其余五个部分的参数。configtxgen 通过调用 Profile 参数，可以实现生成特定的区块文件。
#组织机构配置：定义了不同的组织标志，这些标志将在 Profile 部分被引用。
Organizations:

    - &OrdererOrg

        Name: OrdererOrg    # 组织名称
        ID: OrdererMSP      # 组织ID，ID是引用组织的关键
        MSPDir: ./crypto-config/ordererOrganizations/example.com/msp    # 组织的MSP证书路径
        # 定义本层级的组织策略，其权威路径为 /Channel/<Application|Orderer>/<OrgName>/<PolicyName>
        Policies:
            Readers:
                Type: Signature
                Rule: "OR('OrdererMSP.member')"
            Writers:
                Type: Signature
                Rule: "OR('OrdererMSP.member')"
            Admins:
                Type: Signature
                Rule: "OR('OrdererMSP.admin')"
        OrdererEndpoints:
            - orderer0.example.com:7050

    - &Org1

        Name: Org1MSP
        ID: Org1MSP
        MSPDir: ./crypto-config/peerOrganizations/org1.example.com/msp
        Policies:
            Readers:
                Type: Signature
                Rule: "OR('Org1MSP.admin', 'Org1MSP.peer', 'Org1MSP.client')"
            Writers:
                Type: Signature
                Rule: "OR('Org1MSP.admin', 'Org1MSP.client')"
            Admins:
                Type: Signature
                Rule: "OR('Org1MSP.admin')"
            Endorsement:
                Type: Signature
                Rule: "OR('Org1MSP.peer')"
        # 定义组织的锚节点
        AnchorPeers:
            - Host: peer0.org1.example.com  # 锚节点的host地址
              Port: 7051        # 锚节点开放的端口号

    - &Org2

        Name: Org2MSP
        ID: Org2MSP
        MSPDir: ./crypto-config/peerOrganizations/org2.example.com/msp
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
            - Host: peer0.org2.example.com
              Port: 7051

#该部分用户定义 Fabric 网络的功能。
#Capabilities段定义了fabric程序要加入网络所必须支持的特性。
#例如，如果添加了一个新的MSP类型，那么更新的程序可能会根据该类型识别并验证签名，
#    但是老版本的程序就没有办法验证这些交易。这可能导致不同版本的fabric程序中维护的世界状态不一致。
Capabilities:
    # Channel配置同时应用于orderer节点与peer节点，并且必须被两种节点同时支持
    # 将该配置项设置为ture表明要求节点具备该能力,false则不要求该节点具备该能力
    Channel: &ChannelCapabilities

        V2_0: true

    # Orderer功能仅适用于orderers，可以安全地操作，而无需担心升级peers
    # 将该配置项设置为ture表明要求节点具备该能力,false则不要求该节点具备该能力
    Orderer: &OrdererCapabilities

        V2_0: true

    # 应用程序功能仅适用于Peer网络，可以安全地操作，而无需担心升级或更新orderers
    # 将该配置项设置为ture表明要求节点具备该能力,false则不要求该节点具备该能力
    Application: &ApplicationCapabilities

        V2_0: true

#  应用配置：Application配置段用来定义要写入创世区块或配置交易的应用参数。
#  该部分定义了交易配置相关的值，以及包含和创世区块相关的值。
Application: &ApplicationDefaults   #  自定义被引用的地址

    # Organizations配置列出参与到网络中的机构清单
    Organizations:

    # 定义本层级的应用控制策略，其权威路径为 /Channel/Application/<PolicyName>
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
Orderer: &OrdererDefaults

    # 排序节点类型用来指定要启用的排序节点实现，不同的实现对应不同的共识算法。
    # 目前可用的类型为：solo，kafka，EtcdRaft
    OrdererType: solo
    # 服务地址,这个地方很重要，一定要配正确
    Addresses:
        - orderer0.example.com:7050

    EtcdRaft:
        Consenters:
            - Host: orderer0.example.com
              Port: 7050
              ClientTLSCert: ./crypto-config/ordererOrganizations/example.com/orderers/orderer0.example.com/tls/server.crt
              ServerTLSCert: ./crypto-config/ordererOrganizations/example.com/orderers/orderer0.example.com/tls/server.crt

    # 区块打包的最大超时时间 (到了该时间就打包区块)
    BatchTimeout: 5s
    # 区块打包的最大包含交易数（orderer端切分区块的参数）
    BatchSize:
        MaxMessageCount: 10         # 一个区块里最大的交易数
        AbsoluteMaxBytes: 99 MB     # 一个区块的最大字节数，任何时候都不能超过
        PreferredMaxBytes: 512 KB   # 一个区块的建议字节数，如果一个交易消息的大小超过了这个值, 就会被放入另外一个更大的区块中
    # 【可选项】表示Orderer允许的最大通道数， 默认0表示没有最大通道数
    MaxChannels: 0
    # 参与维护Orderer的组织，默认为空
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

    # TwoOrgsOrdererGenesis用来生成orderer启动时所需的block，用于生成创世区块，名字可以任意
    # 需要包含Orderer和Consortiums两部分
    TwoOrgsOrdererGenesis:
        <<: *ChannelDefaults    # 通道为默认配置，这里直接引用上面channel配置段中的ChannelDefaults
        Orderer:
            <<: *OrdererDefaults    # Orderer为默认配置，这里直接引用上面orderer配置段中的OrdererDefaults
            Organizations:      # 这里直接引用上面Organizations配置段中的OrdererOrg
                - *OrdererOrg
            Capabilities:       # 这里直接引用上面Capabilities配置段中的OrdererCapabilities
                <<: *OrdererCapabilities
        # 联盟为默认的 SampleConsortium 联盟，添加了两个组织，表示orderer所服务的联盟列表
        Consortiums:
            #  创建更多应用通道时的联盟引用 TwoOrgsChannel 所示
            SampleConsortium:
                Organizations:
                    - *Org1
                    - *Org2
    # TwoOrgsChannel用来生成channel配置信息，名字可以任意
    # 需要包含Consortium和Applicatioon两部分。
    TwoOrgsChannel:
        # 通道所关联的联盟名称
        Consortium: SampleConsortium
        <<: *ChannelDefaults    # 通道为默认配置，这里直接引用上面channel配置段中的ChannelDefaults
        Application:
            <<: *ApplicationDefaults    # 这里直接引用上面Application配置段中的ApplicationDefaults
            Organizations:
                - *Org1
                - *Org2
            Capabilities:
                <<: *ApplicationCapabilities    # 这里直接引用上面Capabilities配置段中的ApplicationCapabilities
```

与单节点搭建的区别：

- Organizations部分多了Org2的配置。
- Profiles的部分创世块名称与通道名称不同。单节点搭建部分为soloOrgsOrdererGenesis和soloOrgsChannel，多节点搭建部分为TwoOrgsOrdererGenesis和TwoOrgsChannel。（创世块名称与通道名称自己任意取，但是后面使用命令生成文件时命令要与配置文件所定义的名称一致）
- Profiles部分创世块配置与通道配置中都多加入了Org2。

## **生成创世块文件和通道文件**

```bash
#使用以下命令生成创世区块。
configtxgen -profile TwoOrgsOrdererGenesis -channelID fabric-channel -outputBlock ./channel-artifacts/genesis.block
#使用以下命令生成通道文件。
configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID mychannel
#使用以下命令为 Org1 定义锚节点。
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID mychannel -asOrg Org1MSP
#使用以下命令为 Org2 定义锚节点。
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx -channelID mychannel -asOrg Org2MSP
```

![Untitled](Fabric%E5%88%86%E5%B8%83%E5%BC%8F%E6%90%AD%E5%BB%BA%2045ac46874038437cbc5fd3e2a4a44073/Untitled%203.png)

使用以下命令将生成的文件拷贝到另一台主机

```bash
scp -r ./channel-artifacts root@192.168.1.172:~/hyperledger/multinodes/
```

# docker-compose.yaml文件编写

在单节点中我们编写过一个docker-compose文件，在其中我们配置了orderer节点与peer节点。在多机部署的时候我们需要为每台虚拟机都编写一个docker-compose文件来配置相应的节点。多机部署与单机部署的配置文件内容大致相同，下面会介绍单机与多机的异同点。

## **orderer节点**

使用以下命令在orderer节点的虚拟机的项目路径上创建一个 `orderer.yaml`文件。

```bash
cd ~/hyperledger/multinodes
vim orderer.ayml
```

写入以下内容后，保存退出文件。

```bash
version: '2'

networks:
    mynet:
        driver: bridge

services:
    orderer.example.com:
        container_name: orderer.example.com
        image: hyperledger/fabric-orderer:latest
        environment:
            - FABRIC_LOGGING_SPEC=INFO
            - ORDERER_GENERAL_LISTENADDRESS=0.0.0.0
            - ORDERER_GENERAL_LISTENPORT=7050
            - ORDERER_GENERAL_GENESISMETHOD=file
            - ORDERER_GENERAL_GENESISFILE=/var/hyperledger/orderer/orderer.genesis.block
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
        working_dir: /opt/gopath/src/github.com/hyperledger/fabric
        command: orderer
        volumes:
            - ./channel-artifacts/genesis.block:/var/hyperledger/orderer/orderer.genesis.block
            - ./crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp:/var/hyperledger/orderer/msp
            - ./crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/:/var/hyperledger/orderer/tls
        ports:
            - 7050:7050
        extra_hosts:
            - "orderer.example.com:192.168.1.171"
            - "peer0.org1.example.com:192.168.1.171"
            - "peer0.org2.example.com:192.168.1.172"
        networks:
            - mynet
```

与单机搭建的不同：

- 没有了卷挂载目录 `orderer.example.com:/var/hyperledger/production/orderer`。
- 单机搭建中的网络名 `networks: - example`改为 `extra_hosts:`，因为我们是多机搭建有真实的IP，所以网络名称都改为真实的IP地址。

## **org1**

Fabric中peer节点的世界状态数据库默认是Leveldb，在这个部分我们将使用Couchdb。

Fabric的状态存储支持可插拔的模式，兼容LevelDB、CouchDB等存储。Fabric使用CouchDB作为状态存储与其他数据库相比具有较多优势

- CouchDB是一种NoSQL解决方案。它是一个面向文档的数据库，其中文档字段存储为键值映射。字段可以是简单的键值对、列表或映射。除了支持类似LevelDB的键控/合成键/键范围查询之外，CouchDB还支持完整的数据富查询功能，比如针对整个区块链数据的非键查询，因为它的数据内容是以JSON格式存储的，并且是完全可查询的。因此，CouchDB可以满足LevelDB不支持的许多用例的链代码、审计和报告需求。
- CouchDB还可以增强区块链中的遵从性和数据保护的安全性。因为它能够通过筛选和屏蔽事务中的各个属性来实现字段级别的安全性，并且只在需要时授权只读权限。
- CouchDB属于CAP定理的ap类型(可用性和分区公差)。它使用具有最终一致性的主-主复制模型。更多信息可以在CouchDB文档的最终一致性页面上找到。然而，在每个fabric对等点下，没有数据库副本，对数据库的写操作保证一致和持久(而不是最终的一致性)。
- CouchDB是Fabric的第一个外部可插入状态数据库，可以而且应该有其他外部数据库选项。例如，IBM为其区块链启用关系数据库。还可能需要cp类型(一致性和分区容忍度)的数据库，以便在不保证应用层的情况下实现数据一致性。

使用以下命令在org1节点的虚拟机的项目路径上创建一个 `org1.yaml`文件。

```bash
cd ~/hyperledger/multinodes
vim org1.yaml
```

```bash
version: '3'

networks:
    mynet:
        driver: bridge

services:
    couchdb0.org1.example.com:
        container_name: couchdb0.org1.example.com
        image: couchdb:2.1.1
        environment:
            - COUCHDB_USER=admin
            - COUCHDB_PASSWORD=adminpw
        ports:
            - 5984:5984
        volumes:
            - /etc/localtime:/etc/localtime
        networks:
            - mynet

    peer0.org1.example.com:
        container_name: peer0.org1.example.com
        image: hyperledger/fabric-peer:latest
        environment:
            - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
            - CORE_PEER_ID=peer0.org1.example.com
            - CORE_PEER_ADDRESS=peer0.org1.example.com:7051
            - CORE_PEER_LISTENADDRESS=0.0.0.0:7051
            - CORE_PEER_CHAINCODEADDRESS=peer0.org1.example.com:7052
            - CORE_PEER_CHAINCODELISTENADDRESS=0.0.0.0:7052
            - CORE_PEER_GOSSIP_BOOTSTRAP=peer0.org1.example.com:7051
            - CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer0.org1.example.com:7051
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
            - CORE_LEDGER_STATE_COUCHDBCONFIG_COUCHDBADDRESS=couchdb0.org1.example.com:5984
            - CORE_LEDGER_STATE_COUCHDBCONFIG_USERNAME=admin
            - CORE_LEDGER_STATE_COUCHDBCONFIG_PASSWORD=adminpw
        depends_on:
            - couchdb0.org1.example.com

        working_dir: /opt/gopath/src/github.com/hyperledger/fabric/peer
        command: peer node start
        volumes:
            - /var/run/:/host/var/run/
            - ./crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/msp:/etc/hyperledger/fabric/msp
            - ./crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls:/etc/hyperledger/fabric/tls
            - /etc/localtime:/etc/localtime
        ports:
            - 7051:7051
            - 7052:7052
            - 7053:7053
        extra_hosts:
            - "orderer0.example.com:192.168.1.135"
            - "peer0.org1.example.com:192.168.1.135"
            - "peer1.org1.example.com:192.168.1.135"
            - "peer0.org2.example.com:192.168.1.136"
            - "peer1.org2.example.com:192.168.1.136"
        networks:
            - mynet

    cli:
        container_name: cli
        image: hyperledger/fabric-tools:latest
        tty: true
        stdin_open: true
        environment:
            - GOPATH=/opt/gopath
            - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
            - FABRIC_LOGGING_SPEC=INFO
            - CORE_PEER_ID=cli
            - CORE_PEER_ADDRESS=peer0.org1.example.com:7051
            - CORE_PEER_LOCALMSPID=Org1MSP
            - CORE_PEER_TLS_ENABLED=true
            - CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/server.crt
            - CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/server.key
            - CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
            - CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
        working_dir: /opt/gopath/src/github.com/hyperledger/fabric/peer
        command: /bin/bash
        volumes:
            - /var/run/:/host/var/run/
            - ./chaincode/go/:/opt/gopath/src/github.com/hyperledger/fabric-cluster/chaincode/go/
            - ./crypto-config:/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/
            - ./channel-artifacts:/opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts
            - /etc/localtime:/etc/localtime
        extra_hosts:
            - "orderer0.example.com:192.168.1.135"
            - "peer0.org1.example.com:192.168.1.135"
            - "peer1.org1.example.com:192.168.1.135"
            - "peer0.org2.example.com:192.168.1.136"
            - "peer1.org2.example.com:192.168.1.136"
        networks:
            - mynet
```

与单机搭建的不同：

- 多了couchdb的配置。
- peer0节点环境变量多了 `CORE_LEDGER_STATE_STATEDATABASE=CouchDB`，表示peer0节点的状态数据库采用了couchdb。
- 多了 `depends_on: - couchdb0.org1.example.com`，表示在couchdb启动后再启动peer0节点。
- 单机搭建中的网络名 `networks: - example`改为 `extra_hosts:`，因为我们是多机搭建有真实的IP，所以网络名称都改为真实的IP地址。

## org2

组织二的配置文件与组织一基本相同，唯一不同点是把org1改为org2。

使用以下命令在org2节点的虚拟机的项目路径上创建一个 `org2.yaml`文件。

```bash
cd ~/hyperledger/multinodes
vim org2.yaml
```

写入以下内容后，保存退出文件。

```bash
version: '3'

networks:
    mynet:
        driver: bridge

services:
    couchdb0.org2.example.com:
        container_name: couchdb0.org2.example.com
        image: couchdb:2.1.1
        environment:
            - COUCHDB_USER=admin
            - COUCHDB_PASSWORD=adminpw
        ports:
            - 5984:5984
        volumes:
            - /etc/localtime:/etc/localtime
        networks:
            - mynet

    peer0.org2.example.com:
        container_name: peer0.org2.example.com
        image: hyperledger/fabric-peer:latest
        environment:
            - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
            - CORE_PEER_ID=peer0.org2.example.com   #设置对等节点实例的标识ID。
            - CORE_PEER_ADDRESS=peer0.org2.example.com:7051 #同一机构中其他Peer节点要连接此节点需指定的P2P连接地址
            - CORE_PEER_LISTENADDRESS=0.0.0.0:7051  #设置或读取对等节点的监听地址。默认情况下Peer节点在所有地址上监听请求。
            - CORE_PEER_CHAINCODEADDRESS=peer0.org2.example.com:7052    #链码连接该Peer节点的地址。
            - CORE_PEER_CHAINCODELISTENADDRESS=0.0.0.0:7052 #Peer节点监听链码连接请求的地址。如果未设置该参数，将自动选择 节点地址的7052端口。
            - CORE_PEER_GOSSIP_BOOTSTRAP=peer0.org2.example.com:7051 #设置初始化gossip的引导节点列表，节点启动时将连接 这些引导节点。
            - CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer0.org2.example.com:7051 #向机构外的节点发布的访问端结点。如果未设置该参数，节点 将不为其他机构所知。
            - CORE_PEER_LOCALMSPID=Org2MSP
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
            - CORE_LEDGER_STATE_COUCHDBCONFIG_COUCHDBADDRESS=couchdb0.org2.example.com:5984
            - CORE_LEDGER_STATE_COUCHDBCONFIG_USERNAME=admin
            - CORE_LEDGER_STATE_COUCHDBCONFIG_PASSWORD=adminpw
        depends_on:
            - couchdb0.org2.example.com

        working_dir: /opt/gopath/src/github.com/hyperledger/fabric/peer
        command: peer node start
        volumes:
            - /var/run/:/host/var/run/
            - ./crypto-config/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/msp:/etc/hyperledger/fabric/msp
            - ./crypto-config/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls:/etc/hyperledger/fabric/tls
            - /etc/localtime:/etc/localtime
        ports:
            - 7051:7051
            - 7052:7052
            - 7053:7053
        extra_hosts:
            - "orderer0.example.com:192.168.1.135"
            - "peer0.org1.example.com:192.168.1.135"
            - "peer1.org1.example.com:192.168.1.135"
            - "peer0.org2.example.com:192.168.1.136"
            - "peer1.org2.example.com:192.168.1.136"
        networks:
            - mynet

    cli:
        container_name: cli
        image: hyperledger/fabric-tools:latest
        tty: true
        stdin_open: true
        environment:
            - GOPATH=/opt/gopath
            - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
            - FABRIC_LOGGING_SPEC=INFO
            - CORE_PEER_ID=cli
            - CORE_PEER_ADDRESS=peer0.org2.example.com:7051
            - CORE_PEER_LOCALMSPID=Org2MSP
            - CORE_PEER_TLS_ENABLED=true
            - CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/server.crt
            - CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/server.key
            - CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
            - CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
        working_dir: /opt/gopath/src/github.com/hyperledger/fabric/peer
        command: /bin/bash
        volumes:
            - /var/run/:/host/var/run/
            - ./chaincode/go/:/opt/gopath/src/github.com/hyperledger/fabric-cluster/chaincode/go
            - ./crypto-config:/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/
            - ./channel-artifacts:/opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts
            - /etc/localtime:/etc/localtime
        extra_hosts:
            - "orderer0.example.com:192.168.1.135"
            - "peer0.org1.example.com:192.168.1.135"
            - "peer1.org1.example.com:192.168.1.135"
            - "peer0.org2.example.com:192.168.1.136"
            - "peer1.org2.example.com:192.168.1.136"
        networks:
            - mynet
```

# 通道操作

主要介绍的 `peer channel`命令，`peer channel`命令主要是用于创建通道以及节点加入通道。

- `o`,`-orderer`: orderer节点的地址。
- `c`, `-channelID`: 要创建的通道的ID, 必须小写, 在250个字符以内。
- `f`, `file`: 由 `configtxgen`生成的通道文件, 用于提交给orderer。
- `t`, `-timeout`: 创建通道的超时时长, 默认为5s。
- `-tls`: 通信时是否使用tls加密。
- `-cafile`: 当前orderer节点pem格式的tls证书文件, 要使用绝对路径。

## 创建通道

```bash
#使用docker exec命令进入客户端容器（在Org1主机上操作）。
docker exec -it cli bash
#使用以下命令在客户端容器中创建通道（在Org1容器上操作）。
docker exec -it cli bash
#使用以下命令在客户端容器中创建通道，并生成配置文件（在Org1容器上操作）
peer channel create -o orderer.example.com:7050 -c mychannel -f ./channel-artifacts/channel.tx --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/msp/tlscacerts/tlsca.example.com-cert.pem
=========================================================================			
				-o,--orderer: orderer节点的地址。
				-c, --channelID: 要创建的通道的ID, 必须小写, 在250个字符以内。
				-f, -file: 由configtxgen生成的通道文件, 用于提交给orderer。
				-t, --timeout: 创建通道的超时时长, 默认为5s。
				--tls: 通信时是否使用tls加密。
				--cafile: 当前orderer节点pem格式的tls证书文件, 要使用绝对路径。
				orderer节点pem格式的tls证书文件路径为：crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem。
```

![Untitled](Fabric%E5%88%86%E5%B8%83%E5%BC%8F%E6%90%AD%E5%BB%BA%2045ac46874038437cbc5fd3e2a4a44073/Untitled%204.png)

```bash
#使用以下命令将通道文件 mychannel.block 拷贝到宿主机（在Org1主机上操作）。
docker cp cli:/opt/gopath/src/github.com/hyperledger/fabric/peer/mychannel.block ./
#然后使用以下命令拷贝到其他服务器上用于其他节点加入通道（在Org1主机上操作）。
scp mychannel.block root@192.168.1.172:~/hyperledger/multinodes/
#使用以下命令将通道文件拷贝到容器中（在Org2主机上操作）。
docker cp mychannel.block cli:/opt/gopath/src/github.com/hyperledger/fabric/peer/
#使用以下命令进入 cli容器（在Org2主机上操作）。
docker exec -it cli bash
```

## 加入通道

将每个组织的每个节点都加入到通道中需要客户端来完成，一个客户端同时只能连接一个peer节点, 如果想要该客户端连接其他节点, 那么就必须修改当前客户端中相关的环境变量。我们当前在 `docker-compose.yaml`文件中所配置的 `cli`连接的是Go组织的 `peer0`节点。

```bash
#使用以下命令让peer0节点加入通道（在Org1和Org2容器上操作）。
peer channel join -b mychannel.block
		#参数解释 -b, --blockpath: block文件路径（通过 peer channel create 命令生成的通道文件）。
```

输出如下，此时组织的 `peer0`已经加入通道。

`> INFO 002 Successfully submitted proposal to join channel`

## 更新锚节点

锚节点配置更新后，同一通道内不同组织之间的 Peer 也可以进行 Gossip 通信，共同维护通道账本。后续，用户可以通过智能合约使用通道账本。

```bash
#使用以下命令来更新锚节点（在org1容器上操作）。
peer channel update -o orderer.example.com:7050 -c mychannel -f ./channel-artifacts/Org1MSPanchors.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
#使用以下命令来更新锚节点（在org2容器上操作）
peer channel update -o orderer.example.com:7050 -c mychannel -f ./channel-artifacts/Org2MSPanchors.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
```

- `o`,`-orderer`:`orderer`节点的地址。
- `c`, `-channelID`: 要创建的通道的ID, 必须小写, 在250个字符以内。
- `f`, `file`: 由 `cryptogen`生成的锚节点文件。

# 安装智能合约

```bash
#进入org1虚拟机。首先我们使用以下命令在项目路径下创建一个文件夹名为chaincode。
mkdir chaincode
#然后使用以下命令将官方示例的智能合约复制到我们刚刚创建的chaincode文件夹中。
cd ~/hyperledger/fabric-samples/chaincode
cp -r sacc ~/hyperledger/multinodes/chaincode/go/
#使用以下命令进入容器。
docker exec -it cli bash
#使用以下命令进入链码所在目录。
cd /opt/gopath/src/github.com/hyperledger/fabric-cluster/chaincode/go/sacc
#使用以下命令设置go语言依赖包。
go env -w GOPROXY=https://goproxy.cn,direct
go mod vendor
#使用以下命令回到peer目录下。
cd /opt/gopath/src/github.com/hyperledger/fabric/peer
#Fabric生命周期将链码打包在易于阅读的tar文件中，方便协调跨多个组织的安装，使用以下命令打包链码。
peer lifecycle chaincode package sacc.tar.gz   --path /opt/gopath/src/github.com/hyperledger/fabric-cluster/chaincode/go/sacc   --label sacc_1
#使用以下命令退出容器，并将打包好的链码复制到Org2虚拟机中。
exit
docker cp cli:/opt/gopath/src/github.com/hyperledger/fabric/peer/sacc.tar.gz ./ scp sacc.tar.gz root@172.10.0.12:~/hyperledger/multinodes
#使用以下命令分别在两个组织的虚拟机上安装链码（Org1和Org2的虚拟机中都要进行以下操作）
peer lifecycle chaincode install sacc.tar.gz

#使用以下命令查询链码（Org1和Org2的虚拟机中都要进行以下操作）。
peer lifecycle chaincode queryinstalled
#使用以下命令批准链码（Org1和Org2的虚拟机中都要进行以下操作，其中链码的ID要根据上面查询的结果替换到下面的命令中）。
peer lifecycle chaincode approveformyorg --channelID mychannel --name sacc --version 1.0 --init-required --package-id sacc_1:cf82a5d3da433c3fd0043a5be0c64eca0198e3019169186023f75bf6d223437d --sequence 1 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
#使用以下命令查看链码是否就绪（Org1和Org2的虚拟机中都要进行以下操作）。
peer lifecycle chaincode checkcommitreadiness --channelID mychannel --name sacc --version 1.0 --init-required --sequence 1 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --output json
#使用以下命令提交链码（在组织一或者组织二上）。
peer lifecycle chaincode commit -o orderer.example.com:7050 --channelID mychannel --name sacc --version 1.0 --sequence 1 --init-required --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
#使用以下命令将链码初始化，连码只能初始化一次
peer chaincode invoke -o orderer.example.com:7050 --isInit --ordererTLSHostnameOverride orderer.example.com --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n sacc --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"Args":["a","bb"]}'
		#成功输出：INFO 001 Chaincode invoke successful. result: status:200
#使用以下命令查询数据。
peer chaincode query -C mychannel -n sacc -c '{"Args":["query","a"]}'
		#成功输出：bb
#使用以下命令调用链码，新增数据。
peer chaincode invoke -o orderer.example.com:7050 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n sacc --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"Args":["set","a","cc"]}'
		#成功输出：INFO 001 Chaincode invoke successful. result: status:200 payload:"cc"
#使用以下命令查询数据。
peer chaincode query -C mychannel -n sacc -c '{"Args":["query","a"]}'
		#成功输出：cc

```

# **搭建hyperledger explorer区块链浏览器**

## docker-compose.yaml文件

```yaml
version: '3'

networks:
    mynet:
        driver: bridge

services:
    explorerdb.mynetwork.com:
        image: hyperledger/explorer-db:latest
        container_name: explorerdb.mynetwork.com
        hostname: explorerdb.mynetwork.com
        environment:
            - DATABASE_DATABASE=fabricexplorer
            - DATABASE_USERNAME=hppoc
            - DATABASE_PASSWORD=password
            - DISCOVERY_AS_LOCALHOST=false
        healthcheck:
            test: "pg_isready -h localhost -p 5432 -q -U postgres"
            interval: 30s
            timeout: 10s
            retries: 5
        volumes:
            - ./pgdata:/var/lib/postgresql/data
            - /etc/localtime:/etc/localtime
        networks:
            - mynet

    explorer.mynetwork.com:
        image: hyperledger/explorer:1.1.5
        container_name: explorer.mynetwork.com
        hostname: explorer.mynetwork.com
        environment:
            - DATABASE_HOST=explorerdb.mynetwork.com
            - DATABASE_DATABASE=fabricexplorer
            - DATABASE_USERNAME=hppoc
            - DATABASE_PASSWD=password
            - LOG_LEVEL_APP=info
            - LOG_LEVEL_DB=info
            - LOG_LEVEL_CONSOLE=debug
            - LOG_CONSOLE_STDOUT=true
            - DISCOVERY_AS_LOCALHOST=false
        volumes:
            - ./config.json:/opt/explorer/app/platform/fabric/config.json
            - ./connection-profile:/opt/explorer/app/platform/fabric/connection-profile
            - ./crypto-config:/tmp/crypto
            - ./walletstore:/opt/explorer/wallet
            - /etc/localtime:/etc/localtime
        ports:
            - 8080:8080
        depends_on:
            - explorerdb.mynetwork.com
        extra_hosts:
            - "orderer0.example.com:192.168.1.135"
            - "peer0.org1.example.com:192.168.1.135"
            - "peer1.org1.example.com:192.168.1.135"
            - "peer0.org2.example.com:192.168.1.136"
            - "peer1.org2.example.com:192.168.1.136"
        networks:
            - mynet
```

## config.json文件

```json
{
	"network-configs": {
		"org1-network": {
			"name": "Org1 Network",
			"profile": "./connection-profile/org1-network.json"
		},
		"org2-network": {
                        "name": "Org2 Network",
                        "profile": "./connection-profile/org2-network.json"
                }
	},
	"license": "Apache-2.0"
}
```

## org1-network.json

```json
{
  "name": "org1-network",
  "version": "1.0.0",
  "client": {
    "tlsEnable": true,
    "adminCredential": {
      "id": "exploreradmin",
      "password": "exploreradminpw"
    },
    "enableAuthentication": true,
    "organization": "Org1MSP",
    "connection": {
      "timeout": {
        "peer": {
          "endorser": "300"
        },
        "orderer": "300"
      }
    }
  },
  "channels": {
    "mychannel": {
      "peers": {
        "peer0.org1.example.com": {},
        "peer1.org1.example.com": {}
      }
    }
  },
  "organizations": {
    "Org1MSP": {
      "mspid": "Org1MSP",
      "adminPrivateKey": {
        "path": "/tmp/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/priv_sk"
      },
      "peers": [
        "peer0.org1.example.com",
        "peer1.org1.example.com"
      ],
      "signedCert": {
        "path": "/tmp/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/cert.pem"
      }
    }
  },
  "peers": {
    "peer0.org1.example.com": {
      "tlsCACerts": {
        "path": "/tmp/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
      },
      "url": "grpcs://peer0.org1.example.com:7051"
    },
    "peer1.org1.example.com": {
      "tlsCACerts": {
        "path": "/tmp/crypto/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/tls/ca.crt"
      },
      "url": "grpcs://peer1.org1.example.com:7151"
    }
  }
}
```

## org2-network.json

```json
{
  "name": "org2-network",
  "version": "1.0.0",
  "client": {
    "tlsEnable": true,
    "adminCredential": {
      "id": "exploreradmin",
      "password": "exploreradminpw"
    },
    "enableAuthentication": true,
    "organization": "Org2MSP",
    "connection": {
      "timeout": {
        "peer": {
          "endorser": "300"
        },
        "orderer": "300"
      }
    }
  },
  "channels": {
    "mychannel": {
      "peers": {
        "peer0.org2.example.com": {},
        "peer1.org2.example.com": {}
      }
    }
  },
  "organizations": {
    "Org2MSP": {
      "mspid": "Org2MSP",
      "adminPrivateKey": {
        "path": "/tmp/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp/keystore/priv_sk"
      },
      "peers": [
        "peer0.org2.example.com",
        "peer1.org2.example.com"
      ],
      "signedCert": {
        "path": "/tmp/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp/signcerts/cert.pem"
      }
    }
  },
  "peers": {
    "peer0.org2.example.com": {
      "tlsCACerts": {
        "path": "/tmp/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"
      },
      "url": "grpcs://peer0.org2.example.com:7051"
    },
    "peer1.org2.example.com": {
      "tlsCACerts": {
        "path": "/tmp/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"
      },
      "url": "grpcs://peer1.org2.example.com:7151"
    }
  }
}
```

# fabric日志管理

此步骤不是必需的，但对链码进行故障诊断非常有用。要监控智能合同的日志，管理员可以使用 `logspout`[工具](https://links.jianshu.com/go?to=https%3A%2F%2Flogdna.com%2Fwhat-is-logspout%2F)查看一组Docker容器的聚合输出。该工具将来自不同Docker容器的输出流收集到一个地方，以便于从单个窗口查看正在发生的事情。这可以帮助管理员在安装智能合同时调试问题，帮助开发人员在调用智能合同时调试问题。由于一些容器的创建纯粹是为了启动智能合同，并且只存在很短的时间，因此从您的网络收集所有日志是有帮助的。

```bash
docker run -d --name="logspout" \
        --volume=/var/run/docker.sock:/var/run/docker.sock \
        --publish=127.0.0.1:8001:80 \
        --network  fabric_net \
        gliderlabs/logspout
sleep 3
curl http://127.0.0.1:8001/logs
```

# **Fabric的运维服务与可视化监控**

[Hyperledger Fabric的运维服务与可视化监控【Prometheus/StatsD】](http://blog.hubwiz.com/2019/12/26/hyperledger-fabric-monitoring/)

```bash
docker run -d\
 --name graphite\
 --restart=always\
 --network  fabric_net \
 -p 80:80\
 -p 2003-2004:2003-2004\
 -p 2023-2024:2023-2024\
 -p 8125:8125/udp\
 -p 8126:8126\
 graphiteapp/graphite-statsd
```
