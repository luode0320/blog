### 你可以使用哪些RPC通过网络连接到geth客户端？

可以使用**JSON-RPC**和**WS-RPC**通过网络连接到geth客户端。 **IPC-RPC**只能连接到同一台机器上的geth客户端。

### 1. HTTP JSON-RPC

HTTP JSON-RPC 是最常用的连接方式之一，它允许通过 HTTP 协议发送 JSON 格式的请求和接收响应。这种方式适合 Web
应用程序和其他需要通过网络连接到 Geth 的场景。

#### 如何配置 Geth

```sh
geth --datadir /path/to/data/folder --rpc --rpc.addr "0.0.0.0" --rpc.port 8545
```

这里的参数说明：

- `--rpc`：启用 JSON-RPC 服务。
- `--rpc.addr`：指定 JSON-RPC 服务监听的 IP 地址，默认为 `localhost`。使用 `0.0.0.0` 表示监听所有 IP 地址。
- `--rpc.port`：指定 JSON-RPC 服务监听的端口，默认为 `8545`。

#### 使用 Web3.js 连接

```js
const Web3 = require('web3');
const web3 = new Web3('http://your.geth.node.ip:8545');

// 查询当前区块高度
web3.eth.getBlockNumber().then(console.log);
```

#### 使用 ethers.js 连接

```js
import { providers } from 'ethers';

const provider = new providers.JsonRpcProvider('http://your.geth.node.ip:8545');

// 查询当前区块高度
provider.getBlockNumber().then(console.log);
```

### 2. WebSocket JSON-RPC

WebSocket JSON-RPC 允许通过 WebSocket 协议发送 JSON 格式的请求和接收响应。这种方式适合需要实时通信的应用场景，如监听新区块、交易等。

#### 如何配置 Geth

```sh
geth --datadir /path/to/data/folder --ws --ws.addr "0.0.0.0" --ws.port 8546
```

这里的参数说明：

- `--ws`：启用 WebSocket 服务。
- `--ws.addr`：指定 WebSocket 服务监听的 IP 地址，默认为 `localhost`。使用 `0.0.0.0` 表示监听所有 IP 地址。
- `--ws.port`：指定 WebSocket 服务监听的端口，默认为 `8546`。

#### 使用 Web3.js 连接

```js
const Web3 = require('web3');
const web3 = new Web3(new Web3.providers.WebsocketProvider('ws://your.geth.node.ip:8546'));

// 订阅新区块
web3.eth.subscribe('newBlocks').on('data', block => {
  console.log(block);
});
```

#### 使用 ethers.js 连接

```js
import { providers } from 'ethers';

const provider = new providers.WebSocketProvider('ws://your.geth.node.ip:8546');

// 订阅新区块
provider.on('block', blockNumber => {
  console.log(`New block: ${blockNumber}`);
});
```

### 3. IPC-RPC（本地通信）

虽然 IPC-RPC 是用于本地进程间通信的方式，但如果两个进程位于同一台机器上，也可以通过 IPC-RPC 进行通信。这种方式不适合通过网络连接。

#### 使用 Web3.js 连接

```js
const Web3 = require('web3');
const web3 = new Web3(new Web3.providers.IpcProvider('/path/to/geth.ipc'));

// 查询当前区块高度
web3.eth.getBlockNumber().then(console.log);
```

