# 简介

> 在Hyperledger Fabric中，Orderer模块可以使用Solo共识机制来确保分布式系统的可靠性和一致性。
>
> 注意: fabric新版本已经无法使用solo和kafka的共识机制



**Solo共识机制是一种基于单一Orderer节点的共识算法，它在网络只有一个Orderer节点的情况下使用。**

# 工作原理

在Solo共识机制中只有一个Orderer排序节点

- 所有的Peer节点通过gPRC连接排序服务将交易发送给Orderer节点
- Orderer节点通过Recv接口按照接收到的交易顺序生成区块, 写入本地账本, 并将这些区块广播给所有的Peer节点
- Peer节点通过deliver接口，获取排序服务生成的区块数据。

由于只有一个Orderer节点，因此不存在节点间的共识问题，Orderer节点只需按照接收到的交易顺序生成区块即可

由于排序服务只有一个排序节点为所有Peer节点服务，没有高可用性和可扩展性，不适合用于生产环境，通常用于开发和测试环境。

# 结论

solo没有做任何处理, 它就是将接受到的消息和配置的区块最大值比较后是否需要分到下一个高度而已, 没有做任何处理

**如果你觉得简单说结论得不到信任, 请继续看下面的解析!**

# 源码位置

算法位于Fabric的`orderer/consensus/solo`包下

在Orderer模块中，Solo共识机制的实现主要涉及到以下文件：

- `orderer/consensus/consensus.go`：这是切换共识算法的接口, 主要是入口函数`HandleChain`
- `orderer/consensus/solo/consensus.go`：该文件定义了Solo共识机制的核心结构体和相关方法

# 源码解析

> 直接分析solo的核心处理逻辑: `orderer/consensus/solo/consensus.go`

- 核心逻辑是`orderer/consensus/solo/consensus.go/start`方法
- 阅读源码的逻辑应该是直接看`start`方法
- 遇到不清楚的结构、方法和定义再深入
- 文章的顺序是直接分析`start`方法

虽然我们知道了核心代码在`start`方法, 但是这里我要指出orderer排序节点调用它的入口函数`HandleChain`(可以不深究)

**orderer/consensus/solo/consensus.go/HandleChain**

```go
// HandleChain 处理新链的初始化，警告用户Solo共识仅适用于测试。
func (solo *consenter) HandleChain(support consensus.ConsenterSupport, metadata *cb.Metadata) (consensus.Chain, error) {
	logger.Warningf("使用Solo排序服务已过时，仅限测试环境，并可能在未来移除。")
	return newChain(support), nil // 创建并返回新的chain实例
}
// newChain 创建一个新的chain实例，初始化其内部状态。
// 这个虽然不是接口函数, 但是其他的共识算法也用这个同名的方法创建算法实例
func newChain(support consensus.ConsenterSupport) *chain {
	return &chain{
		support:  support,
		sendChan: make(chan *message), // 初始化消息发送通道
		exitChan: make(chan struct{}), // 初始化退出通道
	}
}
```

这是入口函数`HandleChain`, 就算是kafka、reft等其他共识算法, 也是用这个方法创建我们的算法对象的

然后才会使用算法对象来调用`main`方法执行相关算法逻辑

这个不用太深究, 如果需要直接研究源码, 可以从这个函数入手

## start()

> Start会开一个goroutine允许共识程序

- 主要核心逻辑: select多路复用
    1. 处理接收到的消息
    2. 定时器触发超时产生新的块
    3. 停止共识

**算法的核心代码: 因为文章是解析solo算法, 所以对于一些不重要的逻辑, 可以跳过**

```go
// Start 启动共识的主循环处理过程。
func (ch *chain) Start() {
	go ch.main() // 在新goroutine中运行链的主循环
}

// main 共识的主循环函数，处理消息、执行批次切割、生成区块并写入账本。
func (ch *chain) main() {
    ...
    // 对消息进行批次切割，并写入区块。
    batches, pending := ch.support.BlockCutter().Ordered(msg.normalMsg)
    // 下面的for遍历就是将排序好的数据写入账本, 和共识算法没有关系
    for _, batch := range batches {
        block := ch.support.CreateNextBlock(batch)
        ch.support.WriteBlock(block, nil)
    }
    ...
}
```

从代码可以简单分析出`ch.support.BlockCutter().Ordered(msg.normalMsg)`是solo算法的重点

所以我们的重点就是`BlockCutter()`和`Ordered(msg.normalMsg)`

## BlockCutter()

```go
// ConsenterSupport 提供给Consenter实现可用的资源接口。
type ConsenterSupport interface {
	// BlockCutter 返回此通道的区块切割助手。
	BlockCutter() blockcutter.Receiver
}
```

实现:

```go
// BlockCutter 返回与此通道关联的 blockcutter.Receiver 实例。
// blockcutter.Receiver 负责接收交易并将它们组织成批次，以便高效地组成区块。
func (cs *ChainSupport) BlockCutter() blockcutter.Receiver {
	return cs.cutter
}
```

这将返回一个负责接收交易并将它们组织成批次的对象, 后面我们将调用这个对象你们的方法实现共识逻辑

所以solo核心应该在`Ordered(msg.normalMsg)`

## Ordered(msg.normalMsg)

```go
// Receiver 定义了一个有序广播消息的接收器接口。
type Receiver interface {
	// Ordered 应在消息被排序时依次调用。
    // `msg`接收的消息本身。
	// `messageBatches`中的每个批次都将被打包进一个区块中。
	// `pending`表示接收器中是否仍有待处理的消息。
	Ordered(msg *cb.Envelope) (messageBatches [][]*cb.Envelope, pending bool)
}
```

实现:

```go
// Ordered 方法应该随着消息的有序到达而被顺序调用。
//
// messageBatches 长度及 pending 参数可能的情况如下：
//
// - messageBatches 长度: 0, pending: false
//   - 不可能发生，因为我们刚接收到一条消息。
//
// - messageBatches 长度: 0, pending: true
//   - 没有切割批次，且有待处理的消息。
//
// - messageBatches 长度: 1, pending: false
//   - 消息计数达到了 BatchSize.MaxMessageCount 的限制。
//
// - messageBatches 长度: 1, pending: true
//   - 当前消息将导致待处理批次的字节大小超过 BatchSize.PreferredMaxBytes。
//
// - messageBatches 长度: 2, pending: false
//   - 当前消息的字节大小超过了 BatchSize.PreferredMaxBytes，因此被单独放在一个批次中。
//
// - messageBatches 长度: 2, pending: true
//   - 不可能发生。
//
// 注意：messageBatches 的长度不能大于 2。
func (r *receiver) Ordered(msg *cb.Envelope) (messageBatches [][]*cb.Envelope, pending bool) {
	if len(r.pendingBatch) == 0 {
		// 开始新批次时记录时间
		r.PendingBatchStartTime = time.Now()
	}

	// 获取排序服务配置
	ordererConfig, ok := r.sharedConfigFetcher.OrdererConfig()
	if !ok {
		logger.Panicf("无法检索排序服务配置以查询批次参数，无法进行区块切割")
	}

	// 这个batchSize就是通道配置中的batchSize
	batchSize := ordererConfig.BatchSize()

	// 计算当前消息的字节大小
	messageSizeBytes := messageSizeBytes(msg)
	if messageSizeBytes > batchSize.PreferredMaxBytes {
		logger.Debugf("当前消息大小为 %v 字节，超过了首选最大批次大小 %v 字节，将被单独隔离。", messageSizeBytes, batchSize.PreferredMaxBytes)

		// 如果有待处理的消息，则先切割现有批次
		if len(r.pendingBatch) > 0 {
			messageBatch := r.Cut()
			messageBatches = append(messageBatches, messageBatch)
		}

		// 创建只包含当前消息的新批次
		messageBatches = append(messageBatches, []*cb.Envelope{msg})

		// 记录该批次填充时间为0
		r.Metrics.BlockFillDuration.With("channel", r.ChannelID).Observe(0)

		return
	}

	// 检查消息是否会超出当前批次的预设最大字节大小
	messageWillOverflowBatchSizeBytes := r.pendingBatchSizeBytes+messageSizeBytes > batchSize.PreferredMaxBytes
	if messageWillOverflowBatchSizeBytes {
		logger.Debugf("当前消息大小为 %v 字节，将使待处理批次大小 %v 字节溢出。", messageSizeBytes, r.pendingBatchSizeBytes)
		logger.Debugf("如果添加当前消息，待处理批次将会溢出，现在进行批次切割。")
		messageBatch := r.Cut()
		r.PendingBatchStartTime = time.Now() // 重置批次开始时间
		messageBatches = append(messageBatches, messageBatch)
	}

	logger.Debugf("将消息加入到批次中")
	r.pendingBatch = append(r.pendingBatch, msg)
	r.pendingBatchSizeBytes += messageSizeBytes
	pending = true

	// 检查消息数量是否达到最大限制
	if uint32(len(r.pendingBatch)) >= batchSize.MaxMessageCount {
		logger.Debugf("达到批次消息数量上限，进行批次切割")
		messageBatch := r.Cut()
		messageBatches = append(messageBatches, messageBatch)
		pending = false
	}

	return
}

// Cut 方法返回当前批次并开始一个新的批次。
func (r *receiver) Cut() []*cb.Envelope {
	if r.pendingBatch != nil {
		// 记录当前批次填充耗时（从开始构建批次到切割的时间）
		r.Metrics.BlockFillDuration.With("channel", r.ChannelID).Observe(time.Since(r.PendingBatchStartTime).Seconds())
	}
	// 重置批次开始时间
	r.PendingBatchStartTime = time.Time{}
	// 保存当前批次并清空，准备下一个批次
	batch := r.pendingBatch
	r.pendingBatch = nil
	r.pendingBatchSizeBytes = 0 // 重置批次字节大小计数
	return batch                // 返回已切割的批次
}
```

> 实际上并没有任何其他的逻辑, 完全就是比较是否超出了配置的最大值, 是否需要分成小块然后保存到账本

