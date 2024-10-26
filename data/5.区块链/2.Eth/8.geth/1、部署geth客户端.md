## Go Ethereum

以太坊协议的 Golang 执行层实现。

## 构建源

构建`geth`需要 Go（版本 1.21 或更高版本）和 C 编译器。

安装依赖项后, 运行

```shell
# linux
make geth

# windos: 参考 Makefile 文件的 geth 部分
./build/ci.go install ./cmd/clef
./build/ci.go install ./cmd/geth
```

或者，要构建全套实用程序，请执行以下操作：

```shell
make all
```

查看版本:

```shell
# linux
./build/bin/geth version

# windows
./build/bin/geth.exe version
```

输出:

```
Geth
Version: 1.14.9-unstable
Git Commit: 3801e3e616f4dc787533a2fd6bc8b57295f8a63b
Git Commit Date: 20240817
Architecture: amd64
Go Version: go1.21.0
Operating System: windows
GOPATH=E:\go-1.21.0\bin;C:\Users\Administrator\go
GOROOT=G:/golang
```

## 可执行文件

go-ethereum项目在 'cmd' 目录中提供了几个包装器/可执行文件.

|     命令     | 描述                                                                                                                                                                                                                                            |
|:----------:|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **`geth`** | 我们的主要以太坊 CLI 客户端<br />它是以太坊网络（主网main、测试网test或私有private网）的入口点<br />能够作为全节点运行（默认）, 备份节点（保留所有历史状态）或轻节点（实时检索数据） <br />                                                                                                                            |
|   `clef`   | 独立的签名工具，可以作为 'geth' 的后端签名者                                                                                                                                                                                                                    |
|  `devp2p`  | 用于与网络层上的节点交互的实用程序，而无需运行完整的区块链                                                                                                                                                                                                                 |
|  `abigen`  | 源代码生成器，用于将以太坊合约定义转换为易于使用、编译时类型安全的 Go 包. <br />它也接受 Solidity 源文件，使开发更加简化. 请参阅我们的 [原生 DApp](https://geth.ethereum.org/docs/developers/dapp-developer/native-bindings) 页面了解详细信息                                                                  |
| `bootnode` | 我们的以太坊客户端实现的精简版本，仅参与网络节点发现协议, 但不运行任何更高级别的应用程序协议. <br />它可以用作轻量级 bootstrap 节点，以帮助在专用网络中查找对等节点。                                                                                                                                                 |
|   `evm`    | EVM（以太坊虚拟机）的开发人员实用程序版本，能够在可配置的环境和执行模式下运行字节码片段. <br />其目的是允许对 EVM 操作码进行隔离、细粒度的调试 (e.g. `evm --code 60ff60ff --debug run`).                                                                                                                     |
| `rlpdump`  | 用于转换二进制 RLP 的开发人员实用工具 ([Recursive Length Prefix](https://ethereum.org/en/developers/docs/data-structures-and-encoding/rlp)) <br />转储 (以太坊协议使用的数据编码既包括网络方面，也包括共识方面) 实现用户友好的层次结构表示<br /> (e.g. `rlpdump --hex CE0183FFFFFFC4C304050583616263`). |

## 运行 geth

## 软件要求

* linux/windos: 启动 geth 客户端
* docker: 启动 prysm 共识节点

## 硬件要求

最低:

* 具有 2+ 核心的 CPU
* 4GB 内存
* 1TB免费存储空间同步主网
* 8 MBit/sec 下载互联网服务

推荐:

* 具有 4+ 核的快速 CPU
* 16GB+ 内存
* 高性能 SSD，至少 1TB 的可用空间
* 25+ MBit/sec 下载互联网服务

## 配置

所有配置信息可以查看[data/config.txt](data/config.txt)

## 创建一个钱包账户

```shell
# linux
./build/bin/clef newaccount --keystore ./data/sepolia/keystore

# windows
./build/bin/clef.exe newaccount --keystore ./data/sepolia/keystore
```

## 部署主网络上的全节点

到目前为止，最常见的情况是人们想要简单地与以太坊互动网络

- 创建帐户;转移资金;部署合同并与之交互。

- 为此在特定用例中，用户不关心多年前的历史数据，因此我们可以快速同步到网络的当前状态。

```shell
# linux
./build/bin/geth console --datadir ./data/sepolia --maxpeers 30 --cache 2048 --allow-insecure-unlock --gcmode archive --http --http.addr 0.0.0.0 --http.port 8545 --http.api admin,eth,net,web3,personal --http.corsdomain "*" --ws --ws.addr 0.0.0.0 --ws.port 8546 --ws.api admin,eth,net,web3,personal --ws.origins "*" --ipcdisable  --authrpc.addr 0.0.0.0 --authrpc.port 8551 --authrpc.jwtsecret ./data/sepolia/jwtsecret

# windows
./build/bin/geth.exe console --datadir ./data/sepolia --maxpeers 30 --allow-insecure-unlock --cache 2048 --gcmode archive --http --http.addr 0.0.0.0 --http.port 8545 --http.api admin,eth,net,web3,personal --http.corsdomain "*" --ws --ws.addr 0.0.0.0 --ws.port 8546 --ws.api admin,eth,net,web3,personal --ws.origins "*" --ipcdisable  --authrpc.addr 0.0.0.0 --authrpc.port 8551 --authrpc.jwtsecret ./data/sepolia/jwtsecret
```

参数解释：

- console: JavaScript控制台
- --datadir：数据库和密钥库的数据目录(默认:"~/.ethereum")
- --http.api：指定需要调用的HTTP-RPC API接口，默认只有eth,net,web3
- --http：启动HTTP-RPC服务（基于HTTP的）
- --http.addr：HTTP-RPC服务器监听地址(default: "localhost")
- --cache：分配给内部缓存的内存的兆字节 (默认值为: 1024)
- --maxpeers：最大的网络节点数量(如果设置为0，网络将被禁用)(默认值:50)
- --allow-insecure-unlock：允许使用不安全的账户解锁
- --authrpc.port：设置认证监听的api端口，默认为8551
- --authrpc.addr：允许连接认证监听api端口的IP地址
- --authrpc.vhosts：允许连接认证监听api端口的域名
- --authrpc.jwtsecret：设置身份验证的RPC接口的JWT私钥的路径

## 部署 sepolia 测试网络上的全节点

```shell
# linux
./build/bin/geth console --sepolia --datadir ./data/sepolia --maxpeers 30 --cache 2048 --allow-insecure-unlock --gcmode archive --http --http.addr 0.0.0.0 --http.port 8545 --http.api admin,eth,net,web3,personal --http.corsdomain "*" --ws --ws.addr 0.0.0.0 --ws.port 8546 --ws.api admin,eth,net,web3,personal --ws.origins "*" --ipcdisable  --authrpc.addr 0.0.0.0 --authrpc.port 8551 --authrpc.jwtsecret ./data/sepolia/jwtsecret

# windows
./build/bin/geth.exe console --sepolia --syncmode=snap --datadir ./data/sepolia --maxpeers 30 --cache 2048 --allow-insecure-unlock --gcmode archive --http --http.addr 0.0.0.0 --http.port 8545 --http.api admin,eth,net,web3,personal --http.corsdomain "*" --ws --ws.addr 0.0.0.0 --ws.port 8546 --ws.api admin,eth,net,web3,personal --ws.origins "*" --ipcdisable  --authrpc.addr 0.0.0.0 --authrpc.port 8551 --authrpc.jwtsecret ./data/sepolia/jwtsecret
```

参数解释：

- console: JavaScript控制台
- --sepolia: sepolia测试网络
- --datadir：数据库和密钥库的数据目录(默认:"~/.ethereum")
- --http.api：指定需要调用的HTTP-RPC API接口，默认只有eth,net,web3
- --http：启动HTTP-RPC服务（基于HTTP的）
- --http.addr：HTTP-RPC服务器监听地址(default: "localhost")
- --cache：分配给内部缓存的内存的兆字节 (默认值为: 1024)
- --maxpeers：最大的网络节点数量(如果设置为0，网络将被禁用)(默认值:50)
- --allow-insecure-unlock：允许使用不安全的账户解锁
- --authrpc.port：设置认证监听的api端口，默认为8551
- --authrpc.addr：允许连接认证监听api端口的IP地址
- --authrpc.vhosts：允许连接认证监听api端口的域名
- --authrpc.jwtsecret：设置身份验证的RPC接口的JWT私钥的路径

**注意：**

- 尽管一些内部保护措施可以防止交易在主网络和测试网络之间交叉，但您应始终使用单独的账户进行游戏和真钱交易。

## Docker 快速部署 sepolia

```shell
docker run -d \
--restart=always \
--name ethereum-node \
-v /usr/local/src/sepolia:/data/sepolia \
-p 8545:8545 \
-p 30303:30303 \
-p 8551:8551 \
ethereum/client-go
--datadir /data/sepolia \
--maxpeers 30 \
--cache 2048 \
--gcmode archive \
--http \
--http.addr 0.0.0.0 \
--http.port 8545 \
--http.api admin,eth,net,web3,personal \
--http.corsdomain "*" \
--ws \
--ws.addr 0.0.0.0 \
--ws.port 8546 \
--ws.api admin,eth,net,web3,personal \
--ws.origins "*" \
--ipcdisable  \
--allow-insecure-unlock \
--authrpc.addr 0.0.0.0 \
--authrpc.port 8551 \
--authrpc.jwtsecret /data/sepolia/jwtsecret
```

## 部署共识节点Prysm

`geth`在以太坊经过 POW ->  做POS 和转换之后, 共识层由独立的节点控制, `geth`只做为很轻的客户端节点使用

```shell
docker run -itd \
--restart=always  \
--name prysm \
-v /etc/localtime:/etc/localtime \
-v /etc/timezone:/etc/timezone \
-v /usr/local/src/prysm/data:/data \
-v /usr/local/src/prysm/jwtsecret:/opt/jwtsecret \
--network=host \
gcr.io/prysmaticlabs/prysm/beacon-chain:stable \
--sepolia \
-datadir=/data \
--jwt-secret=/opt/jwtsecret \
--rpc-host=0.0.0.0 \
--grpc-gateway-host=0.0.0.0 \
--monitoring-host=0.0.0.0 \
--execution-endpoint=http://192.168.0.102:8551 \
--checkpoint-sync-url=https://sepolia.beaconstate.info \
--genesis-beacon-api-url=https://sepolia.beaconstate.info/ \
--accept-terms-of-use=true  
```

参数说明：

- --datadir：数据库和密钥库的数据目录(默认:"~/.ethereum")
- --authrpc.jwtsecret：设置身份验证的RPC接口的JWT私钥的路径
- --rpc-host：允许连接RPC服务的主机(默认值:“127.0.0.1”)
- --grpc-gateway-host：允许连接网关的主机(默认值:“127.0.0.1”)
- --monitoring-host：用于监听和响应prometheus监控的主机(默认值:“127.0.0.1”)
- --execution-endpoint：连接执行客户端的http端点。格式为“http://localhost:8551”
- --checkpoint-sync-url：从最新的检查点开始同步, 而不是同步所有区块
- --genesis-beacon-api-url：获取区块信息的url
- --accept-terms-of-use：接受条款和条件(用于非交互环境)(默认值:false)

## 部署一个 POA 挖矿的 DEV 本地测试节点

这个节点可以用于测试环境, 此环境在本地允许, 自带一个无限 eth 的钱包用于测试, 测试数据都在本地允许:

```shell
# linux
./build/bin/geth console --dev --syncmode=snap --datadir ./data/dev --maxpeers 30 --cache 2048 --allow-insecure-unlock --gcmode archive --http --http.addr 0.0.0.0 --http.port 8545 --http.api admin,eth,net,web3,personal --http.corsdomain "*" --ws --ws.addr 0.0.0.0 --ws.port 8546 --ws.api admin,eth,net,web3,personal --ws.origins "*" --ipcdisable

# windows
./build/bin/geth.exe console --dev --syncmode=snap --datadir ./data/dev --maxpeers 30 --cache 2048 --allow-insecure-unlock --gcmode archive --http --http.addr 0.0.0.0 --http.port 8545 --http.api admin,eth,net,web3,personal --http.corsdomain "*" --ws --ws.addr 0.0.0.0 --ws.port 8546 --ws.api admin,eth,net,web3,personal --ws.origins "*" --ipcdisable
```

## 运营专用私有网络

维护自己的专用网络涉及更多，因为需要进行大量配置在官方授予的网络上需要手动设置。

首先，您需要创建网络的创世状态，所有节点都需要如此了解并同意。

它由一个小的 JSON 文件组成（例如，将其命名为`genesis.json`）：

```json
{
   "config": {
      "chainId": 1,
      "homesteadBlock": 0,
      "eip150Block": 0,
      "eip155Block": 0,
      "eip158Block": 0,
      "byzantiumBlock": 0,
      "constantinopleBlock": 0,
      "petersburgBlock": 0,
      "istanbulBlock": 0,
      "berlinBlock": 0,
      "londonBlock": 0
   },
   "alloc": {
      "0xf6960DdBF90799E746d3AaD737a15Ca6f86dfaE1": {
         "balance": "100000000000000000000"
      },
      "0x2a2345Bf69B13424403a790D32c7C72D91845621": {
         "balance": "100000000000000000000"
      }
   },
   "coinbase": "0x0000000000000000000000000000000000000000",
   "difficulty": "0x20000",
   "extraData": "",
   "gasLimit": "0x2fefd8",
   "nonce": "0x0000000000000042",
   "mixhash": "0x0000000000000000000000000000000000000000000000000000000000000000",
   "parentHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
   "timestamp": "0x00"
}
```

在上述 JSON 文件中定义了创世状态后，您需要在启动之前使用它初始化每个 `geth` 节点，以确保所有区块链参数都已正确设置：

```shell
# linux
./build/bin/geth console --datadir ./data/private/private01 init ./data/private/genesis.json 

# windos
./build/bin/geth.exe console --datadir ./data/private/private01 init ./data/private/genesis.json
```

#### 创建交汇点

在您想要运行的所有节点都初始化为所需的创世状态后，您需要启动一个 Bootstrap 节点，其他人可以使用该节点在您的网络中和/或上方找到彼此互联网。
干净的方法是配置并运行一个专用的 bootnode：

```shell
$ bootnode --genkey=boot.key
$ bootnode --nodekey=boot.key
```

引导节点联机时,
它将显示一个 [`enode` URL](https://ethereum.org/en/developers/docs/networking-layer/network-addresses/#enode)
其他节点可以用来连接到它并交换对等信息.
请务必替换显示的 IP 地址信息 (most probably `[::]`) 使用外部可访问的 IP 获取实际的 'enode' URL.

*注意：您也可以使用成熟的 'geth' 节点作为引导节点，但数量较少推荐方式.*

#### 启动您的成员节点

引导节点可操作且可从外部访问 (you can try `telnet <ip> <port>` to ensure it's indeed reachable),
通过 '--bootnodes' 标志启动指向 BootNode 的每个后续 'geth' 节点以进行对等发现.
可能还需要将专用网络的数据目录分开, 因此，也要指定自定义的 '--datadir' 标志.

```shell
geth --datadir=path/to/custom/data/folder --bootnodes=<bootnode-enode-url-from-above>
```

*注意：由于您的网络将与主网络和测试网络完全切断，因此您将还需要配置一个矿工来处理交易并为您创建新的区块.*

#### 经营私人矿机

在专用网络设置中，单个 CPU 矿工实例绰绰有余实际用途，因为它可以在正确的时间间隔产生稳定的块流无需大量资源

- （考虑在单个线程上运行，无需多个线程一个）。

要启动用于挖矿的 'geth' 实例，请使用所有常用的扩展标志运行它由：

```shell
$ geth <usual-flags> --mine --miner.threads=1 --miner.etherbase=0x0000000000000000000000000000000000000000
```

这将开始在单个 CPU 线程上挖掘块和事务, 记入所有对 '--miner.etherbase' 指定的账户进行处理.

您可以通过更改默认的 gas limit 块收敛来进一步调整采矿 (`--miner.targetgaslimit`)
价格交易在以下地被接受 (`--miner.gasprice`).