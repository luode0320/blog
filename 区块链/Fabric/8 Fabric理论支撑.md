# Fabric理论支撑

# fabric应用程序架构

[【2020初春】【区块链】Fabric 系统架构及简单实例_fabric实例_之井的博客-CSDN博客](https://blog.csdn.net/mdzz_z/article/details/107578048)

![Untitled](../../../图片保存\Untitled10.png)

# 基础概念

[揭秘 Hyperledger Fabric（1/3）：Fabric 架构](https://zhuanlan.zhihu.com/p/395644879)

```bash
1、peer节点是什么
Fabric（Hyperledger Fabric）是一个面向企业应用的开源分布式账本平台，其中的Peer节点是该平台的核心组件之一。
Peer节点是指在Fabric网络中执行交易、维护账本、验证其他节点发送的交易和状态更新等操作的节点。在Fabric中，Peer节点分为两种类型：
	Endorsing Peer：也称为背书节点，负责对交易进行背书签名，确保交易的合法性。
	Committing Peer：也称为提交节点，负责将背书结果提交到账本中，并将结果广播到整个网络中。
Peer节点可以是一个组织中的一个成员，也可以是多个组织中的多个成员。Peer节点之间通过gRPC协议进行通信，每个Peer节点都有自己的身份标识和访问控制列表（ACL），确保交易和数据的安全性和隐私性。
在Fabric网络中，Peer节点的数量和分布对网络性能和可用性有很大的影响。通常情况下，为了保证网络的性能和可靠性，需要设置足够多的Peer节点，并根据实际需求进行负载均衡和容灾备份。

2、orderer节点有什么用
在Hyperledger Fabric中，Orderer节点是网络中的另一个核心组件，它负责维护交易的顺序和完整性，确保所有的Peer节点看到的交易顺序是一致的。
具体来说，Orderer节点有以下几个主要的功能：
	接收交易：当一个客户端提交一个交易请求时，它将首先被发送到Orderer节点。
	记录交易顺序：Orderer节点将交易按照一定的规则（如时间戳）记录下来，并将交易序列化为区块。
	维护区块链：Orderer节点将区块广播给所有的Peer节点，Peer节点将其保存到本地的账本中，从而实现账本的复制和共识。
	提供共识算法：Orderer节点负责实现共识算法，以确保所有Peer节点看到的交易序列是一致的。
需要注意的是，Orderer节点是可插拔的，Fabric支持不同类型的Orderer节点，如Solo Orderer、Kafka Orderer和Raft Orderer等，每种Orderer节点都有其独特的优缺点和适用场景。在实际应用中，需要根据具体需求选择合适的Orderer节点类型和数量，并进行合理的配置和管理。

3、通道有什么用
在Hyperledger Fabric中，通道（Channel）是一种将网络中的Peer节点和Orderer节点划分为不同组的方式，以便于进行私密交易和数据隔离。通道可以理解为一个子网络，只包含特定的Peer节点和Orderer节点，与其他通道相互隔离，拥有自己的账本和交易历史记录。
通道主要有以下几个作用：
	隔离数据：通道可以将不同的交易和数据隔离开来，避免数据泄露和不必要的访问。
	实现私密交易：在通道中的交易仅由通道内的Peer节点和Orderer节点可见和处理，其他节点无法看到这些交易。
	提高吞吐量：由于不同的通道之间互相隔离，可以在同一网络中并行地处理多个通道的交易，从而提高整个网络的吞吐量和性能。
	管理权限：通道可以根据需要设定访问权限和管理规则，例如限制特定的组织或用户只能访问特定的通道。
在实际应用中，通道是非常重要的组件，特别是对于需要进行私密交易或数据隔离的场景，例如金融交易、供应链管理、医疗保健等领域。通过合理的通道划分和管理，可以实现更加灵活和安全的区块链应用。

4、账本的作用
账本（Ledger）是Hyperledger Fabric中的核心组件之一，它是一个分布式数据库，用于记录网络中所有交易和状态的历史记录。账本是区块链的本质，也是区块链的主要特点之一。
账本的主要作用如下：
	记录交易历史：账本中记录了所有交易的历史记录，包括交易的发起者、接收者、金额等详细信息。
	维护状态信息：账本中记录了当前网络中所有参与者的状态信息，例如资产余额、合约状态等。
	实现共识机制：账本中的交易历史记录是通过共识机制来达成共识的，保证交易的真实、不可篡改。
	提供查询接口：账本提供了API接口，可以查询历史交易记录、当前状态信息等数据。
	实现权限控制：账本可以根据访问者的身份和权限，限制其对数据的访问和修改。

需要注意的是，Hyperledger Fabric中的账本是可插拔的，支持不同的数据库类型和存储方式，例如LevelDB、CouchDB等，根据不同的应用场景和需求，可以选择合适的账本类型和配置。
总之，账本是Hyperledger Fabric中非常重要的组件，负责记录和维护网络中的交易和状态信息，是实现区块链技术的核心组成部分。

5、链码的作用
链码（Chaincode）是Hyperledger Fabric中的智能合约，它是一个运行在Peer节点上的程序，用于定义和执行交易和状态的逻辑。链码可以理解为一种应用程序，用于实现区块链中的业务逻辑和业务规则，类似于传统应用中的后端服务。
链码的主要作用如下：
	定义业务逻辑：链码可以定义和实现区块链中的业务逻辑和业务规则，例如资产转移、数据验证、权限控制等。
	执行交易：链码可以执行交易，包括读取、写入账本中的状态信息，更新账户余额等操作。
	实现数据验证：链码可以实现数据的验证和检查，确保交易的正确性和合法性。
	提供API接口：链码可以提供API接口，供外部应用程序和系统调用和访问。
	支持升级：链码支持版本控制和升级，可以在不中断现有服务的情况下，实现链码的升级和更新。
链码是Hyperledger Fabric中非常重要的组件，它是实现业务逻辑和智能合约的核心部分。通过合理的链码设计和实现，可以实现更加灵活、高效和安全的区块链应用。

6、通道配置的作用
通道配置（Channel Configuration）是Hyperledger Fabric中的一个重要组成部分，它用于定义和配置通道中所有参与者的权限、策略和属性等信息。通道配置是实现Hyperledger Fabric中权限控制和安全性的关键。
通道配置的主要作用如下：
	定义参与者权限：通道配置定义了通道中所有参与者的权限和角色，包括Peer节点、Orderer节点、客户端应用程序等。通过定义角色和权限，可以实现对账本的读写操作、链码的部署和调用等操作的限制和控制。
	配置安全策略：通道配置可以定义安全策略和规则，包括对交易的背书策略、对区块的验证策略、对TLS证书的校验等。这些安全策略和规则可以保障交易和数据的安全性和完整性。
	管理共识机制：通道配置定义了共识机制的相关参数和配置，包括共识算法、背书策略、块生成策略等。通过配置共识机制，可以保证交易的一致性和可靠性。
	配置其他属性：通道配置还可以定义其他属性，例如通道的名称、版本号、通道成员的列表、网络拓扑结构等。这些属性可以帮助用户更好地管理和维护Hyperledger Fabric网络。
需要注意的是，通道配置是可升级和可变化的，可以根据实际需求进行修改和调整。同时，通道配置也需要进行管理和维护，以确保网络的安全和可靠性。
总之，通道配置是Hyperledger Fabric中非常重要的组件，用于定义和配置通道中的角色、权限、安全策略和共识机制等。通过合理的通道配置，可以实现更加安全、高效和可靠的区块链应用。

7、组织的作用
在Hyperledger Fabric中，组织（Organization）是指一组参与者（包括Peer节点和客户端应用程序等）的集合，他们共同拥有一定的共识关系和权限规则，可以协同参与区块链网络的运作。
组织的主要作用如下：
	定义参与者：组织定义了参与者的集合，包括Peer节点、客户端应用程序和管理员等。参与者可以共同维护区块链网络的运作，实现交易的验证、背书、排序和提交等操作。
	管理访问权限：组织可以定义访问权限和角色，用于控制参与者的操作和访问权限。例如，组织可以定义读写账本的权限、部署链码的权限、执行交易的权限等。
	管理身份认证：组织可以定义身份认证和授权规则，确保参与者的身份和操作符合规定和合法。例如，组织可以定义TLS证书的验证规则、数字签名的校验规则等。
	管理共识关系：组织可以定义共识关系和协作规则，包括对交易的背书、对区块的验证和排序等。组织可以协同参与共识过程，确保交易的一致性和可靠性。
	管理链码部署和升级：组织可以管理链码的部署和升级，包括链码的代码和版本管理、链码的生命周期管理等。组织可以控制链码的访问权限，确保链码的安全性和合法性。
需要注意的是，Hyperledger Fabric中的组织是非常灵活和可扩展的，可以根据实际需求进行组织结构的设计和调整。同时，组织之间也可以进行协作和交互，实现区块链网络的多组织共识和交易。
总之，组织是Hyperledger Fabric中非常重要的组成部分，它用于定义参与者、管理访问权限和身份认证、管理共识关系和链码部署等。通过合理的组织结构和管理，可以实现更加安全、高效和可靠的区块链应用。

8、证书的作用
在区块链领域中，证书（Certificate）是指一种数字证书，用于证明参与者的身份和授权信息。Hyperledger Fabric中使用X.509证书格式，这种证书通常由认证机构（CA）颁发，用于验证参与者的身份和权限。
证书在Hyperledger Fabric中的作用包括：
	身份认证：证书可以用于验证参与者的身份和身份信息。参与者需要使用自己的证书进行身份认证，才能进行区块链网络的操作和交易。
	权限授权：证书可以用于授权参与者的操作权限和访问权限。通过证书，参与者可以获得不同的操作权限，例如读写账本、部署链码、执行交易等。
	信息加密：证书可以用于对信息进行加密和解密，确保信息传输的安全性和隐私性。通过证书，参与者可以生成公钥和私钥，用于加密和解密信息。
	数字签名：证书可以用于生成数字签名，用于验证参与者的操作和交易的合法性和真实性。通过证书，参与者可以生成数字签名，并用自己的私钥进行签名，其他参与者可以使用公钥进行验证和确认。
在Hyperledger Fabric中，证书是非常重要的组成部分，它用于身份认证、权限授权、信息加密和数字签名等。通过合理的证书管理和验证，可以确保区块链网络的安全、可靠和高效。

9、锚节点的作用
锚节点（Anchor Node）是区块链网络中的一个节点，它主要用于连接两个或多个不同的区块链网络，以便在这些网络之间传递信息和数据。锚节点通常是在两个或多个区块链之间建立桥梁，以实现跨链通信和互操作性。

锚节点的作用如下：

实现跨链通信：由于不同的区块链网络之间可能存在不同的共识机制、协议和规则等，因此它们无法直接进行通信。锚节点可以作为中间媒介，将数据从一个区块链网络传递到另一个区块链网络，从而实现跨链通信。

促进互操作性：通过连接不同的区块链网络，锚节点可以帮助不同的网络之间实现数据共享和交互。这有助于提高整个区块链生态系统的互操作性和协同性。

提高安全性：锚节点可以增加区块链网络的安全性和可靠性。它可以作为区块链网络之间的信任桥梁，确保数据传输的完整性和一致性。

总之，锚节点在区块链网络中具有非常重要的作用，可以促进不同区块链之间的数据传输和交互，并提高整个区块链生态系统的安全性和可靠性。

Hyperledger Fabric理解
	排序节点（orderer）
		排序节点（Orderer） 是 Fabric 共识机制中使用的最重要的组件之一。 排序节点（Orderer） 是一种服务，负责对交易进行排序，创建一个新的有序交易区块，并将新创建的区块分发给相关通道上的所有区块链节点（Peers）
	
	组织（org）
		组织Organization，代表区块链网络中的企业、机构等实体，一个组织理论上可以有无数个peer节点

	对等节点（peer）
		Peer 是一个区块链节点，将所有交易存储在加入的通道上。每个 Peer可以根据需要加入一个或多个频道。但是，同一Peer上不同通道的存储将是分开的。因此，组织可以确保机密信息仅在特定通道上共享给允许的参与者。

	锚节点（peer）
		锚节点是相对于组织的概念，由于Fabric是联盟链而不是公有链，所以Fabric内有组织的概念，而锚节点作为组织的代表，负责同网络内其他组织进行信息交换。锚节点通过访问其他组织的锚节点，来获知其他组织内Peer节点的信息。

	通道（channel）
		通道(Channels)可能被认为是一个组织与加入同一通道的其他参与组织秘密通信的隧道。不参与相关通道的任何其他人永远无法访问与该通道相关的任何交易或信息。一个组织可以同时参与多个通道。
		注意：
			1、通道与通道之间是不会产生联系的，每一个通道都是独立的存在
			2、排序节点可以为多个通道服务
	
	通道配置（重点）
		通道配置一般包括通道全局配置、排序配置和应用配置等多个层级，这些配置都存放在通道的配置区块内。通道全局配置定义该通道内全局的默认配置，排序配置和应用配置分别管理与排序服务相关配置和与应用组织相关配置。
		简单的描述：
			1、配置当前通道的策略
			2、配置当前通道关联那个联盟
			3、配置有那些orderer节点为这个通道服务，配置orderer节点策略
			4、配置orderer在通道中的共识机制
			5、定义通道中存在那些组织，配置组织的策略，并为组织指定锚节点
	
	联盟（Consortium）
		fabric中的联盟和通道是一对一的关系，联盟必须和通道channel并存，在无系统通道的版本中，联盟与通道等价。
	
	账本
		节点账本的内部组件包括区块链（Blockchain）和 世界状态（World State）。 区块链（Blockchain）保存特定通道上每个链码的所有交易历史。世界状态（World State）为每个特定的链码维护变量的当前状态。
		Fabric 目前支持的两种类型的世界状态（World State）数据库包括 LevelDB 和 CouchDB。
		fabric不可篡改是因为：区块链（Blockchain）保存特定通道上每个链码的所有交易历史，这个是没有办法篡改的
	
	证书颁发机构（fabric ca）
		证书颁发机构（Certificate Authority）或 CA 负责管理用户证书，例如用户注册、用户登记、用户注销等。更具体地说，Hyperledger Fabric 是一个需许可认证的区块链网络。这意味着只有获得许可的用户才能在授权通道上查询（query，访问信息）或调用（invoke，创建新交易）交易。 Hyperledger Fabric 使用 X.509 标准证书来表示每个用户的权限、角色和属性。换句话说，用户可以根据他/她拥有的权限、角色和属性，来查询或调用任何通道上的任何交易。
	
	客户端（client）
		Client 被认为是一个与 Fabric 区块链网络交互的应用程序。也就是说，Client可以根据其从其关联组织的 CA 服务器派生的证书上指定的权限、角色和属性与 Fabric 网络进行交互。
	
	链码（Chaincode）
		要部署链码（Chaincode），网络管理员必须将链码（Chaincode）安装到目标节点（Peers）上，然后调用排序节点（Orderer）将链码（Chaincode）实例化到特定通道（Channel）上。 在实例化链码（Chaincode）时，管理员可以为链码定义背书策略（endorsement policy）。 背书策略定义了哪些节点需要就交易结果达成一致，然后才能将交易添加到通道上所有节点的账本（Ledgers）中。

	背书节点（Endorsing peer）
		背书策略（endorsement policy）中指定的节点称为背书节点（Endorsing peer），它由已安装的链码（Chaincode）和其上的本地账本组成，而承诺节点（Committing peer）将只有本地账本。 
	
	系统链码
		QSCC（Query System Chaincode，查询系统链码）用于账本和Fabric相关的查询有助于规范访问控制的 CSCC（Configuration System Chaincode，配置系统链码）
		LSCC（Lifecycle System Chaincode，生命周期系统链码），定义了通道的规则
		ESCC（Endorsement System Chaincode，背书系统链码）用于背书交易用于验证交易的 VSCC（Validation System Chaincode，验证系统链码）
	
	Hyperledger Fabric 中的共识
		Fabric 共识具有丰富的多阶段和多层次的背书、有效性和版本控制检查。 在将交易区块写入账本之前，有多个阶段来确保所有参与者的许可、背书、数据同步、交易顺序和变更的正确性。
			Hyperledger Fabric 使用基于许可投票的共识，该共识假设网络中的所有参与者都是部分信任的。 共识可以分为以下三个阶段。

				背书（Endorsement）
				排序（Ordering）
				验证和承诺（Validation and Commitment）
			
			
	Fabric 事务调用的工作流程：
		1、客户端（Client）提出交易提议，用用户（User）的证书签署交易提议，并将交易提议发送到特定通道（Channel）上的一组预先确定的背书节点（Endorsing Peers）。
		2、每个背书节点（Endorsing Peers）从交易提议的有效负载中验证用户的身份和授权。如果验证检查通过，则背书节点（Endorsing Peers）模拟交易，生成响应和读写结合，并使用其证书对生成的响应进行背书。
		3、客户端（Client）积聚并检查来自背书节点（Endorsing Peers）的已背书交易提议响应。
		4、客户端（Client）将附有背书交易提议响应的交易发送给排序节点（Orderer）。
		5、排序节点（Orderer） 对接收到的交易进行排序，生成一个新的有序交易区块，并用其证书对生成的块进行签名。
		6、排序节点（Orderer）将生成的区块广播给相关通道上的所有节点（同时向背书节点（Endorsing Peers）和 承诺节点（Comitting Peers））。然后，每个节点确保接收到的区块中的每笔交易都由适当的背书节点（Endorsing Peers）签名（即，从调用的链码的背书策略中确定）并且存在足够的背书。之后，将进行版本检查（称为多版本并发控制（MVCC）检查）以验证接收到的区块中每个交易的正确性。也就是说，每个节点都会将每个交易的 readset 与其账本的世界状态（World state）进行比较。如果验证检查通过，则交易被标记为有效，并且每个节点的世界状态（World state）都会更新。否则，交易被标记为无效而不更新世界状态（World state）。最后，无论该区块是否包含任何无效交易，接收到的区块都会附加到每个节点的本地区块链中。
		7、客户端（Client）从 EventHub 服务接收任何订阅的事件。
```

# ****权限管理和策略****

[超级账本Fabric中的权限管理和策略_yeasy的博客-CSDN博客](https://blog.csdn.net/yeasy/article/details/88536882)


![Untitled 1](../../../图片保存\Untitled11.png)

## ****身份证书****

实现权限管理的基础是身份证书机制。

通过基于 PKI 的成员身份管理，Fabric 网络可以对接入的节点和用户的各种能力进行限制。

Fabric 设计中考虑了三种类型的证书：登记证书（Enrollment Certificate）、交易证书（Transaction Certificate），以及保障通信链路安全的 TLS 证书。证书的默认签名算法为 ECDSA，Hash 算法为 SHA-256。

登记证书（ECert）：颁发给提供了注册凭证的用户或节点等实体，代表网络中身份。一般长期有效。
交易证书（TCert）：颁发给用户，控制每个交易的权限，不同交易可以不同，实现匿名性。短期有效。
通信证书（TLSCert）：控制对网络层的接入访问，可以对远端实体身份进行校验，防止窃听。
目前，在实现上，主要通过 ECert 来对实体身份进行检验，通过检查签名来实现权限管理。TCert 功能暂未实现，用户可以使用 idemix 机制来实现部分匿名性。

## **身份集合**

基于证书机制，Fabric 设计了身份集合（MSP Principal）来灵活标记一组拥有特定身份的个体，如下图所示。

![Untitled 2](E:\区块链笔记\799cbe3c-fee5-4dfa-97a3-39edfdf38cbc_Export-59cb9f1a-0e45-41fe-b8bc-48ea5e4e97e3\Fabric理论支撑 20ecedd68e7548598bc7e2be14fa7165\Untitled12.png)

对应的 MSP Principal 的数据结构如下图所示。

![Untitled 3](E:\区块链笔记\799cbe3c-fee5-4dfa-97a3-39edfdf38cbc_Export-59cb9f1a-0e45-41fe-b8bc-48ea5e4e97e3\Fabric理论支撑 20ecedd68e7548598bc7e2be14fa7165\Untitled13.png)

身份集合支持从不同维度上对身份进行分类：

Role：根据证书角色来区分，如 Admin、User、Client、Peer ,orderer等；
OrganizationUnit：根据身份中的 OU 信息来区分，如某个特定部门。实际上 Client 和 Peer 角色也是通过证书中的 OU 域来指定的；
Identity：具体指定某个个体的证书，只有完全匹配才认为合法；
Anonymity：证书是否是匿名的，用于 idemix 类型的 MSP；
Combined：由其他多个子身份集合组成，需要符合所有的子集合才认为合法。
基于不同维度可以灵活指定符合某个身份的个体，例如某个 MSP 的特定角色（如成员或管理员），或某个 MSP 特定单位（OrganizationUnit），当然也可以指定为某个特定个体。

需要注意目前角色定义是在代码中实现。对于管理员角色，除安装链码操作是将签名的证书跟节点 msp/admincerts 路径下的证书列表进行查找匹配，其它操作依赖于通道配置中对应组织 MSP 结构中 MSP.value.admins 中定义；对于成员角色，则需要所签名证书是被节点同一 MSP 根签发即可。具体实现可参考 msp/mspimpl.go 文件中 satisfiesPrincipalInternal 相关方法。Client 和 Peer 角色认定则通过检查证书中 OU 域信息。

## ****通道策略****

![Untitled 4](../../../图片保存\Untitled14.png)

# orderer共识算法

[Fabric2.0的Orderer](https://zhuanlan.zhihu.com/p/346475708)

在Fabric2.0的网络结构中，是非常关键的一个组件。Fabric网络的正常运转都和orderer节点有着密切的关系，如果缺少或者损失了Orderer节点，则会出现无法正常交易、无法正常增加Peer节点、无法扩充Orderer节点。

Fabric节点，包含两大核心组件。排序服务和共识组件两部分，其中排序服务是同客户端密切相关的功能，而共识组件则为了完成网络一致性的核心功能。

- **排序服务**

排序服务之中，也有着两个核心的功能模块。即Broadcast和Deliver。

Broadcast的主要功能是接收来自客户端的交易请求，对客户端发送过来的数据格式进行校验，同时也会对客户端的访问权限进行检查，然后再尝试将请求打包给共识组件进行排序。

Broadcast不仅仅包括交易的相关功能，对于系统通道/用户通道的创建和更新乃至到链码的实例化都有参与的部分，链码的相关初始化和安装并不只是由Peer节点自行维护。

Deliver的主要功能是负责处理Peer或者客户端获取区块文件的请求。客户端发来请求之后，都会检查对应通道是否在Orderer节点之中存在，每当网络之中生成新的区块文件，或者客户端试图获取通道内的创世块、具体的区块文件时，都是通过Orderer的Deliver模块进行处理。

客户端来获取区块文件的时候，会发送一个区块序列号区间给Deliver，而Deliver会根据区间来从自己本地读取区块文件，每次自增+1的形式给客户端有序的返回指定区块文件。

- **共识组件**

1. Solo（已弃用）

该模式，并不是可用于生成环境之下的共识机制。因为该模式适用于一个Orderer节点，多个Peer节点的情况。

由于Orderer节点只有一个，即使网络之中存在多个Peer节点。从Orderer上面来看，任何请求都是存在先后顺序的关系。Orderer节点可以简单的根据先后顺序进行排序，也不需要担心并发请求。通过Golang的Mutex模块下，将排序函数加锁和解锁，采用简单的数组模式即可实现。因为Solo并不涉及到不同Orderer节点之间同步数据的情况。

1. Kafka（1.4的共识机制）

在Fabric中Kafka并不是指的Orderer节点是Kafka节点，Kafka可以看作为独立于Orderer的服务。Orderer只是调用Kafka集群来向内部增加数据，各个节点之间数据的一致性，由Kafka服务完成。

Fabric内的Kafka共识机制的工作原理如下：

①客户端发送交易至Orderer节点。

②Orderer节点收到请求之后，解析并校验数据。检查通过之后封装为Kafka的消息，通过接口调用发送交易数据到Kafka集群。同时与Kafka集群建立长连接，定期交换数据来保持连接的稳定性和消息的及时性，当Kafka集群内某个通道的区块文件过大之后，会及时通知Orderer节点来取区块数据。

③Kafka集群内会为每个通道都建立一个对应的Topic，其Topic的数据结构应该可以这样理解（=map[string][]Blockchain），通过Map（Dict）来建立通道和区块链条的关系。Kafka支持分布式和多节点部署，而不同节点之间的状态如何同步则是通过Kafka集群内部完成，并不是Orderer节点进行参与的。即节点之间的数据同步，都是由Kafka集群完成，而不是Orderer节点

④Orderer节点通过向Kafka集群注册事件的形式进行数据监听，当区块文件高度或者超时时间得到满足之后，就会拉取排序之后的交易消息到Orderer节点本地。

⑤Orderer节点将交易信息拉取到本地之后，就会尝试将交易信息打包为区块，最终分发给各个Peer节点。

1. Raft（2.0的共识机制）

在Fabric2.0的新版本中，才能使用该共识算法，Raft共识最简单的表述应该称之为冗余备份机制。

在Fabric的Raft机制之中，存在着领导者、跟随者和候选者三种角色。Leader节点负责进行区块的排序，跟随者将会实时从领导者处接收区块文件使自己的状态和领导者的状态保持一致性。

候选者指的是通道内所有的Orderer节点，只要当前网络之中没有Leader节点，那么所有的Orderer节点都会是候选者。在Fabric内每个通道都会对应有一个Raft共识Orderer组，所以可能会出现某个Orderer同时会是多个通道的领导节点。

在Raft的机制下最终只有一个Orderer节点进行排序，所以其性能非常的高，并不需要多个节点之间同步状态的拜占庭问题。当领导节点存活的情况下，其他Orderer节点的功能相当于Commit peer的功能，只是不断的同步区块文件，维持网络内部的稳定性，当领导节点宕机之后，及时进行二次的重新选举，保障交易可以正常完成。

Raft的机制在网络之中存活Orderer节点占总数的51%以上才能正常运转，否则会出现整个网络无法正常交易的情况。当网络之中同时存在两个Orderer节点一起离线的情况下，也会导致整个网络出现故障，即无法正常向网络内额外添加Orderer节点。只有仅掉线一个Orderer的情况，才能通过删除Orderer节点移除掉线节点，再增加Orderer节点，使整个网络恢复正常。

Raft机制，也导致会出现额外的新问题，即网络流量的大幅增加。因为跟随者需要实时不断的从领导节点获取最新的排序状态、节点选举后的通信链路维护，节点之间的数据交互会占据局域网内大部分的网络流量。

## 共识机制的步骤

[HyperLeger Fabric开发（四）——HyperLeger Fabric共识机制_51CTO博客_hyperledger fabric共识机制](https://blog.51cto.com/quantfabric/2316045)

[Fabric2.2中的Raft共识模块源码分析 - Garrett_Wale - 博客园](https://www.cnblogs.com/GarrettWale/p/16131853.html)

[【2020初春】【区块链】Fabric 系统架构及简单实例_fabric实例_之井的博客-CSDN博客](https://blog.csdn.net/mdzz_z/article/details/107578048)

![Untitled 5](../../../图片保存\Untitled15.png)

![Untitled 6](../../../图片保存\Untitled16.png)

![Untitled 7](../../../图片保存\Untitled17.png)

![Untitled 8](\Untitled18.png)

在区块链系统中，共识过程是指不同节点之间达成一致的过程，以保证数据的一致性和安全性。一般来说，共识过程包含以下几个步骤：

1. `提议阶段`：在这个阶段，参与共识的节点中的一个节点（一般称为提议者）会提出一个交易或区块，并将其发送给其它节点。
2. `认证阶段`：在这个阶段，其它节点（一般称为验证者）会对接收到的交易或区块进行验证，并在验证通过后将其广播给其它节点。
3. `投票阶段`：在这个阶段，每个验证者会对接收到的交易或区块进行投票，并将投票结果广播给其它节点。
4. `统计阶段`：在这个阶段，每个节点会统计所有投票结果，并计算出达成共识的结果。
5. `执行阶段`：在这个阶段，如果达成共识，各个节点会对交易或区块进行执行，并将执行结果广播给其它节点。
6. `持久化阶段`：在这个阶段，交易或区块的执行结果会被写入区块链账本，以保证数据的一致性和安全性。

需要注意的是，不同的区块链系统具体的共识过程可能会有所不同，但总体上都会包含以上几个步骤，以达到保证数据的一致性和安全性的目的。

## 共识流程

交易的共识包括3个阶段的处理：提议阶段、打包阶段和验证阶段，下面结合交易流程，分别介绍各个阶段。

（一）提议阶段
提议阶段我们可以理解为背书阶段，这一阶段可以分为三个步骤，如下：

1. 用户通过Application（封装了Fabric SDK的客户端应用程序）构造出交易提议，交易提议中包含欲执行的Chaincode和函数名，背书节点列表（与具体的Chaincode背书策略有关，包含在同一个Channel中）等数据，并将交易提议发送至相应的Peer。
2. 各背书节点接收到交易提议后，首先进行一些检查和签名的验证，然后独立地模拟执行指定的Chaincode函数（不将执行结果写入本地账本），生成一个提议结果，并对结果进行背书，即在结果中添加数字签名并利用私钥对结果进行签名。
3. 将提议结果返回至Application。

当Application收集到足够多的提议结果后，提议阶段完成。

（二）打包阶段
打包阶段也就是对交易进行排序的阶段，Orderer节点在这个阶段中起着至关重要的作用，过程如下：

1. Orderer接收到来自于多个Application的交易提议结果
2. 对每个Application提交的交易进行排序，这里值得注意的是排序的规则不是按照Orderer接收到交易的时间，而是按照交易的时间进行排序
3. 将交易分批打包进区块中，形成一个统一的共识结果，这种机制保证了Fabric不会出现账本的分叉
4. 当等待足够时间或区块满足大小后，Orderer将打包好的区块发送给特定Channel中的所有Peer

（三）验证阶段
Channel中的节点在接收到Orderer广播的区块后，每个节点都按照相同的方式独立处理接收到的区块，保证账本的一致性，步骤如下：

1. 通过VSCC检查交易是否满足背书策略。
2. 检查账本当前状态是否与提议结果生成时一致。
3. 通过检查的成功交易将被更新到账本中。
4. 构造Event消息，向注册了事件监听的Application通知Event消息。

# Fabirc 背书节点与背书策略

在区块链中，特别是在基于共识机制的区块链中，背书节点和背书策略是两个重要的概念。

**背书节点**（Endorsing Node）是指在共识机制中参与交易验证和背书的节点。在Hyperledger Fabric等区块链平台中，背书节点是网络中的一组节点，它们评估交易并将其标记为有效，从而生成区块。

**背书策略**（Endorsement Policy）是一组规则，定义了必须哪些背书节点必须同意某个交易，以便该交易可以被提交到区块链中。在Hyperledger Fabric中，背书策略是指在提交交易之前必须获得多少背书节点的签名，以使交易被视为有效。

背书策略可以根据应用程序的需求进行自定义，例如可以指定需要多少个背书节点签名、哪些节点必须签名、何时节点需要签名等等。这种灵活性使得背书策略可以适应各种应用程序的需求，并确保在提交交易之前得到足够的节点确认，从而提高整个网络的安全性和可信度。

总之，背书节点和背书策略是保障区块链共识机制顺利运行的两个关键因素，其合理设置和使用可以提高区块链网络的效率和安全性。

## 1.背书策略定义

[科学网-Hyperledger Fabric共识机制优化方案 - 欧彦的博文](https://blog.sciencenet.cn/blog-3291369-1304694.html?mType=Group)

[Fabric2.0如何设置背书策略](https://www.yisu.com/zixun/522677.html#:~:text=%E8%AE%BE%E7%BD%AE%E8%83%8C%E4%B9%A6%E7%AD%96%E7%95%A5%20fabric2.0%E6%99%BA%E8%83%BD%E5%90%88%E7%BA%A6%E8%AE%BE%E7%BD%AE%E8%83%8C%E4%B9%A6%E7%AD%96%E7%95%A5%E5%BE%97%E6%96%B9%E5%BC%8F%E4%B8%BB%E8%A6%81%E6%9C%89%E4%B8%A4%E7%A7%8D%EF%BC%8C%E4%B8%80%E7%A7%8D%E6%98%AF%E9%80%9A%E8%BF%87%E6%8F%90%E4%BA%A4%E5%90%88%E7%BA%A6%E7%9A%84%E6%97%B6%E5%80%99%E8%AE%BE%E7%BD%AE%EF%BC%8C%E6%88%91%E4%BB%AC%E7%A7%B0%E4%B9%8B%E4%B8%BA%E5%90%88%E7%BA%A6%E7%BA%A7%E5%88%AB%E7%9A%84%E8%83%8C%E4%B9%A6%E7%AD%96%E7%95%A5%EF%BC%8C%E4%B8%80%E7%A7%8D%E6%98%AF%E7%9B%B4%E6%8E%A5%E9%80%9A%E8%BF%87%E5%90%88%E7%BA%A6%E5%8A%A8%E6%80%81%E8%AE%BE%E7%BD%AE%EF%BC%8C%E6%88%91%E4%BB%AC%E7%A7%B0%E4%B9%8B%E4%B8%BA%E9%94%AE%E7%BA%A7%E5%88%AB%E8%83%8C%E4%B9%A6%E7%AD%96%E7%95%A5%E3%80%82,3.1%20%E5%90%88%E7%BA%A6%E7%BA%A7%E5%88%AB%E8%83%8C%E4%B9%A6%E7%AD%96%E7%95%A5%E8%AE%BE%E7%BD%AE)

智能合约背书策略用来定义交易是否合法的判断条件，策略以主体的形式表示。主体格式为'MSP.ROLE'， MSP代表所要求的MSPID， ROLE表示角色，一共有四种合法角色：member, admin, client, peer。

## 2. 背书策略语法

背书策略的语法如下： EXPR(E[, E...]) EXPR可以是AND、OR、OutOf，E可以是一个上面示例的主体或者是另一个嵌套的EXPR策略。示例如下： AND('Org1.member', 'Org2.member', 'Org3.member') ：要求三个主体中每一个主体都要签名。 OR('Org1.member', 'Org2.member') ：要求三个主体中至少有一个主体签名。 OR('Org1.member', AND('Org2.member', 'Org3.member'))：要求同时有主体Org1.member的签名，以及主体Org2.member与Org3.member中至少一个主体的签名。 OutOf(2, 'Org1.member', 'Org2.member', 'Org3.member') ：要求三个主体中，至少有两个主体签名。

## 3. 设置背书策略

fabric2.0智能合约设置背书策略得方式主要有两种，一种是通过提交合约的时候设置，我们称之为合约级别的背书策略，一种是直接通过合约动态设置，我们称之为键级别背书策略。

## 3.1 合约级别背书策略设置

所谓合约级别背书策略，就是在这个合约的交易都必须遵循这个策略，在默认情况下，即不设置背书策略，合约的背书策略为majority of channel members,过半数通道成员。

输入以下命令设置合约级别背书策略 背书策略"OR('Org1.member', 'Org2.member')" 组织1成员或者组织2成员背书即满足

```bash
peer lifecycle chaincode approveformyorg  --signature-policy "OR('Org1MSP.member','Org2MSP.member')" --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --channelID mychannel --name mycc --version 1 --init-required --package-id mycc_1:4ad799ccef18d596f8c175fe1849cadc63f92a5efb1e7332712fbb2827a2ec6f --sequence 2 --waitForEvent
```

- -signature-policy：设置背书策略

出现以下错误： `Error: proposal failed with status: 500 - failed to invoke backing implementation of 'ApproveChaincodeDefinitionForMyOrg': currently defined sequence 3 is larger than requested sequence 2`

序列号不是当前合约序列号，只需要改成最新的序号即可，假如是这里，sequence值改成3即可

`Error: proposal failed with status: 500 - failed to invoke backing implementation of 'ApproveChaincodeDefinitionForMyOrg': attempted to redefine uncommitted sequence (4) for namespace mycc with unchanged content`

存在当前最新的合约没有commit，无法进行新的approve，只需要将最新的commit后再进行这次新的approve即可。

切换节点重复命令，知道满足lifecycle策略

![https://cache.yisu.com/upload/information/20210522/356/586744.png](https://cache.yisu.com/upload/information/20210522/356/586744.png)

假如在操作上都approve成功了，还是出现以下情况：

![https://cache.yisu.com/upload/information/20210522/356/586745.png](https://cache.yisu.com/upload/information/20210522/356/586745.png)

```
我的实践是直接先commit，commit成功就可以继续走
```

## 3.1.2 提交合约

每次调用完approve之后，必须commit才能起效。

控制台输入以下命令

```bash
peer lifecycle chaincode commit -o orderer.example.com:7050 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --channelID mychannel --name mycc --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt --version 1 --sequence 2 --init-required    --signature-policy "OR('Org1MSP.member','Org2MSP.member')"
```

控制台输出以下结果表示成功

![https://cache.yisu.com/upload/information/20210522/356/586746.png](https://cache.yisu.com/upload/information/20210522/356/586746.png)

此时查询a的值为90

![https://cache.yisu.com/upload/information/20210522/356/586747.png](https://cache.yisu.com/upload/information/20210522/356/586747.png)

## 3.1.3 验证背书策略

3.2设置的背书策略为组织1成员或者组织2成员背书即满足， 此时指定背书节点为peer0.org1.example.com

```bash
peer chaincode invoke -o orderer.example.com:7050 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n mycc --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt  -c '{"Args":["invoke","a","b","10"]}'
```

控制台输出如下：

![https://cache.yisu.com/upload/information/20210522/356/586748.png](https://cache.yisu.com/upload/information/20210522/356/586748.png)

重新查询a的值为80，更新成功

![https://cache.yisu.com/upload/information/20210522/356/586749.png](https://cache.yisu.com/upload/information/20210522/356/586749.png)

将背书策略修改为 "AND('Org1MSP.member','Org2MSP.member')"

```bash
peer lifecycle chaincode approveformyorg  --signature-policy "AND('Org1MSP.member','Org2MSP.member')" --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --channelID mychannel --name mycc --version 1 --init-required --package-id mycc_1:4ad799ccef18d596f8c175fe1849cadc63f92a5efb1e7332712fbb2827a2ec6f --sequence 3 --waitForEvent
```

```bash
peer lifecycle chaincode commit -o orderer.example.com:7050 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --channelID mychannel --name mycc --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt --version 1 --sequence 3 --init-required    --signature-policy "AND('Org1MSP.member','Org2MSP.member')"
```

同样只设置peer0.org1.example.com节点，重新invoke，查看节点日志结果如下：

![https://cache.yisu.com/upload/information/20210522/356/586750.png](https://cache.yisu.com/upload/information/20210522/356/586750.png)

`ERRO 0ed VSCC error: stateBasedValidator.Validate failed, err validation of endorsement policy for chaincode mycc in tx 15:0 failed: signature set did not satisfy policy`

不满足背书策略，因为我们已经重新设置为"AND('Org1MSP.member','Org2MSP.member')"

接下来，我们通过设置键级别背书策略的方法，将上面操作完成

## 3.2 键级别背书策略设置

键级别的背书策略是通过智能合约内部调用SDK完成

shim包提供了以下的函数设置或者恢复键对应的背书策略。下面的ep代表是“endorsement policy”的缩写。

![https://cache.yisu.com/upload/information/20210522/356/586751.png](https://cache.yisu.com/upload/information/20210522/356/586751.png)

对于私有数据，以下功能适用：

![https://cache.yisu.com/upload/information/20210522/356/586752.png](https://cache.yisu.com/upload/information/20210522/356/586752.png)

Go shim提供了扩展功能，允许链码开发人员根据组织的MSP标识符来处理认可策略

![https://cache.yisu.com/upload/information/20210522/356/586753.png](https://cache.yisu.com/upload/information/20210522/356/586753.png)

根据官方给的说明 假如需要两个特定组织来批准key更改，设置key的背书策略，请将两个org都传递MSPIDs给AddOrgs()，然后调用Policy()构造可以传递给的认可策略字节数组SetStateValidationParameter() 接下来我们进行实践

## 3.2.1 编辑合约提供修改背书策略方法

首先导入相关依赖包

![https://cache.yisu.com/upload/information/20210522/356/586754.png](https://cache.yisu.com/upload/information/20210522/356/586754.png)

新增function 设置背书策略

![https://cache.yisu.com/upload/information/20210522/356/586755.png](https://cache.yisu.com/upload/information/20210522/356/586755.png)

endorsement具体实现如下：

![https://cache.yisu.com/upload/information/20210522/356/586756.png](https://cache.yisu.com/upload/information/20210522/356/586756.png)

由于新增了引入包，先下载依赖 进入合约目录输入以下命令

```
 go mod vendor
```

![https://cache.yisu.com/upload/information/20210522/356/586757.png](https://cache.yisu.com/upload/information/20210522/356/586757.png)

## 3.2.2 升级合约

[Fabric2.0中如何升级智能合约](https://www.yisu.com/zixun/522671.html)

## 3.2.3 验证背书策略

设置a的背书策略为 AND("Org1MSP.member","Org2MSP.member")

```bash
peer chaincode invoke -o orderer.example.com:7050 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n mycc --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt  -c  '{"Args":["endorsement","a","Org1MSP","add"]}'
```

```bash
peer chaincode invoke -o orderer.example.com:7050 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n mycc --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt  -c  '{"Args":["endorsement","a","Org2MSP","add"]}'
```

![https://cache.yisu.com/upload/information/20210522/356/586758.png](https://cache.yisu.com/upload/information/20210522/356/586758.png)

查看peer日志，交易成功

![https://cache.yisu.com/upload/information/20210522/356/586759.png](https://cache.yisu.com/upload/information/20210522/356/586759.png)

只设置peer0.org1节点作为背书节点

```
 peer chaincode invoke -o orderer.example.com:7050 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n mycc --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt  -c '{"Args":["addTen","a"]}'
```

查看节点日志如下，提示不满足策略，因为前面设置的是AND("Org1MSP.member","Org2MSP.member")

![https://cache.yisu.com/upload/information/20210522/356/586760.png](https://cache.yisu.com/upload/information/20210522/356/586760.png)

修改背书策略，删除Org2MSP

```
peer chaincode invoke -o orderer.example.com:7050 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n mycc --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses peer0.org2.example.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt  -c  '{"Args":["endorsement","a","Org2MSP","del"]}'
```

修改成功

![https://cache.yisu.com/upload/information/20210522/356/586761.png](https://cache.yisu.com/upload/information/20210522/356/586761.png)

重新执行以下命令：

```
 peer chaincode invoke -o orderer.example.com:7050 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n mycc --peerAddresses peer0.org1.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt  -c '{"Args":["addTen","a"]}'
```

修改a值从110变成120，执行成功

![https://cache.yisu.com/upload/information/20210522/356/586762.png](https://cache.yisu.com/upload/information/20210522/356/586762.png)

关于“Fabric2.0如何设置背书策略”这篇文章就分享到这里了，希望以上内容可以对大家有一定的帮助，使各位可以学到更多知识，如果觉得文章不错，请把它分享出去让更多的人看到。

# cryptogen命令

cryptogen是hyperleder [fabric](https://so.csdn.net/so/search?q=fabric&spm=1001.2101.3001.7020)提供的为网络实体生成加密材料（公私钥/证书等）的实用程序。简单来说就是一个生成认证证书(x509 certs)的工具。这些证书代表一个身份，并允许在网络实体间通信和交易时进行签名和身份认证。

cryptogen使用一个包含网络拓扑的crypto-config.yaml文件，为文件中定义的组织和属于这些组织的实体生成一组证书和密钥。每个组织都配置唯一的根证书（ca-cert），并包含了特定的实体（peer和orders），这就形成李一种典型的网络结构--每个成员都有所属杜CA。hyperleder fabric网络中的交易和通信都使用实体杜私钥签名，使用公钥验证。

## 编译生成cryptogen

cryptogen源码在fabric/common/tools/cryptogen/中，是一个独立杜可执行程序。

生成cryptogen可执行程序有两种方式。

1）在fabric/下执行make cryptogen，如果正常执行，则会在fabric/build/bin/下生成可执行文件cryprogen。

`make cryptogen`
命令会生
build/bin/cryptogen
里边生成crytogen工具。
2）直接在fabric/common/tools/cryptogen/下执行 `go build`。

2 crypto-config.yaml文件

```yaml
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

3 cryptogen命令说明

使用如下命令，生成证书文件：

```bash
cryptogen generate--config=./crypto-config.yaml
```

保存在crypto-config目录下

# configtxgen命令

configtxgen模块用来生成orderer的初始化文件和channel的初始化文件，configtxgen的

参数如下：

```bash
vagrant@ubuntu-xenial:/opt/gopath/src/github.com/hyperledger/fabric$ configtxgen --help
Usage of configtxgen:
  -asOrg string
      作为特定的组织(按名称string)执行配置生成，只包括org(可能)有权设置的写集中的值。如用来指明生成的锚节点所在的组织
  -channelCreateTxBaseProfile string
      指定一个概要文件作为orderer系统通道当前状态，以允许在通道创建tx生成期间修改非应用程序参数。仅在与“outputCreateChannelTx”组合时有效。
  -channelID string
      在configtx中使用的通道ID，即通道名称，默认是"testchainid"
  -configPath string
      包含要使用的配置的路径(如果设置的话)
  -inspectBlock string
      按指定路径打印块中包含的配置，用于检查和输出通道中创世区块的内容，锚节点在configtx.yaml中的AnchorPeers中指定
  -inspectChannelCreateTx string
      按指定路径打印交易中包含的配置，用来检查通道的配置交易信息
  -outputAnchorPeersUpdate string
      创建一个配置更新来更新锚节点(仅在默认通道创建时工作，并且仅在第一次更新时工作)
  -outputBlock string
      将genesis块写入(如果设置)的路径。configtx.yaml文件中的Profiles要指定Consortiums，否则启动排序服务节点会失败
  -outputCreateChannelTx string
      将通道配置交易文件写入(如果设置)的路径。configtx.yaml文件中的Profiles必须包含Application，否则创建通道会失败
  -printOrg string
      将组织的定义打印为JSON。(对于手动向通道添加组织非常有用)
  -profile string
      指定使用的是configtx.yaml中某个用于生成的Profiles配置项。(默认为“SampleInsecureSolo”)
  -version
      显示版本信息
```

## ****configtxgen模块的配置文件****

configtxgen模块的配置文件包括[Fabric](https://so.csdn.net/so/search?q=Fabric&spm=1001.2101.3001.7020)系统初始块、channel初始块文件等信息。configtxgen模块配置文件示例：

> 这个示例就是《Fabric实战（2）运行一个简单的fabric网络（容器外）》的configtx.yaml文件。

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
        Policies:    #定义相关策略
            Readers:     #可读
                Type: Signature
                Rule: "OR('OrdererMSP.member')"       #具体策略：允许OrdererMSP中所有member读操作
                # Rule: "OR('SampleOrg.admin', 'SampleOrg.peer', 'SampleOrg.client')"
            Writers:    #可写
                Type: Signature
                Rule: "OR('OrdererMSP.member')"
            Admins:    #admin
                Type: Signature
                Rule: "OR('OrdererMSP.admin')"
        # orderer节点列表，用来推送事务和接收块
        OrdererEndpoints:
            - orderer0.xinhe.com:7050
            - orderer1.xinhe.com:7150
            - orderer2.xinhe.com:7250

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
              Port: 7051

#该部分用户定义 Fabric 网络的功能。
#Capabilities段定义了fabric程序要加入网络所必须支持的特性。
#例如，如果添加了一个新的MSP类型，那么更新的程序可能会根据该类型识别并验证签名，
#    但是老版本的程序就没有办法验证这些交易。这可能导致不同版本的fabric程序中维护的世界状态不一致。
Capabilities:   #这一区域主要是定义版本的兼容情况
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
    # 目前可用的类型为：
#    solo：在Hyperledger Fabric中的solo模式的共识算法，是最简单的一种共识算法，只有一个排序节点（order）接收客户端peer节点消息，并完成排序，按照order节点的排序结果进行生成区块和上链处理。此种模式只能在测试环境中使用，不适合生产环境大规模使用。
#    kafka：由一组orderer节点组成排序服务节点，与Kafka集群进行对接，利用Kafka完成消息的共识功能。
#       客户端peer节点向Orderer节点集群发送消息后，经过Orderer节点组的背书后，封装成Kafka消息格式，然后发往Kafka集群，
#       完成交易信息的统一排序。如果联盟链中有多个channel，在Kafka中实现就是按照每个channel一个topic的设定，每个channel都有一条链。
#    EtcdRaft：
    OrdererType: etcdraft
    # Orderer服务地址列表,这个地方很重要，一定要配正确
    Addresses:
        - orderer0.xinhe.com:7050
        - orderer1.xinhe.com:7150
        - orderer2.xinhe.com:7250

    EtcdRaft:
        Consenters:
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

    # 区块打包的最大超时时间 (到了该时间就打包区块)
    BatchTimeout: 2s
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
        #定义谁可以调用交付区块的API
        Readers:
            Type: ImplicitMeta
            Rule: "ANY Readers"
        #定义谁可以调用广播区块的API
        Writers:
            Type: ImplicitMeta
            Rule: "ANY Writers"
        #定义谁可以修改配置信息
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
                # 联盟中包含的组织
                Organizations:
                    - *Org1
                    - *Org2
                    - *Org3
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
                - *Org3
            Capabilities:
                <<: *ApplicationCapabilities    # 这里直接引用上面Capabilities配置段中的ApplicationCapabilities
```

## ****configtxgen模块的应用场景****

创建orderer初始快的命令示例：

```bash
#通过configtx.yaml文件中的TwoOrgsOrdererGenesis配置信息生成创世区块
#使用以下命令生成创世区块。
configtxgen -profile TwoOrgsOrdererGenesis -channelID fabric-channel -outputBlock ./channel-artifacts/genesis.block
```

## ****生成创建channel的提案文件****

```bash
#通过configtx.yaml文件中的TwoOrgsChannel配置信息生成通道提案文件。
configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID mychannel
```

## ****创建锚点更新文件****

```bash
# 通过configtx.yaml文件中的TwoOrgsChannel配置信息生成组织****锚****节点更新文件
#使用以下命令为 Org1 定义锚节点。
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID mychannel -asOrg Org1MSP
#使用以下命令为 Org2 定义锚节点。
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx -channelID mychannel -asOrg Org2MSP
```
