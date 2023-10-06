# Fabric CA理论支撑

[9-HyperLedger-Fabric原理-MSP详解（一）-MSP基础](https://zhuanlan.zhihu.com/p/35683522)

**Fabric CA（Certificate Authority）是Hyperledger Fabric项目中的一部分，用于管理Fabric网络中的身份认证和证书签名。**

Fabric CA提供了以下功能：

1. 身份注册和管理：Fabric CA允许用户注册、注销和管理身份，包括Peer、Orderer、客户端以及其他组织的用户身份。
2. 证书签名和管理：Fabric CA为身份颁发数字证书，同时也能够管理和吊销这些证书。
3. 权限控制：Fabric CA使用访问控制列表（ACL）来限制对其功能的访问。只有授权用户才能进行身份管理和证书签名操作。
4. 多租户支持：Fabric CA支持多个租户的管理和隔离，每个租户可以有自己的一套证书和密钥，以及自己的ACL列表。
5. 可插拔性：Fabric CA支持使用不同的数据库、密钥管理器和加密算法，以满足不同的部署需求和安全要求。
6. 安全性：Fabric CA使用公钥基础设施（PKI）来保证身份和证书的安全性。证书签名和验证使用公钥密码学算法，以确保身份的真实性和完整性。

总的来说，Fabric CA为Fabric网络提供了安全、可靠的身份认证和证书管理功能，为区块链应用程序提供了基础的安全保障。

**Fabric CA使用证书来进行身份认证。在Fabric网络中，每个节点和客户端都需要拥有一个数字证书，证书用于证明其身份。**

下面是Fabric CA进行身份认证的基本流程：

1. 注册身份：首先，客户端需要向CA注册身份，包括创建一个私钥和证书签名请求（CSR），并将其发送给CA。
2. 颁发证书：CA使用其私钥对CSR进行签名，生成一个数字证书并返回给客户端。该证书包含客户端的公钥、名称和其他元数据。
3. 证书验证：客户端使用证书验证自己的身份。在Fabric网络中，节点和客户端都会将自己的证书发送给目标节点或客户端进行身份验证。
4. ACL验证：在身份验证成功后，CA还会使用访问控制列表（ACL）验证客户端是否有权访问目标资源。

Fabric CA支持多种证书类型，包括X.509证书和ECert（enrollment certificate）。ECert是Fabric中专门用于身份验证的证书类型，它包含有关客户端的详细信息，如名称、角色和属性等。Fabric CA还支持使用不同的证书管理和密钥管理方案，以满足不同的部署需求和安全要求。

总之，Fabric CA使用数字证书和ACL来保证Fabric网络中节点和客户端的身份认证和访问控制。

**在Hyperledger Fabric中，使用Fabric CA（Certificate Authority）来管理证书的颁发和撤销。当客户端需要证书时，可以使用Fabric CA客户端（fabric-ca-client）来从CA服务器中拉取证书。**

具体而言，使用Fabric CA客户端拉取的证书类型取决于所请求的证书类型。以下是常见的证书类型及其对应的拉取操作：

1. 注册证书（Enrollment Certificate）：注册证书是用于身份验证的证书，由Fabric CA颁发给客户端。拉取注册证书需要提供客户端的身份标识和私钥，以及Fabric CA服务器的地址和端口。在拉取注册证书时，客户端会向Fabric CA服务器发送证书签名请求（Certificate Signing Request，CSR），并将其与客户端的私钥一起发送给服务器。Fabric CA服务器会验证客户端的身份，并颁发一个注册证书，该证书包含客户端的身份信息和公钥。
2. 根证书（Root Certificate）：根证书是用于验证其他证书的证书，由Fabric CA颁发给组织（Organization）或CA管理员。拉取根证书需要提供Fabric CA服务器的地址和端口，以及要拉取的证书类型。在拉取根证书时，客户端会从Fabric CA服务器下载一个根证书文件，用于验证其他证书的有效性。
3. 中间证书（Intermediate Certificate）：中间证书是用于建立信任链的证书，由Fabric CA颁发给组织或CA管理员。拉取中间证书需要提供Fabric CA服务器的地址和端口，以及要拉取的证书类型。在拉取中间证书时，客户端会从Fabric CA服务器下载一个中间证书文件，用于建立信任链。

# **crypto-config 文件夹的作用**

在 Hyperledger Fabric 网络中，每个参与者（如 Peer、Orderer、客户端）都有自己的身份，并且需要进行身份验证。为了保证网络的安全性，这些身份需要使用加密方式进行管理和传输。

**`crypto-config`** 文件夹是用来管理这些加密文件的文件夹。它包含了所有参与者的身份验证所需的证书和密钥，包括：

- 根证书（CA）：每个组织都有一个根证书，用于签署该组织的其他证书，如 TLS 证书、组织证书、节点证书等。根证书是一个非常重要的证书，因为它是整个组织的信任锚点。
- TLS 证书：在 Fabric 网络中，所有的通信都需要使用 TLS 协议进行加密，因此每个参与者都需要一个 TLS 证书，以确保通信的机密性和完整性。
- 组织证书：每个组织都需要一个组织证书，用于表示该组织的身份。组织证书通常包含组织名称、根证书的签名、组织的 MSP 配置等信息。
- 节点证书：每个节点（Peer、Orderer）都需要一个节点证书，用于表示该节点的身份。节点证书通常包含节点的名称、组织名称、公钥等信息。

这些证书和密钥需要按照一定的组织结构进行组织和存储。在 Fabric 中，使用 **`cryptogen`** 工具来生成这些加密文件，并将它们存储在 **`crypto-config`** 文件夹中。

**`crypto-config`** 文件夹的组织结构如下：

```bash
crypto-config/
├── ordererOrganizations/     # 定义所有的 Orderer 组织
│   ├── example.com/         # Orderer 组织的域名
│   │   ├── ca/              # Orderer 组织的根证书
│   │   ├── orderers/        # Orderer 节点的公钥和私钥
│   │   └── users/           # Orderer 组织中的用户公钥和私钥
└── peerOrganizations/       # 定义所有的 Peer 组织
    ├── org1.example.com/    # Peer 组织的域名
    │   ├── ca/              # Peer 组织的根证书
    │   ├── peers/           # Peer 节点的公钥和私钥
    │   └── users/           # Peer 组织中的用户公钥和私钥
    └── org2.example.com/    # 另一个 Peer 组织的域名
        ├── ca/              # Peer 组织的根证书
        ├── peers/           # Peer 节点的公钥和私钥
        └── users/           # Peer 组织中的用户公钥和私钥
```

其中，**`ordererOrganizations`** 和 **`peerOrganizations`** 分别代表 Orderer 和 Peer 所在的组织。在每个组织下，**`ca`** 目录存储组织的根证书、**`orderers`** 或 **`peers`** 目录分别存储该组织的 Orderer 或 Peer 的节点证书，**`tlsca`** 目录存储该组织的 TLS 证书。

总之，**`crypto-config`** 文件夹是 Hyperledger Fabric 中非常重要的一个文件夹，它包含了网络中的所有加密文件，是保证 Fabric 网络安全性的关键。

# Msp结构图

## A

[成员服务提供者 (MSP) - hyperledger-fabricdocs master 文档](https://hyperledger-fabric.readthedocs.io/zh_CN/latest/membership/membership.html)

![Untitled](../../../图片保存\Untitled.jpg)

*上图显示了本地MSP在文件系统中的子文件夹*

- **config.yaml:** 通过启用“Node OUs”和定义可接受的角色来配置Fabric中的身份分类特性。
- **cacerts:** 此文件夹包含此MSP代表的组织所信任的根CA的自签名X.509证书列表。此MSP文件夹中必须至少有一个根CA证书。

  这是最重要的文件夹，因为它确定了派生所有其他证书的必要CA，拥有这些证书才能被视为对应组织的成员，从而形成信任链。
- **intermediatecerts:** 此文件夹包含该组织所信任的中间CA的X.509证书列表。每个证书必须由MSP中的一个根CA，或者其本身颁发的CA链最终会指向一个受信任的根CA的任何中间CA，进行签名。

  一个中间CA可能代表组织的不同细分(如 `ORG1-MANUFACTURING`和 `ORG1-DISTRIBUTION`对应于 `ORG1`)，或者组织本身(如果商业CA被用于组织的身份管理，则可能是这种情况)。在后一种情况下，中间CA可以用来表示组织的细分。[这里](https://hyperledger-fabric.readthedocs.io/zh_CN/latest/msp.html)你可以找到关于MSP配置的最佳实践的更多信息。请注意，一个正常工作的网络可能没有中间CA，在这种情况下，这个文件夹将是空的。

  与根CA文件夹一样，该文件夹也定义了CA，且证书必须从该CA颁发，才能被视为组织的成员。
- **admincerts (在Fabric的1.4.3及以上版本被弃用):** 此文件夹包含一个身份列表，这些身份定义了具有此组织管理员角色的参与者。通常，这个列表中应该有一个或多个X.509证书。

  **注意:** 在Fabric v1.4.3之前，管理员是通过显式地将证书放在peer节点本地MSP目录的 `admincerts`文件夹中来被定义的。**Fabric的1.4.3及以上版本不再需要此文件夹中的证书。** 相反，建议在用户注册到CA时，使用 `admin`角色来指定节点管理员。然后，该标识被节点OU角色在它们的signcert中识别为 `admin`。提醒一下，为了使用管理员角色，必须在以上的config.yaml配置文件中，通过将“Node OUs”设置为 `Enable: true`来启用“identity classification”特性。我们稍后将进一步探讨这个问题。

  提醒一下，对于通道MSP，仅有参与者具有管理员角色这个条件，并不能说明他们可以管理特定的资源。给定身份在管理系统中拥有的实际权限是由管理系统资源的 *策略* 决定的。例如，通道策略可能指定 `ORG1-MANUFACTURING`管理员拥有向通道添加新组织的权限，而 `ORG1-DISTRIBUTION`管理员没有这样的权限。
- **keystore: (私钥)** 这个文件夹是为peer节点或排序节点的本地MSP(或客户端的本地MSP)定义的，其包含节点的私钥。此私钥用于签名数据——例如，作为背书阶段的一部分，用其签名交易提案响应。

  此文件夹对于本地MSP是强制性的，并且必须准确地包含一个私钥。显然，对该文件夹的访问必须仅限于对peer节点负有管理责任的用户。

  **通道MSP**配置不包含此文件夹，因为通道MSP仅提供身份验证功能，而不提供签名功能。

  **注意:** 如果您使用[硬件安全模块(HSM)](https://hyperledger-fabric.readthedocs.io/zh_CN/latest/hsm.html)进行私钥管理，此文件夹将为空，因为私钥由HSM生成并存储在HSM中。
- **signcert:** 对于 Peer 节点或排序节点(或在客户端的本地 MSP 中)，此文件夹包含 CA 发行的节点**签名密钥**。该证书表明节点的身份，与这个证书相对应的**私钥**可以用于生成签名，并且该签名可以被任何拥有这个证书的人验证。

  此文件夹对于本地 MSP是强制性的，并且必须包含一个准确的**公钥**。显然，对该文件夹的访问必须仅限于对 Peer 节点负有管理责任的用户。

  **通道 MSP**的配置不包含此文件夹，因为通道MSP仅提供身份验证功能，而不提供签名功能。
- **tlscacerts:** 此文件夹包含受此组织信任的根CA的自签名X.509证书列表，**用于进行节点之间基于TLS的安全通信**。TLS通信的一个例子是peer节点需要连接到排序节点，以便它能接收到账本更新数据。

  MSP和TLS信息与网络内的节点相关——peer节点和排序节点，换句话说，而不是与使用网络的应用程序和管理程序相关。

  此文件夹中必须至少有一个TLS根CA证书。有关TLS的更多信息，请参见[使用传输层安全协议(TLS)保护通信](https://hyperledger-fabric.readthedocs.io/zh_CN/latest/enable_tls.html)。
- **tlsintermediatecacerts:** 此文件夹包含一个受该MSP所代表的组织信任的中间CA证书列表，**用于进行节点之间基于TLS的安全通信**。当商业CA被用作一个组织的TLS证书时，此文件夹特别有用。与成员资格中间CA类似，TLS中间CA的指定是可选的。
- **operationscerts:** 此文件夹包含与[Fabric运维服务](https://hyperledger-fabric.readthedocs.io/zh_CN/latest/operations_service.html)API通信所需的证书。

通道MSP包含以下附加文件夹:

- **Revoked Certificates:** 如果参与者的身份被撤销，关于该身份的识别信息——而不是身份本身——会被保存在这个文件夹中。对于基于x.509的身份，这些标识符是被称为Subject Key Identifier(SKI)和Authority Access Identifier(AKI)的字符串对，并且在使用证书时被检查，以确保证书没有被撤销。

  尽管这个列表在概念上与CA的证书撤销列表(CRL)相同而已，但它也与组织成员的撤销有关。因此，通道MSP的管理员可以通过发布CA的更新过的CRL，快速从组织中撤销参与者或节点。这个“撤销列表中的列表”具有可选择性。只有当证书被撤销时，它才会被填充。

## B

![Untitled 1](../../../图片保存/Untitled1.jpg)

![Untitled 2](../../../图片保存/Untitled2.png)

**Root CAs | 根证书列表**

此文件夹包含，由此 MSP 代表的组织信任的 Root CA，自签名 X.509 证书列表。此 MSP 文件夹中必须至少有一个 Root CA X.509 证书。这是最重要的文件夹，因为它标识了所有其它证书。

**Intermediate CAs | 中间证书列表**

此文件夹包含此组织信任的 Intermediate CA 的 X.509 证书列表。每个证书都必须由 MSP 中的一个 Root CA 签署，或者由 Intermediate CA 签署。

Intermediate CA 可以表示组织的不同细分或组织本身（例如，如果商业 CA 用于组织的身份管理）。在前一种情况下，可以使用 CA 层次结构中，较低的其他 Intermediate CA 来表示组织细分。请注意，可能有一个没有任何中间 CA 的功能网络，在这种情况下，此文件夹将为空。

与 Root CA 文件夹一样，此文件夹定义了中间证书。只有拥有了这些证书，才能被系统视为组织成员的 CA。

**Organizational Units (OUs) | 组织单元列表**

可选的

**Administrators | 管理员身份证书**

该文件夹包含一个身份列表，用于定义具有该组织管理员角色的参与者。对于标准 MSP 类型，此列表中应该有一个或多个 X.509 证书。

**Revoked Certificates | 撤销证书列表**

可选的

**KeyStore for Private Key | 私钥库**

该文件夹为 peer 或 orderer 节点（或客户端的 local MSP）的 local MSP 定义，并包含节点的 signing key（签名密钥）。 此密钥用于**签署数据**，作为认可阶段的一部分。

该文件夹对 Local MSP 是必须的，并且必须包含一个私钥。 很明显，访问这个文件夹，只能由，对此 peer 有管理权限的用户。

Channel MSP 的配置不包括此部分，因为 Channel MSP 旨在提供纯粹的身份验证功能，而不是签署能力。

**TLS Root CA | TLS 根证书列表**

此文件夹包含，此组织为 TLS 通信所信任的 Root CA 的自签名 X.509 证书列表。 **TLS 通信的一个例子是，peer 需要连接到 orderer 以便它可以接收 ledger 更新。**

MSP TLS 信息涉及网络内的节点，即对 peers 和 the orderers，此文件夹中必须至少有一个 TLS Root CA X.509 证书。

**TLS Intermediate CA | TLS 中间证书**

此文件夹包含由此 MSP 代表的，组织信任的用于 TLS 通信的 Intermediate CA 证书列表。当商业 CA 用于组织的 TLS 证书时，此文件夹特别有用。 它是可选的。

Fabric 中 MSP 相关**实现代码**都在 msp 目录下，目前采用了 bccspmsp 结构来代表一个成员身份结构，并且采用了 MSPConfig（主要是其成员 FabricMSPConfig）结构来代表跟该实体相关的证书信息。

MSP 中各实体资源的证书**必须被证书信任树上的叶子节点签名**。中间层签名的证书会被认为是非法实体证书。

# Fabirc CA基础

## Fabric CA核心功能

1. 发行担保证书 ECerts (Enrollment Certificates)；
2. 发行交易证书 TCerts (Transaction Certificates)，保障 Hyperledger Fabric 区域链交易平台上的信息匿名性和不可追踪性；
3. 证书更新和撤销。

- 登记证书（ECert）：颁发给提供了注册凭证的用户或节点等实体，代表网络中身份。一般长期有效。
- 交易证书（TCert）：颁发给用户，控制每个交易的权限，不同交易可以不同，实现匿名性。短期有效。
- 通信证书（TLSCert）：控制对网络层的接入访问，可以对远端实体身份进行校验，防止窃听。

## Fabric CA核心概念

![Untitled 3](../../../图片保存/Untitled3.png)

上图中Fabric CA提供了两种访问方式调用Server服务

- 通过Fabric-Client调用
- 通过SDK调用 （node.js，java， go）

通常情况下， 一个组织会对应一个fabric-server服务器，

- 要在每个组织中部署一个fabric-ca服务器, 给当前组织注册新用户
- Hyperledger fabric CA客户端或SDK可以连接到Hyperledger fabric CA服务器集群，集群由HA Proxy等实现负载均衡。
- 服务器可能包含多个CA，每个CA都是根CA或者中间CA，每个中间CA都有一个父CA。

# MSP证书详解

## **msp定义**

MSP是hyperleger fabric对网络中的组成成员进行身份管理与验证的模块组件。
作用：管理用户ID，验证想要加入网络的节点，为客户发起的交易提供凭证
MSP 在Hyperledger Fabric中按级别分类如下：
网络MSP：对整个hyperledger fabric网络中的成员进行管理；定义参与组织的MSP，以及组织成员中的那些成员被授权执行管理任务（如创建通道）
通道MSP：对一个通道中的成员进行管理，通道在特定的一组组织之间提供私有通信；在该通道的MSP环境中（通道策略）定义了谁有权限参与通道上的某些行为（如添加组织或实例化链码）。
Peer MSP：每个Peer节点都有一个单独的MSP实例，执行与通道MSP完全相同的功能，其限制是它仅适用于定义它的Peer节点。
Orderer MSP：与Peer MSP相同，Orederer节点的本地MSP也在其节点的文件系统上定义，仅适用于该Orderer节点。
User MSP：每个组织都可以拥有多个不同的用户，都在其Organization节点的文件系统上定义，仅适用于定义它的Peer节点。

**在Hyperledger Fabric中，各个网络参与者之间的通信安全依赖于PKI（Public Key Infrastructure,公钥基础结构）标准实现，并确保在区块链上发布的消息得到相应的认证。**

PKI只是一个体系结构，负责生成及颁发证书。在H yperledger fabric 中，默认MSP实际上使用符合X.509标准的证书作为身份，采用传统的PKI分层模型来实现。

PKI的四个关键要素：

数字证书：最常见的证书类型符合X.509标准的证书。

公钥和私钥：

证书颁发机构：这些证书由CA进行数字签名，CA是为组织的参与者提供可验证的数字身份的基础。

证书撤销列表：

## ****MSP的组成结构****

MSP

- RCA 根CA ：文件夹包含根CA的自签名X.509证书列表，用于自签名及给中间CA证书签名。
- ICA 中间CA ：包含根CA颁发的证书列表。
- OU 组织单位：这些单位列在$FABRIC_CFG_PATH/msp/config.yaml文件中，包含一个组织单位列表，其成员被视为该MSP所代表的组织的一部分。
- B 管理页：此文件夹包含一个标识列表，用于定义具有此组织管理员角色的角色。
- ReCA 撤销证书：保存已被撤销参与者身份的信息。
- SCA 签名证书：背书节点在交易提案响应中的签名证书。
- KeyStore 私钥：
- TLS RCA TLS根CA
- TLS ICA TLS中间CA

# Fabric网络证书结构

```bash
crypto-config
├── ordererOrganizations # orderer 节点组织树
│   └── example.com # 组织域，组织的命名域
│       ├── ca # 存放组织(example.com)的 CA 根证书和私钥文件 ?? 【有中间CA情况下，这里是根还是中间】
│       │   ├── .........._sk # 组织(example.com)的私钥文件
│       │   └── ca.example.com-cert.pem # 组织(example.com)的CA根证书
│       │
│       ├── msp # 存放代表该组织(example.com)的身份信息
│       │   ├── admincerts # 存放组织管理员的身份验证证书，被组织(example.com)的根证书签名
│       │   │   └── Admin@example.com-cert.pem
│       │   ├── cacerts # 存放组织(example.com)CA根证书，同 ca 目录下的文件
│       │   │   └── ca.example.com-cert.pem
│       │   ├── intermediatecerts # (可选) 存放组织(example.com)的中间 CA 证书
│       │   │   └── intermediateca.example.com-cert.pem
│       │   ├── tlscacerts # 存放组织(example.com)用于 TSL 安全连接的 CA 根证书，自签名
│       │   │   └── tlsca.example.com-cert.pem
│       │   └── intermediatecerts # (可选) 存放组织(example.com)用于 TSL 安全连接的中间 CA 证书
│       │       └── intermediateca.example.com-cert.pem
│       │  
│       ├── orderers # 存放该组织所有 orderer 节点的信息
│       │   └── orderer.example.com # 第一个 orderer 节点的信息，包含代表其身份的msp证书文件和用于TLS连接的tls证书文件
│       │       ├── msp # 存放代表第一个 orderer 节点身份的 msp 证书文件
│       │       │   ├── admincerts # 存放组织管理员的身份验证证书，Oderer节点将基于其来认证xxx管理员身份 ??
│       │       │   │   └── Admin@example.com-cert.pem
│       │       │   ├── cacerts # 存放组织(example.com)的 CA 根证书
│       │       │   │   └── ca.example.com-cert.pem
│       │       │   ├── intermediatecerts # (可选) 存放组织(example.com)的中间 CA 证书
│       │       │   │   └── intermediateca.example.com-cert.pem
│       │       │   ├── keystore # 存放本 orderer 节点的身份私钥，用来签名
│       │       │   │   └── .........._sk
│       │       │   ├── signcerts # 存放验证本 orderer 节点签名的证书，被组织 CA 根证书签名
│       │       │   │   └── orderer.example.com-cert.pem
│       │       │   ├── tlscacerts # 存放 TLS 连接用的身份证书， 既组织的 TLS CA 根证书
│       │       │   │   └── tlsca.example.com-cert.pem
│       │       │   ├── intermediatecerts # 存放 TLS 中间 CA 证书，既组织的 TLS 中间 CA 证书
│       │       │   │   └── intermediateca.example.com-cert.pem
│       │       │   ├── crls #(可选) 存放证书吊销列表
│       │       │   │   └── XXXX
│       │       │   └──  config.yaml # 映射部门和证书 OU 字段的 YAML 文件
│       │       └── tls # 存放本 orderer 节点 tls 相关的证书和私钥
│       │           ├── ca.crt # 组织(example.com)的 tlsCA 根证书[tlsca.example.com-cert.pem]
│       │           ├── server.crt # 验证本节点签名的证书，被组织 tlsCA 根证书签名 tls/signcerts [cert.pem]
│       │           └── server.key # 本节点的身份私钥，用来签名 tls/keystore[.........._sk]
│       │
│       ├── tlsca # 存放组织(example.com)用于 TSL 安全连接的 CA 根证书和秘钥 ?? 【有中间tlsCA情况下，这里是根还是中间】
│       │   ├── .........._sk # 秘钥
│       │   └── tlsca.example.com-cert.pem # 证书
│       └── users # 存放属于该组织的用户实体
│           └── Admin@example.com # 组织管理员用户信息，包括其 msp 证书和 tls 证书
│               ├── msp # 存放管理员用户的 msp 证书文件
│               │   ├── admincerts # 存放组织管理员的身份验证证书，被组织(example.com)的根证书签名
│               │   │   └── Admin@example.com-cert.pem
│               │   ├── cacerts # 存放组织(example.com)的 CA 根证书
│               │   │   └── ca.example.com-cert.pem
│               │   ├── keystore # 本用户的身份私钥，用来签名
│               │   │   └── .........._sk
│               │   ├── signcerts # 管理员用户的身份验证证书，这是该组织下所有实体 msp 文件中 admincerts 文件的来源
│               │   │   └── Admin@example.com-cert.pem
│               │   └── tlscacerts # 存放 TLS 连接用的身份证书， 既组织的 TLS CA 根证书
│               │       └── tlsca.example.com-cert.pem
│               └── tls
│                   ├── ca.crt # 组织(example.com)的 tlsCA 根证书[ca.example.com-cert.pem]
│                   ├── client.crt # 管理员用户的身份验证证书 Admin@example.com/tls/signcerts [cert.pem]
│                   └── client.key # 管理员用户的身份私钥，用来签名 Admin@example.com/tls/keystore [.........._sk]
│
│
└── peerOrganizations
    ├── org1.example.com		# 组织一证书目录
    │   ├── ca	# 存放了组织的根证书和对应的私钥文件，组织内的实体将基于该证数作为证数根。
    │   │   ├── ca.org1.example.com-cert.pem
    │   │   └── priv_sk
    │   ├── msp	# 存放代表该组织的身份信息。
    │   │   ├── admincerts	# 被根证书签名的组织管理员的身份验证证书。
    │   │   ├── cacerts	#CA服务器的根证书，和ca目录下的文件相同。
    │   │   │   └── ca.org1.example.com-cert.pem  
    │   │   ├── config.yaml
    │   │   └── tlscacerts	# #CA服务器的根证书 用于TLS的ca证书
    │   │       └── tlsca.org1.example.com-cert.pem
    │   ├── peers	# 存放该组织下所有peer节点的证书
    │   │   ├── peer0.org1.example.com
    │   │   │   ├── msp
    │   │   │   │   ├── admincerts	# 组织管理员的身份验证证书，用于验证交易签名者是否为管理员身份。
    │   │   │   │   ├── cacerts	# 存放组织的根证书。
    │   │   │   │   │   └── ca.org1.example.com-cert.pem
    │   │   │   │   ├── config.yaml # 组织机构的配置文件
    │   │   │   │   ├── keystore	# 本节点的身份私钥，用来签名。
    │   │   │   │   │   └── priv_sk
    │   │   │   │   ├── signcerts	# 验证本节点签名的证书，被组织根证书签名。
    │   │   │   │   │   └── peer0.org1.example.com-cert.pem
    │   │   │   │   └── tlscacerts	# TLS连接用的身份证书，即组织TLS证书。
    │   │   │   │       └── tlsca.org1.example.com-cert.pem
    │   │   │   └── tls	# 存放tls相关的证书和私钥。
    │   │   │       ├── ca.crt	# 组织的根证书。
    │   │   │       ├── server.crt	# 验证本节点签名的证书，被组织根证书签名。
    │   │   │       └── server.key	# 本节点的身份私钥，用来签名。
    │   │   └── peer1.org1.example.com
    │   │       ├── msp
    │   │       │   ├── admincerts
    │   │       │   ├── cacerts
    │   │       │   │   └── ca.org1.example.com-cert.pem
    │   │       │   ├── config.yaml
    │   │       │   ├── keystore
    │   │       │   │   └── priv_sk
    │   │       │   ├── signcerts
    │   │       │   │   └── peer1.org1.example.com-cert.pem
    │   │       │   └── tlscacerts
    │   │       │       └── tlsca.org1.example.com-cert.pem
    │   │       └── tls
    │   │           ├── ca.crt
    │   │           ├── server.crt
    │   │           └── server.key
    │   ├── tlsca
    │   │   ├── priv_sk
    │   │   └── tlsca.org1.example.com-cert.pem
    │   └── users	# 存放属于该组织的用户实体。
    │       ├── Admin@org1.example.com	# 管理员用户的信息，包括其msp证书和tls证书。
    │       │   ├── msp
    │       │   │   ├── admincerts	# ：管理员身份证书。
    │       │   │   ├── cacerts	# 存放组织的根证书。
    │       │   │   │   └── ca.org1.example.com-cert.pem
    │       │   │   ├── config.yaml
    │       │   │   ├── keystore	# 本用户的身份私钥，用来签名。
    │       │   │   │   └── priv_sk
    │       │   │   ├── signcerts	# 管理员用户的身份验证证书，由组织根证书签名，要放到Peer的msp/admincerts下才会被这个Peer认可。
    │       │   │   │   └── Admin@org1.example.com-cert.pem
    │       │   │   └── tlscacerts	# TLS连接用的身份证书，即组织TLS证书。
    │       │   │       └── tlsca.org1.example.com-cert.pem
    │       │   └── tls	# 存放TLS相关的证书和私钥
    │       │       ├── ca.crt	# 组织的根证书。
    │       │       ├── client.crt	# 管理员用户的身份验证证书，由组织根证书签名。
    │       │       └── client.key	# 管理员的身份私钥，用来签名。
    │       └── User1@org1.example.com	# 用户的信息，结构和admin相同，包括msp证书和tls证书。
    │           ├── msp
    │           │   ├── admincerts
    │           │   ├── cacerts
    │           │   │   └── ca.org1.example.com-cert.pem
    │           │   ├── config.yaml
    │           │   ├── keystore
    │           │   │   └── priv_sk
    │           │   ├── signcerts
    │           │   │   └── User1@org1.example.com-cert.pem
    │           │   └── tlscacerts
    │           │       └── tlsca.org1.example.com-cert.pem
    │           └── tls
    │               ├── ca.crt
    │               ├── client.crt
    │               └── client.key
    └── org2.example.com
        ├── ca
        │   ├── ca.org2.example.com-cert.pem
        │   └── priv_sk
        ├── msp
        │   ├── admincerts
        │   │   ├── Admin@org2.example.com-cert.pem
        │   │   └── ca.org2.example.com-cert.pem
        │   ├── cacerts
        │   │   └── ca.org2.example.com-cert.pem
        │   └── tlscacerts
        │       └── tlsca.org2.example.com-cert.pem
        ├── peers
        │   ├── peer0.org2.example.com
        │   │   ├── msp
        │   │   │   ├── admincerts
        │   │   │   │   └── Admin@org2.example.com-cert.pem
        │   │   │   ├── cacerts
        │   │   │   │   └── ca.org2.example.com-cert.pem
        │   │   │   ├── keystore
        │   │   │   │   └── priv_sk
        │   │   │   ├── signcerts
        │   │   │   │   └── peer0.org2.example.com-cert.pem
        │   │   │   └── tlscacerts
        │   │   │       └── tlsca.org2.example.com-cert.pem
        │   │   └── tls
        │   │       ├── ca.crt
        │   │       ├── server.crt
        │   │       └── server.key
        │   └── peer1.org2.example.com
        │       ├── msp
        │       │   ├── admincerts
        │       │   │   └── Admin@org2.example.com-cert.pem
        │       │   ├── cacerts
        │       │   │   └── ca.org2.example.com-cert.pem
        │       │   ├── keystore
        │       │   │   └── priv_sk
        │       │   ├── signcerts
        │       │   │   └── peer1.org2.example.com-cert.pem
        │       │   └── tlscacerts
        │       │       └── tlsca.org2.example.com-cert.pem
        │       └── tls
        │           ├── ca.crt
        │           ├── server.crt
        │           └── server.key
        ├── tlsca
        │   ├── priv_sk
        │   └── tlsca.org2.example.com-cert.pem
        └── users
            ├── Admin@org2.example.com
            │   ├── msp
            │   │   ├── admincerts
            │   │   │   └── Admin@org2.example.com-cert.pem
            │   │   ├── cacerts
            │   │   │   └── ca.org2.example.com-cert.pem
            │   │   ├── keystore
            │   │   │   └── priv_sk
            │   │   ├── signcerts
            │   │   │   └── Admin@org2.example.com-cert.pem
            │   │   └── tlscacerts
            │   │       └── tlsca.org2.example.com-cert.pem
            │   └── tls
            │       ├── ca.crt
            │       ├── client.crt
            │       └── client.key
            └── User1@org2.example.com
                ├── msp
                │   ├── admincerts
                │   │   └── User1@org2.example.com-cert.pem
                │   ├── cacerts
                │   │   └── ca.org2.example.com-cert.pem
                │   ├── keystore
                │   │   └── priv_sk
                │   ├── signcerts
                │   │   └── User1@org2.example.com-cert.pem
                │   └── tlscacerts
                │       └── tlsca.org2.example.com-cert.pem
                └── tls
                    ├── ca.crt
                    ├── client.crt
                    └── client.key

```

## NodeOUs**介绍**

在Hyperledger Fabric中，Node OUs（Node Organizational Units）是用于管理节点身份验证和授权的组织单元。Node OUs定义了节点身份的一组规则，这些规则控制了哪些节点可以参与到通道和链码的事务中。

Node OUs通常包含以下组件：

- 根证书（root CA）：一个可信的CA，用于签署和验证证书和CRL。
- 中间证书（intermediate CA）：在根证书下的另一个CA，用于签署和验证节点的TLS证书。
- 节点证书（node certificate）：用于标识节点的证书，可以由中间CA签署。

Node OUs通常包含两个组织单元：

1. Peer OU：用于管理peer节点的身份验证和授权。Peer OU通常定义了哪些peer节点可以参与到通道和链码的事务中。
2. Client OU：用于管理客户端应用程序的身份验证和授权。Client OU通常定义了哪些客户端应用程序可以连接到peer节点，并向通道和链码提交事务。

使用Node OUs可以有效地管理节点的身份验证和授权，保护网络免受未经授权的访问和操作。

映射部门和证书 OU 字段的 YAML 配置文件，用 `<Certificate,OrganizationalUnitIdentifier>`
表示一个映射表

```bash
NodeOUs:
  Enable: true # 启用标识分类
  ClientOUIdentifier: # 客户端(client)标识符
    Certificate: cacerts/localhost-7054-ca-org1.pem # 验证客户端(client)身份的 CA 或中间 CA 证书
    OrganizationalUnitIdentifier: client # 与客户端(client)的x509证书中包含的OU匹配的值
  PeerOUIdentifier: # 对等节点(peer)标识符
    Certificate: cacerts/localhost-7054-ca-org1.pem # 验证对等节点(peer)身份的 CA 或中间 CA 证书
    OrganizationalUnitIdentifier: peer # 与对等节点(peer)的x509证书中包含的OU匹配的值
  AdminOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-org1.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-org1.pem
    OrganizationalUnitIdentifier: orderer
```

- ecdsa-with-SHA256 使用 SHA256 算法对内容先计算摘要，再应用签名算法对摘要进行签名
- Orderer 节点管理员证书位于 `crypto-config/ordererOrganizations/example.com/msp/admincerts`。由 CA 颁发给 `Admin@example.com`
- TLS 证书是自签名证书，与之前的 CA 证书没有关系。位于 `crypto-config/ordererOrganizations/example.com/msp/tlscacerts`
- TLS 客户端证书是由 TLS CA 颁发给 `Admin@example.com` 的用于 TLS 连接的证书。位于 `crypto-config/ordererOrganizations/example.com/users/Admin@example.com/tls`

# Fabric证书目录结构图片

![Untitled 4](../../../图片保存/Untitled4.png)

# Fabric CA配置详解

以下是一个使用表格描述 Fabric CA 配置文件的常见选项：

| 配置选项                        | 描述                                   |
| ------------------------------- | -------------------------------------- |
| ca-server.port                  | Fabric CA 服务器监听的端口             |
| ca-server.tls.enabled           | 是否启用 TLS                           |
| ca-server.tls.certfile          | TLS 证书文件的路径                     |
| ca-server.tls.keyfile           | TLS 密钥文件的路径                     |
| ca-server.database.type         | 数据库类型                             |
| ca-server.database.datasource   | 数据库连接信息                         |
| ca-server.csr.cn                | 证书请求中的 Common Name               |
| ca-server.csr.names             | 证书请求中的 Subject Alternative Names |
| ca-server.csr.hosts             | 证书请求中的 Hosts                     |
| registry.maxenrollments         | 允许一个用户最多可以注册多少个证书     |
| registry.identity.identifier    | 用户标识的属性                         |
| registry.identity.name.format   | 用户名称格式                           |
| registry.db.type                | 数据库类型                             |
| registry.db.datasource          | 数据库连接信息                         |
| registry.db.tls.certfiles       | TLS 证书文件的路径                     |
| registry.db.tls.client.certfile | TLS 客户端证书文件的路径               |
| registry.db.tls.client.keyfile  | TLS 客户端证书密钥文件的路径           |
| affiliations.name               | 组织机构的名称                         |
| affiliations.maxenrollments     | 组织机构允许的最大注册数               |
| affiliations.affiliations       | 子组织机构                             |
| ca.expiry                       | 证书的有效期限                         |
| ca.crlsizelimit                 | CRL（证书吊销列表）的大小限制          |
| ca.name                         | CA 的名称                              |
| ca.certfile                     | CA 的证书文件路径                      |
| ca.keyfile                      | CA 的密钥文件路径                      |
| ca.crlfile                      | CRL 文件的路径                         |
| ca.org.name                     | 证书主题中的组织名称                   |
| ca.org.unit                     | 证书主题中的组织单位名称               |
| ca.country                      | 证书主题中的国家名称                   |
| ca.locality                     | 证书主题中的地区名称                   |
| ca.province                     | 证书主题中的省份名称                   |

注意：以上表格中的选项仅供参考，不同版本的 Fabric CA 可能会有所不同。在实际使用中，请查阅相应版本的官方文档以获取最新的配置选项。

# Fabric CA **`fabric-ca-client register` 命令**

以下是**`fabric-ca-client register`**命令支持的一些常用属性和它们的含义：

| 属性                  | 含义                                                                                                  |
| --------------------- | ----------------------------------------------------------------------------------------------------- |
| --id.name             | 用户名称（必需）                                                                                      |
| --id.affiliation      | 用户所属的组织（必需）                                                                                |
| --id.type             | 用户类型（默认为“User”）                                                                            |
| --id.attrs            | 用户属性，可以是任意名称和值的属性，以逗号分隔。例如：--id.attrs "role=admin:ecert,organization=org1" |
| --id.secret           | 用户密码（默认为自动生成的密码）                                                                      |
| --id.maxenrollments   | 用户可以注册的最大次数                                                                                |
| --tls.certfiles       | TLS证书文件的路径，用于与CA服务器进行安全通信（默认为“$FABRIC_CA_CLIENT_HOME/tls-cert.pem”）        |
| --csr.cn              | 证书主体的Common Name                                                                                 |
| --csr.names           | 证书主体的其他名称。例如：--csr.names "C=US,ST=California,L=San Francisco,O=example,CN=example.com"   |
| --csr.hosts           | 证书可以使用的主机名或IP地址，以逗号分隔。例如：--csr.hosts "localhost,127.0.0.1"                     |
| --csr.keyrequest.algo | 用于生成密钥的算法类型。例如：--csr.keyrequest.algo "ecdsa"                                           |
| --csr.keyrequest.size | 生成密钥的位数。例如：--csr.keyrequest.size "256"                                                     |

注意：以上列表并非所有属性，更多信息可以在**`fabric-ca-client register --help`**命令的帮助文档中找到。

Regenerate response

1. 颁发登录证书(ECerts)；
2. 颁发交易证书(TCerts)

## Fabric CA 属性

[Hyperledger Fabric链码使用基于属性的访问控制_algiz_kk的博客-CSDN博客](https://blog.csdn.net/qq_33657251/article/details/107351136)

[Fabric CA 官方用户指南（中文版）_一颗贪婪的星的博客-CSDN博客_fabric-ca](https://blog.csdn.net/greedystar/article/details/80344984)

[Hyperledger Fabric CA中文文档_寒木的博客-CSDN博客_csr.hosts](https://blog.csdn.net/zhanglingge/article/details/106645646)

[Fabric CA创建用户机制的示例分析](https://www.yisu.com/zixun/524379.html)

下表列出了可以为身份注册的所有预置属性。注：属性的名称是区分大小写的

注意：在注册身份时若提供属性为列表，且列表中存在重复的属性名，则以最后一个为准。

1. 上级id这些布尔属性如果设置为false(或者不设置)，则所创建是下级id都不能带有对应的这个几个布尔类型的系统属性
2. 刚才创建的test_a身份，`id.type=client` ,`hf.Registrar.Roles=client,user`, 如果我们用test_a注册一个 `id.type=peer`或者 `id.type=orderer`的身份 结果会怎样呢？大家应该都想得到，肯定是失败
3. **fabric-ca 1.1 版本 `hf.Registrar.Roles` 属性只支持 `client,user,peer,orderer`四种，1.2版本即将支持自定义角色，详见：https://jira.hyperledger.org/browse/FAB-7882**
4. 当test_a身份的属性 `hf.Registrar.Roles=client,user`，往下用test_a身份创建的子身份的 `f.Registrar.Roles`属性值都不能超过 `client,user`的范围
5. 上级id的 `hf.Registrar.Attributes`值可以约束它所创建的子级id能添加的属性，但是带 `hf.`的除外，带 `hf.`开头的会被当做系统属性，区别对待
6. 从上级往下，所带的属性约束只能是逐渐收敛的，不能发散

- 红色箭头表示 CA 颁发证书给某个组织或个人

![Untitled 5](../../../图片保存/Untitled5.png)

- 颜色相同的线条表示文件内容相同。

## 用户证书中加入自定义属性

[Hyperledger Fabric链码使用基于属性的访问控制_algiz_kk的博客-CSDN博客](https://blog.csdn.net/qq_33657251/article/details/107351136)

```bash
使用fabric-ca-client在证书中加入自定义属性
# 管理员register用户id的时候，加上自定义属性
$ fabric-ca-client register --id.name user1 --id.secret user1pw --id.type user --id.affiliation org1 --id.attrs 'attr1=value1'

# 管理员enroll用户的时候，指定之前注册的id中的哪些属性要加入到证书中
fabric-ca-client enroll -u [http://user1:user1pw@localhost:7054](http://user1:user1pw@localhost:7054/) --enrollment.attrs "attr1,attr2:opt"

# enroll的时候，属性后面加opt，说明该属性是可选的，不带opt的属性，是在register用户id的时候必须指定该属性，否则enroll失败
```

# Fabric CA其他命令

fabric-ca-client命令可以与服务端进行交互, 包括五个子命令:

- enroll: 登录获取ECert
- getcacert: 获取CA服务的证书链
- reenroll: 再次登录
- register: 注册用户实体
- revoke: 吊销签发的实体证书

```bash
# tls证书服务器环境变量
cp tls-ca/crypto/ca-cert.pem tls-ca/crypto/tls-ca-cert.pem
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/tls-ca/crypto/tls-ca-cert.pem
export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/tls-ca/admin
fabric-ca-client enroll -d -u https://tls-ca-admin:tls-ca-adminpw@0.0.0.0:7052

# rca-org证书服务器环境变量
export FABRIC_CA_CLIENT_TLS_CERTFILES=/tmp/hyperledger/rca-org/ca/crypto/ca-cert.pem
export FABRIC_CA_CLIENT_HOME=/tmp/hyperledger/rca-org/ca/admin
fabric-ca-client enroll -d -u https://admin:adminpw@0.0.0.0:7053
```

```bash
# 查看证书信息
openssl x509 -in $ORG_DIR/ca/ica.org1.example.com.crt.pem -text -noout

# 查看联盟信息
fabric-ca-client affiliation list -u https://0.0.0.0:7053

# 添加联盟成员
fabric-ca-client affiliation add xinhe -u https://0.0.0.0:7052

# 删除联盟成员
fabric-ca-client affiliation remove --force org2.department1 -u https://0.0.0.0:7052

# 显示身份/用户列表
fabric-ca-client identity list -u https://0.0.0.0:7053
		--add         增加身份
  		--list        显示所有身份列表
  		--modify      修改身份信息
  		--remove      删除身份信息
	# 修改用户身份
fabric-ca-client identity modify ${userName} --affiliation xinhe.org1 --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*" -u https://0.0.0.0:7053
	标识参数:
		--affiliation string   身份的从属关系
      	--attrs stringSlice    格式的逗号分隔属性列表，格式为 <name>=<value> (如： foo=foo1,bar=bar1)
      	--json string          用于添加新身份的JSON字符串
      	--maxenrollments int   可重复使用密钥进行登记的最大次数 (默认：CA's Max Enrollment)
     	--secret string        要添加的身份的注册密钥
      	--type string          要注册的身份类型 (e.g. 'peer, app, user') (默认："user")
	# 删除身份/用户
fabric-ca-client identity remove ${userName} -u https://0.0.0.0:7052
fabric-ca-client identity remove user-org1 -u https://0.0.0.0:7052

# 吊销指定的证书或指定实体相关的所有证书
fabric-ca-client revoke -e "user1-org1" -r "affiliationchange" -u https://0.0.0.0:7053
	-e: 指定吊销用户
	-r: 指定吊销原因
# 重新认证账号
fabric-ca-client reenroll -e "peer1.org3.xinhe.com"  -u https://0.0.0.0:7053
# 生成CRL (证书撤销列表)
fabric-ca-client gencrl  -u https://0.0.0.0:7053
fabric-ca-client gencrl --caname "" --revokedafter 2017-09-13T16:39:57-08:00 --revokedbefore 2017-09-21T16:39:57-08:00 -M ~/msp
```

```bash
fabric-ca-client [command]
	可用命令
			affiliation 管理附属关系
		  certificate 管理证书
		  enroll      登记身份,获取ECert证书
		  gencrl      生成CRL
		  gencsr      生成CSR
		  getcainfo   获取CA证书链和idex公钥
		  identity    身份管理
		  reenroll    重新登记身份
		  register    注册身份
		  revoke      撤销身份
		  version     显示Fabric CA Client的版本信息
	基础配置
					--caname string                  CA名称
		  -H, --home string                    客户端主目录(默认："$HOME/.fabric-ca-client")
		      --loglevel string                设置日志记录级别 (info, warning, debug, error, fatal, critical)
		  -M, --mspdir string                  成员服务的程序所在的目录 (默认："msp")
		  -m, --myhost string                  注册期间要包含在证书签名请求中的主机名 (默认："$HOSTNAME")
		  -u, --url string                     fabric-ca-server的URL网址 (默认："http://localhost:7054")
# enroll命令 向服务端申请签发ECert证书并将文件保存至本地
# getcacert命令 向服务端申请根证书信息并保存至本地主配置目录的msp/cacerts路径下
#						证书命名格式为: 服务器主机名-CA实例名.pem
# reenroll命令  利用本地配置信息再次执行enroll过程, 生成新的签名证书材料
```

## enroll命令

```bash
fabric-ca-client enroll -u http://admin:adminpw@localhost:7054
.
├── fabric-ca-client-config.yaml
└── msp
    ├── IssuerPublicKey
    ├── IssuerRevocationPublicKey
    ├── cacerts
    │   └── localhost-7054.pem  #CA服务器的根证书，只不过换了一个名字
    ├── keystore                #当前用户的秘钥信息
    │   └── 7ec84cbc25c20600ba98bf2bafb9c695ad57e392a57fb9f33b51fc493601a432_sk
    ├── signcerts               #当前用户的证书
    │   └── cert.pem  
    └── user
```

## ****getcacert命令****

向服务端申请根证书信息并保存至本地主配置目录的msp/cacerts路径下

```bash
fabric-ca-client getcacert -u http://admin:pass@localhost:7054
```

证书命名格式为: 服务器主机名-CA实例名.pem

## ****reenroll命令****

利用本地配置信息再次执行enroll过程, 生成新的签名证书材料

```bash
fabric-ca-client ****reenroll**** -u http://admin:pass@localhost:7054
```

## **register命令**

执行注册新用户实体的客户端必须已经通过登记认证, 并且拥有足够的权限(所注册用户的hf.Registrar.Roles和affiliation都不能超出调用者属性)来进行注册

```bash
fabric-ca-client register --id.name jack --id.type user --id.affiliation org1.department1 --id.attrs '"hf.Registrar.Roles=peer,user"' --id.attrs 'hf.Revoker=true' --id.secret jackpw
```

## ****revoke命令****

吊销指定的证书或指定实体相关的所有证书. 执行revoke命令的客户端身份必须拥有足够的权限(hf.Revoker为true, 并且被吊销者机构不能超出吊销者机构的范围)

```bash
fabric-ca-client revoke -e "jack" -r "affiliationchange"
```

- e: 指定吊销用户
- r: 指定吊销原因
- -e, --revoke.name string          应撤销其证书的身份
- -s, --revoke.serial string           要撤销的证书的序列号

输出内容如下

```bash
2018/05/02 17:55:44 [INFO] Configuration file location: .fabric-ca-client/fabric-ca-client-config.yaml
2018/05/02 17:55:44 [INFO] Sucessfully revoked certificates: []
```

# 验证证书有效性

## 使用跟证书验证签名证书

```bash
openssl verify -verbose -CAfile rootca/ca-cert.pem orderer/orderer0/msp/admincerts/orderer-admin-cert.pem



# 使用 ca-cert.pem 验证 orderer-admin-cert.pem
```

## 查看签名证书颁发者授予者

两个文件: ca-cert.pem 和 tls-cert.pem, 查看一下具体的文件信息:

ca-cert.pem:

```bash
openssl x509 -in .\ca-cert.pem -noout -subject -issuer
>>
subject=C = US, ST = North Carolina, O = Hyperledger, OU = Fabric, CN = rca-org1
issuer=C = US, ST = North Carolina, O = Hyperledger, OU = Fabric, CN = rca-org1
```

tls-cert.pem:

```bash
openssl x509 -in .\tls-cert.pem -noout -subject -issuer
>>
subject=C = US, ST = North Carolina, O = Hyperledger, OU = Fabric, CN = 5dc1c0eb3394
issuer=C = US, ST = North Carolina, O = Hyperledger, OU = Fabric, CN = rca-org1
```

## 验证签名证书与私钥是否匹配

- ca-cert.pem 是org1的身份根证书，是自签名的证书(issuer = subject),所有被发布和被签名(由rca-org1的私钥)的证书都可以被根证书进行验证。从而验证已有证书的合法性。
- tls-cert.pem 由rca-org1发布的，是一个TLS服务器级的证书，仅用于其他服务和这个rca-org1的通讯。 具体的说，当客户机访问rca-org1时，rca-org1将向客户机提供这个服务器证书。客户端将使用颁发者(即根CA证书 【是ca-cert.pem】)来验证此服务器证书，并确认客户端正在与正确的服务器(rca-rg1)通信，并且客户端与rca-org1之间的通信是加密的。

查看私钥(secret keys) ,对应上面的两个证书，存储在msp/keystore

![Untitled 6](../../../图片保存\Untitled6.png)

从私钥中导出公钥，并和证书中的公钥进行对比，确定密钥对。

```bash
openssl ec -in .\msp\keystore\priv_sk -pubout
>>
read EC key
writing EC key
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEnIDJa3ZohFnzMtqY+HOQofPj8+Ry
IuVmcb72Bl4j8jagDO7PC4ToCF7Zlp/0TZd+VKH7f6NKBEPbuEz8BBsIpQ==
-----END PUBLIC KEY-----
 
 
openssl x509 -in .\ca-cert.pem -noout -pubkey
>>
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEnIDJa3ZohFnzMtqY+HOQofPj8+Ry
IuVmcb72Bl4j8jagDO7PC4ToCF7Zlp/0TZd+VKH7f6NKBEPbuEz8BBsIpQ==
-----END PUBLIC KEY-----
```

tls-cert.pem

![Untitled 7](../../../图片保存/Untitled7.png)

## ****查看签名证书详情****

AKI: 公钥标识号, 代表了对该证书进行签发机构的身份

查看根证书的AKI与序列号信息:

```bash
openssl x509 -in .fabric-ca-client/msp/signcerts/cert.pem -text -noout
```

输出内容如下:

```bash
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:  # 序列号
            74:48:88:33:70:1a:01:a0:ad:32:29:6e:c5:ab:5a:fa:3b:91:25:a4
   ......
        X509v3 extensions:
           ......
            X509v3 Authority Key Identifier:    # keyid后面的内容就是 AKI
                keyid:45:B1:50:B6:CD:8A:8D:C5:9B:9E:5F:75:15:47:D6:C0:AD:75:FE:71

    ......
```

下面的需要java环境

```bash
$ keytool -printcert -file ca-cert.pem

Owner: CN=ca-tls, O=MHTech, ST=Cheng Du, C=CN
Issuer: CN=ca-tls, O=MHTech, ST=Cheng Du, C=CN
Serial number: 60bfcf507e7a22ab875415593e0b47132acf8ef5
Valid from: Mon Oct 04 16:02:00 CST 2021 until: Tue Sep 30 16:02:00 CST 2036
Certificate fingerprints:
     MD5:  F9:21:E0:81:8C:DB:4C:55:7D:D3:C5:68:81:17:16:6A
     SHA1: 0C:0D:E3:C8:86:03:92:8A:0D:95:9B:3A:EF:46:08:29:7C:68:2E:0E
     SHA256: B8:2F:B6:10:7C:D0:0D:1D:9A:1A:1B:D1:84:32:50:F7:EE:9E:CD:7A:41:92:AB:51:12:3B:15:E4:36:A0:63:40
Signature algorithm name: SHA256withECDSA
Subject Public Key Algorithm: 256-bit EC key
Version: 3

Extensions:

#1: ObjectId: 2.5.29.19 Criticality=true
BasicConstraints:[
  CA:true
  PathLen:1
]

#2: ObjectId: 2.5.29.15 Criticality=true
KeyUsage [
  Key_CertSign
  Crl_Sign
]

#3: ObjectId: 2.5.29.17 Criticality=false
SubjectAlternativeName [
  IPAddress: 0.0.0.0
]

#4: ObjectId: 2.5.29.14 Criticality=false
SubjectKeyIdentifier [
KeyIdentifier [
0000: D4 9E B9 03 A1 4E 70 49   01 24 94 28 9B A7 F7 D0  .....NpI.$.(....
0010: 5E 17 FE 9C                                        ^...
]
]
```

## ****单独获取AKI****

```bash
openssl x509 -in .fabric-ca-client/msp/signcerts/cert.pem -text -noout | awk '/keyid/ {gsub (/ *keyid:|:/,"",$1);print tolower($0)}'
```

输出内容如下:

```bash
45b150b6cd8a8dc59b9e5f751547d6c0ad75fe71
```

## ****单独获取序列号****

```bash
openssl x509 -in .fabric-ca-client/msp/signcerts/cert.pem -serial -noout | cut -d "=" -f 2
```

输出内容如下:

```bash
74488833701A01A0AD32296EC5AB5AFA3B9125A4
```
