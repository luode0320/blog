### 哪些RPC API是默认启用的

eth、web3、net、debug、personal

默认情况下，Geth 的 Admin API 并不是自动启用的，因为它包含了一些可能会影响节点安全性的管理功能。

下面列出了默认启用的主要 JSON-RPC API 命名空间及其部分 API：

### 默认启用的 JSON-RPC API 命名空间

#### Eth API

Eth API 提供了与以太坊区块链相关的各种操作，包括区块查询、账户管理、交易发送等。

- `eth_blockNumber`：获取当前区块高度。
- `eth_getBalance`：获取账户余额。
- `eth_sendTransaction`：发送交易。
- `eth_call`：执行消息调用。
- `eth_estimateGas`：估算执行交易所需的 gas。
- `eth_getBlockByNumber`：通过区块高度获取区块信息。
- `eth_getTransactionByHash`：通过交易哈希获取交易信息。
- `eth_getTransactionReceipt`：获取交易收据。
- `eth_subscribe`：订阅事件，如新区块、新交易等。

#### Net API

Net API 提供了与网络相关的信息，如网络版本、对等节点数量等。

- `net_version`：获取网络 ID。
- `net_peerCount`：获取当前连接的对等节点数量。
- `net_listening`：检查客户端是否正在监听网络。

#### Personal API

Personal API 提供了与账户管理相关的功能，如导入私钥、解锁账户、发送交易等。

- `personal_importRawKey`：导入一个未加密的私钥。
- `personal_listAccounts`：列出所有已知账户。
- `personal_lockAccount`：锁定一个账户。
- `personal_newAccount`：创建一个新的加密账户。
- `personal_sendTransaction`：发送一个交易，需要账户解锁。
- `personal_sign`：使用私钥对数据进行签名。

#### Admin API

Admin API 提供了一些管理功能，如添加静态节点、获取节点信息等。

默认情况下，Geth 的 Admin API 并不是自动启用的，因为它包含了一些可能会影响节点安全性的管理功能。

- `admin_addPeer`：添加一个静态节点。
- `admin_datadir`：返回数据目录。
- `admin_nodeInfo`：返回节点信息。
- `admin_peers`：返回当前连接的对等节点列表。
- `admin_startRPC`：启动一个 JSON-RPC 服务器。
- `admin_stopRPC`：停止 JSON-RPC 服务器。

#### Debug API

Debug API 提供了一些调试功能，如区块跟踪、性能分析等。

- `debug_backtraceAt`：返回给定事务的回溯。
- `debug_blockProfile`：生成区块级别的性能分析报告。
- `debug_cpuProfile`：生成 CPU 级别的性能分析报告。
- `debug_dumpBlock`：导出一个区块的状态树。
- `debug_freeOSMemory`：释放操作系统内存。
- `debug_gcStats`：获取垃圾回收统计信息。
- `debug_goTrace`：生成 Go 级别的跟踪报告。
- `debug_memStats`：获取内存统计信息。
- `debug_seedHash`：获取挖矿种子哈希。
- `debug_setBlockProfileRate`：设置区块级别的性能分析速率。
- `debug_setGCPercent`：设置垃圾回收百分比。
- `debug_setHead`：设置当前头部区块。
- `debug_startCPUProfile`：开始 CPU 级别的性能分析。
- `debug_startGoTrace`：开始 Go 级别的跟踪。
- `debug_stopCPUProfile`：停止 CPU 级别的性能分析。
- `debug_stopGoTrace`：停止 Go 级别的跟踪。
- `debug_traceBlockByNumber`：跟踪一个区块的执行。
- `debug_traceBlockByHash`：跟踪一个区块的执行。
- `debug_traceBlock`：跟踪一个区块的执行。
- `debug_traceTransaction`：跟踪一个交易的执行。
- `debug_tracingOn`：开启追踪。
- `debug_tracingOff`：关闭追踪。

#### Txpool API

Txpool API 提供了与交易池相关的功能，如获取交易池内容、状态等。

- `txpool_content`：获取交易池的内容。
- `txpool_inspect`：获取交易池的状态信息。
- `txpool_status`：获取交易池的状态。

#### Web3 API

Web3 API 提供了一些基础功能，如客户端版本信息、SHA3 哈希计算等。

- `web3_clientVersion`：返回客户端的版本信息。
- `web3_sha3`：计算数据的 Keccak-256 哈希值。