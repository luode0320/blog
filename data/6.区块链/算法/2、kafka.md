# 简介

> Hyperledger Fabric的核心共识算法通过Kafka集群实现



**简单来说，就是通过Kafka自带的共识算法对所有交易信息进行排序。**

# 工作原理

在Kafka共识机制实际运行逻辑如下：

- 每一条channel链，都有一个对应的topic主题和patition分区, 并且为了保证顺序性，只设置了一个patition=0的分区
- 排序节点负责将来自特定链的交易（通过广播gRPC接收）传输到对应的分区
- 排序节点读取分区, 并获得在所有排序节点间达成一致的排序交易列表(kafka排的)
- 一个链中的交易是定时分批处理的，也就是说当一个新的批次的第一个交易进来时，开始计时
- 当交易达到最大数量时或超时后进行批次切分，生成新的区块
- 定时交易是另一个交易，由上面描述的定时器生成
- 每个排序节点为每个链维护一个本地日志，生成的区块保存在本地账本中
- 交易区块通过分发RPC返回客户端
- 当发生崩溃时，可以利用不同的排序节点分发区块，因为所有的排序节点都维护有本地日志

# 源码解析

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
	// 检查节点是否从Raft迁移而来
	if consenter.inactiveChainRegistry != nil {
		logger.Infof("该节点已从Kafka迁移到Raft，跳过Kafka链的激活")
		// 跟踪链，当应激活时调用回调函数
		consenter.inactiveChainRegistry.TrackChain(support.ChannelID(), support.Block(0), func() {
			consenter.mkChain(support.ChannelID())
		})
		// 返回一个表示链不被当前节点服务的inactive.Chain实例
		return &inactive.Chain{Err: errors.Errorf("通道 %s 不由我服务", support.ChannelID())}, nil
	}

	// 创建共识实例
	lastOffsetPersisted, lastOriginalOffsetProcessed, lastResubmittedConfigOffset := getOffsets(metadata.Value, support.ChannelID())
	ch, err := newChain(consenter, support, lastOffsetPersisted, lastOriginalOffsetProcessed, lastResubmittedConfigOffset)
	if err != nil {
		return nil, err
	}

	// 注册健康检查
	consenter.healthChecker.RegisterChecker(ch.channel.String(), ch)
	return ch, nil
}

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
	// 记录日志，表明链启动并记录相关偏移量和最后截断的区块高度
	logger.Infof("[通道: %s] 启动链，最后持久化偏移量为 %d，最后记录的区块编号为 [%d]",
		support.ChannelID(), lastOffsetPersisted, lastCutBlockNumber)

	// 初始化信号量，用于控制是否完成重新处理飞行中的消息
	doneReprocessingMsgInFlight := make(chan struct{})
	// 1. 从未重新提交过任何配置消息（lastResubmittedConfigOffset == 0）
	// 2. 最近重新提交的配置消息已经被处理（lastResubmittedConfigOffset == lastOriginalOffsetProcessed）
	// 3. 在最新的重新提交配置消息之后，已经处理了一个或多个普通消息（lastResubmittedConfigOffset < lastOriginalOffsetProcessed）
	if lastResubmittedConfigOffset == 0 || lastResubmittedConfigOffset <= lastOriginalOffsetProcessed {
		// 已经跟上重新处理进度，关闭通道以允许广播继续
		close(doneReprocessingMsgInFlight)
	}

	// 更新共识器的度量指标，记录最后持久化偏移量
	consenter.Metrics().LastOffsetPersisted.With("channel", support.ChannelID()).Set(float64(lastOffsetPersisted))

	// 创建并返回chainImpl实例，初始化内部成员变量
	return &chainImpl{
		consenter:                   consenter,                                         // 共识器实例
		ConsenterSupport:            support,                                           // 支持资源
		channel:                     newChannel(support.ChannelID(), defaultPartition), // 创建通道实例
		lastOffsetPersisted:         lastOffsetPersisted,                               // 持久化偏移量
		lastOriginalOffsetProcessed: lastOriginalOffsetProcessed,                       // 处理的偏移量
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