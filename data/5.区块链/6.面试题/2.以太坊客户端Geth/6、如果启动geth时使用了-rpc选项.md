### 如果启动geth时使用了-rpc选项，哪些RPC会被启用

当启动 Geth 客户端时，使用 `-rpc` 选项会启用 **JSON-RPC** 服务，允许通过 HTTP 协议访问一系列以太坊相关的 API。

下面详细介绍一下 `-rpc` 选项启用的服务以及如何配置和使用这些服务。

### 启用 JSON-RPC 服务

#### 基本配置

```sh
geth --datadir /path/to/data/folder --rpc
```

这里的参数说明：

- `--datadir`：指定数据目录，用于存储区块链数据、密钥等信息。
- `--rpc`：启用 JSON-RPC 服务。

#### 配置监听地址和端口

默认情况下，JSON-RPC 服务只会监听本地地址 `localhost`，并且监听端口为 `8545`。

如果你想让 Geth 的 JSON-RPC 服务对外网可见，可以使用以下选项来配置监听地址和端口：

```sh
geth --datadir /path/to/data/folder --rpc --rpc.addr "0.0.0.0" --rpc.port 8545
```

这里的参数说明：

- `--rpc.addr`：指定 JSON-RPC 服务监听的 IP 地址，默认为 `localhost`。使用 `0.0.0.0` 表示监听所有 IP 地址。
- `--rpc.port`：指定 JSON-RPC 服务监听的端口，默认为 `8545`。

### 启用的 JSON-RPC 服务

当使用 `-rpc` 选项启动 Geth 时，会启用以下 JSON-RPC API：

1. **Eth API**：与以太坊区块链相关的 API，包括但不限于：
    - `eth_blockNumber`：获取当前区块高度。
    - `eth_getBalance`：获取账户余额。
    - `eth_sendTransaction`：发送交易。
    - `eth_call`：执行消息调用。
    - `eth_estimateGas`：估算执行交易所需的 gas。
    - `eth_getBlockByNumber`：通过区块高度获取区块信息。
    - `eth_getTransactionByHash`：通过交易哈希获取交易信息。
    - `eth_getTransactionReceipt`：获取交易收据。
    - `eth_subscribe`：订阅事件，如新区块、新交易等。

2. **Net API**：与网络相关的信息，包括但不限于：
    - `net_version`：获取网络 ID。
    - `net_peerCount`：获取当前连接的对等节点数量。
    - `net_listening`：检查客户端是否正在监听网络。

3. **Personal API**：与账户管理相关的 API，包括但不限于：
    - `personal_importRawKey`：导入一个未加密的私钥。
    - `personal_listAccounts`：列出所有已知账户。
    - `personal_lockAccount`：锁定一个账户。
    - `personal_newAccount`：创建一个新的加密账户。
    - `personal_sendTransaction`：发送一个交易，需要账户解锁。
    - `personal_sign`：使用私钥对数据进行签名。

4. **Admin API**：与管理相关的 API，默认情况下，Geth 的 Admin API 并不是自动启用的，因为它包含了一些可能会影响节点安全性的管理功能。

   包括但不限于：

    - `admin_addPeer`：添加一个静态节点。
    - `admin_datadir`：返回数据目录。
    - `admin_nodeInfo`：返回节点信息。
    - `admin_peers`：返回当前连接的对等节点列表。
    - `admin_startRPC`：启动一个 JSON-RPC 服务器。
    - `admin_stopRPC`：停止 JSON-RPC 服务器。

5. **Debug API**：与调试相关的 API，包括但不限于：
    - `debug_backtraceAt`：返回给定事务的回溯。
    - `debug_blockProfile`：生成区块级别的性能分析报告。
    - `debug_cpuProfile`：生成 CPU 级别的性能分析报告。
    - `debug_dumpBlock`：导出一个区块的状态树。
    - `debug_freeOSMemory`：释放操作系统内存。
    - `debug_gcStats`：获取垃圾回收统计信息。
    - `debug_goTrace`：生成 Go 级别的跟踪报告。
    - `debug_memStats`：获取内存统计信息。

6. **Txpool API**：与交易池相关的 API，包括但不限于：
    - `txpool_content`：获取交易池的内容。
    - `txpool_inspect`：获取交易池的状态信息。
    - `txpool_status`：获取交易池的状态。

7. **Web3 API**：与 Web3 相关的 API，包括但不限于：
    - `web3_clientVersion`：返回客户端的版本信息。
    - `web3_sha3`：计算数据的 Keccak-256 哈希值。