# 简介

> Hyperledger Fabric的核心共识算法通过Kafka集群实现
>
> 注意: fabric新版本已经无法使用solo和kafka的共识机制



**简单来说，就是通过Kafka自带的共识算法对所有交易信息进行排序 ->  KRaft 共识协议**

# 工作原理

在Kafka共识机制实际运行逻辑如下：

- 每一条channel链，都有一个对应的topic主题和patition分区, 并且为了保证顺序性，只设置了一个patition=0的分区
- 排序节点负责将来自特定链的交易（通过广播gRPC接收）传输到对应的分区
- 所有排序节点都属于这个分区消费者组内的一个消费者, 排序节点会消费分区消息
- 当交易达到最大数量时或超时后, 进行批次切分成区块并编号高度，按照区块高度的顺序打包生成新的区块
- 打包好的区块通过分发gRPC返回客户端

# 结论

fabric的kafka共识机制本身没有做任何排序处理, 共识和排序完全由kafka控制, 通过单主题单分区的kafka配置达成交易的共识和顺序

fabric本身就是将接受到的消息和配置的区块最大值比较后是否需要分到下一个高度而已, 没有做任何处理

**如果你觉得简单说结论得不到信任, 请继续看下面的解析, 并且最后会解析kafka的共识算法kraft**

# fabric源码解析

> 算法位于Fabric的`orderer/consensus/kafka`包下

核心逻辑是`orderer/consensus/solo/consensus.go/start`方法

在Orderer模块中，kafka共识机制的实现主要涉及到以下文件：

- `orderer/consensus/consensus.go`：这是切换共识算法的接口, 主要是入口函数`HandleChain`
- `orderer/consensus/kafka/chain.go`：该文件定义了kafka共识机制的核心结构体和逻辑方法, `start`在这里
- `orderer/consensus/kafka/consenter.go`: 该文件用来实例化上面chain.go的共识实例, `HandleChain`的实现也在这里
- `orderer/consensus/kafka/channel.go`: 获取网络通道的kafka主题和分区的方法, 用于发送消息到kafka时设置主题和分区
- `orderer/consensus/kafka/config.go`: 封装了使用Sarama创建kafka连接实例

这里我要指出orderer排序节点调用它的入口函数`HandleChain`(可以不深究)

**orderer/consensus/kafka/consenter.go/HandleChain**

```go
// HandleChain 根据给定的支持资源创建或返回一个共识.Chain实例。实现共识.Consenter接口。
func (consenter *consenterImpl) HandleChain(support consensus.ConsenterSupport, metadata *cb.Metadata) (consensus.Chain, error) {
	...
	// 获取kafka最后偏移量、排序节点最后处理的高度、通道配置最后一次处理的高度
	lastOffsetPersisted, lastOriginalOffsetProcessed, lastResubmittedConfigOffset := getOffsets(metadata.Value, support.ChannelID())
    // 创建共识实例
	ch, err := newChain(consenter, support, lastOffsetPersisted, lastOriginalOffsetProcessed, lastResubmittedConfigOffset)
	if err != nil {
		return nil, err
	}
    ...
	return ch, nil
}
```

```go

// newChain 用于根据提供的共识器、支持资源以及偏移量信息创建一个新的链实例。
// 参数:
//   - consenter: 满足commonConsenter接口的共识器实例，提供了基础配置和度量指标。
//   - support: 提供了链操作支持，如账本访问、配置验证等功能。
//   - lastOffsetPersisted: 上次持久化消息的偏移量。
//   - lastOriginalOffsetProcessed: 最后处理的原始消息偏移量。
//   - lastResubmittedConfigOffset: 最后重新提交的配置消息偏移量。
//
// 返回:
//   - *chainImpl: 新创建的链实例。
//   - error: 如果创建过程中发生错误。
func newChain(
	consenter commonConsenter,
	support consensus.ConsenterSupport,
	lastOffsetPersisted int64,
	lastOriginalOffsetProcessed int64,
	lastResubmittedConfigOffset int64,
) (*chainImpl, error) {
	// 获取上次截断区块的高度 = 最新的区块高度 - 1
	lastCutBlockNumber := getLastCutBlockNumber(support.Height())
	...
	// 创建并返回chainImpl实例，初始化内部成员变量
	return &chainImpl{
		consenter:                   consenter,                                         // 共识器实例
		ConsenterSupport:            support,                                           // 支持资源
		channel:                     newChannel(support.ChannelID(), defaultPartition), // 创建通道实例
		lastOffsetPersisted:         lastOffsetPersisted,                               // kafka持久化偏移量
		lastOriginalOffsetProcessed: lastOriginalOffsetProcessed,                       // 排序节点处理的偏移量
		lastResubmittedConfigOffset: lastResubmittedConfigOffset,                       // 重新提交的配置偏移量
		lastCutBlockNumber:          lastCutBlockNumber,                                // 最后截断的区块号

		haltChan:                    make(chan struct{}),         // 用于停止链的通道
		startChan:                   make(chan struct{}),         // 用于启动链的通道
		doneReprocessingMsgInFlight: doneReprocessingMsgInFlight, // 重新处理消息完成信号
	}, nil
}
```

这是入口函数`HandleChain`, 就算是sole、reft等其他共识算法, 也是用这个方法创建我们的算法对象的

然后才会使用算法对象来调用方法执行相关算法逻辑

这个不用太深究, 如果需要直接研究源码, 可以从这个函数入手

## start()

> Start会开一个goroutine允许共识程序

- 主要核心逻辑: select多路复用
    1. 处理接收到的消息
    2. 定时器触发超时产生新的块
    3. 停止共识

**算法的核心代码: 因为文章是解析kafka共识算法, 所以对于一些不重要的逻辑, 可以跳过**

```go
// Start 启动共识的主循环处理过程。
func (chain *chainImpl) Start() {
	// 启动一个新的goroutine来执行startThread函数，确保Start方法本身不会阻塞
	go startThread(chain)
}
```

```go
// 作为启动共识处理流程的入口点，负责执行一系列初始化操作，包括但不限于创建Kafka主题、设置生产者与消费者、发送CONNECT消息、获取副本信息等
// 确保链能够开始正常工作并保持与Kafka主题的数据同步。
// 所有步骤完成后，会启动一个循环处理消息至区块的流程，以维护链的实时状态。
func startThread(chain *chainImpl) {
	var err error
	// 创建主题
    // 创建生产者
    // 创建消费者
    ...
    // 开始处理消息至区块的循环，保持与通道的最新状态同步
	chain.processMessagesToBlocks()
}
```

```go
// 负责消耗指定通道的Kafka消费者中的消息，并将有序消息流转换为通道账本的区块。
// 返回:
//   - []uint64: 各类操作的计数统计。
//   - error: 在处理消息到区块过程中遇到的错误。
func (chain *chainImpl) processMessagesToBlocks() ([]uint64, error) {
    // 消费者拉取消息
    ...
    // 根据消息类型处理
    switch msg.Type.(type) {
    ...
    // 处理kafka普通消息
    case *ab.KafkaMessage_Regular:
        // 其实这里就已经和共识没有关系了, 因为按照顺序从kafka拉取数据, 最后就是打包好就可以了
        if err := chain.processRegular(msg.GetRegular(), in.Offset); err != nil {
            logger.Warningf("[通道: %s] 处理类型为REGULAR的传入消息时发生错误 = %s", chain.ChannelID(), err)
            counts[indexProcessRegularError]++
        } else {
            counts[indexProcessRegularPass]++
        }
    }
}
```

```go
// 处理常规类型的消息，这些消息通常包含事务数据。
// 参数:
//   - regularMessage: 指向常规Kafka消息的指针，包含交易信封。
//   - receivedOffset: 消息在Kafka主题中的原始偏移量。
//
// 功能:
//   - 根据传入的规则更新`lastOriginalOffsetProcessed`。
//   - 使用BlockCutter对消息进行切割成有序高度的块，判断是否需要切割新的区块。
//   - 分别处理切割单个区块和两个区块的情况，确保偏移量的正确更新和存储。
//   - 调用CreateNextBlock和WriteBlock方法来创建新区块，并附加上相应的Kafka元数据。
func (chain *chainImpl) processRegular(regularMessage *ab.KafkaMessageRegular, receivedOffset int64) error {
    ...
    // 定义一个内部函数用于提交普通消息并处理偏移量更新
    commitNormalMsg := func(message *cb.Envelope, newOffset int64) {
        // 使用BlockCutter对消息进行切割成有序高度的块，返回当前批次和是否还有剩余未处理消息
        batches, pending := chain.BlockCutter().Ordered(message)
		...
        // 处理第一个切割区块
        block := chain.CreateNextBlock(batches[0])
        metadata := &ab.KafkaMetadata{
            LastOffsetPersisted:         offset,
            LastOriginalOffsetProcessed: chain.lastOriginalOffsetProcessed,
            LastResubmittedConfigOffset: chain.lastResubmittedConfigOffset,
        }
		// 调用底层 consenter 支持的 WriteBlock 方法，将区块及编码后的元数据写入最佳到区块链的结构中(此时并没有写入文件的操作)
        chain.WriteBlock(block, metadata)
        ...
        // 如果存在第二个批次，继续处理并切割第二个区块
        if len(batches) == 2 {
			...
            block := chain.CreateNextBlock(batches[1])
            metadata = &ab.KafkaMetadata{
                LastOffsetPersisted:         offset,
                LastOriginalOffsetProcessed: newOffset,
                LastResubmittedConfigOffset: chain.lastResubmittedConfigOffset,
            }
			// 调用底层 consenter 支持的 WriteBlock 方法，将区块及编码后的元数据写入最佳到区块链的结构中(此时并没有写入文件的操作)
            chain.WriteBlock(block, metadata)
            ...
        }
    }
}
```

```go
// WriteBlock 应用于包含常规交易的区块。
// 它将目标区块设为即将提交的下一个区块，并在提交前返回。
// 在返回前，它会获取提交锁，并启动一个goroutine来完成以下操作：
// 给区块添加元数据和签名，然后将区块写入账本，最后释放锁。
// 这样允许调用线程在提交阶段完成前开始组装下一个区块，提高了处理效率。
func (bw *BlockWriter) WriteBlock(block *cb.Block, encodedMetadataValue []byte) {
	...
	// 启动一个新的goroutine来异步处理区块提交
	go func() {
		// 调用commitBlock完成区块的元数据添加、签名及账本写入操作
		bw.commitBlock(encodedMetadataValue)
	}()
}

```

```go
// Append 将新区块以原始形式追加到账本中，
// 与 WriteBlock 不同，该操作不修改区块的元数据。
func (cs *ChainSupport) Append(block *cb.Block) error {
	return cs.ledgerResources.ReadWriter.Append(block)
}
```

所以fabric底层并没有什么共识和消息顺序处理, 它就是使用了Kafka自带的共识和消息顺序机制, 然后底层单独为kafka处理起了一个叫做kafka共识的名称

# kafka共识源码解析

截止到2024.6月, kafka最新版本已经是3.7.0, 已经去除了zk, 使用自带的kafka raft。

