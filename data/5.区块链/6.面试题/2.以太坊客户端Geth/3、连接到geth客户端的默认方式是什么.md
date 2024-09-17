### 连接到geth客户端的默认方式是什么？

默认情况下启用IPC-RPC(本地通信)，其他RPC都被禁用。

连接到 Geth 客户端的默认方式**通常是通过其提供的 JSON-RPC 接口**。

JSON-RPC 是一种轻量级的远程过程调用（Remote Procedure Call, RPC）协议，它允许开发者通过 HTTP 或 WebSocket 与 Geth 节点进行交互。

### 默认连接方式

#### 1. 使用 JSON-RPC 通过 HTTP

Geth 默认提供了一个 JSON-RPC 服务器，可以通过 HTTP 协议访问。这是最常见的连接方式，通常用于 Web 应用程序和命令行工具。

##### 配置 Geth

确保 Geth 启动时启用了 JSON-RPC 服务：

```sh
geth --datadir /path/to/data/folder --rpc --rpcaddr "localhost" --rpcport "8545"
```

这里的参数说明：

- `--datadir`：指定数据目录，用于存储区块链数据、密钥等信息。
- `--rpc`：启用 JSON-RPC 服务器。
- `--rpcaddr`：指定 JSON-RPC 服务器的绑定地址，默认为 `localhost`。
- `--rpcport`：指定 JSON-RPC 服务器的端口，默认为 `8545`。

##### 使用 Web3.js 或 ethers.js 连接

使用 Web3.js 连接到 Geth 节点：

```js
const Web3 = require('web3');
const web3 = new Web3('http://localhost:8545');

// 查询当前区块高度
web3.eth.getBlockNumber().then(console.log);
```

使用 ethers.js 连接到 Geth 节点：

```js
import { providers } from 'ethers';

const provider = new providers.JsonRpcProvider('http://localhost:8545');

// 查询当前区块高度
provider.getBlockNumber().then(console.log);
```

#### 2. 使用 JSON-RPC 通过 WebSocket

Geth 还支持通过 WebSocket 协议连接 JSON-RPC 服务器。这种方式通常用于实时应用，如监听新区块、交易等。

##### 配置 Geth

确保 Geth 启动时启用了 WebSocket 服务：

```js
geth --datadir /path/to/data/folder --ws --wsaddr "localhost" --wsport "8546"
```

这里的参数说明：

- `--ws`：启用 WebSocket 服务器。
- `--wsaddr`：指定 WebSocket 服务器的绑定地址，默认为 `localhost`。
- `--wsport`：指定 WebSocket 服务器的端口，默认为 `8546`。

##### 使用 Web3.js 或 ethers.js 连接

使用 Web3.js 连接到 Geth 节点：

```js
const Web3 = require('web3');
const web3 = new Web3(new Web3.providers.WebsocketProvider('ws://localhost:8546'));

// 订阅新区块
web3.eth.subscribe('newBlocks').on('data', block => {
  console.log(block);
});
```

使用 ethers.js 连接到 Geth 节点：

```js
import { providers } from 'ethers';

const provider = new providers.WebSocketProvider('ws://localhost:8546');

// 订阅新区块
provider.on('block', blockNumber => {
  console.log(`New block: ${blockNumber}`);
});
```

### 默认端口

Geth 默认使用的端口如下：

- **HTTP JSON-RPC**：8545
- **WebSocket JSON-RPC**：8546

#### 3. 通过 IPC

IPC（Inter-Process Communication）是一种本地进程间通信方式，通常用于同一台机器上的进程间通信。这种方式比通过网络连接更快，但也限制了其适用范围。

##### 使用 Web3.js 连接

```js
const Web3 = require('web3');
const web3 = new Web3(new Web3.providers.IpcProvider('/path/to/geth.ipc'));

// 查询当前区块高度
web3.eth.getBlockNumber().then(console.log);
```

### IPC-RPC 和 JSON-RPC的区别

### JSON-RPC

#### 定义

JSON-RPC（JSON Remote Procedure Call）是一种轻量级的远程过程调用协议，它使用 JSON 数据格式来编码请求和响应。

#### 特点

1. **跨平台**：由于使用 JSON 格式，JSON-RPC 可以在任何支持 JSON 的平台上使用。
2. **协议简单**：请求和响应的结构相对简单，容易理解和实现。
3. **多种传输协议**：可以使用多种传输协议，如 HTTP、WebSocket 等。
4. **广泛支持**：很多开发工具和库都支持 JSON-RPC，如 Web3.js、ethers.js 等。

#### 使用场景

1. **Web 应用**：使用 HTTP 协议的 JSON-RPC 适合 Web 应用程序。
2. **实时应用**：使用 WebSocket 协议的 JSON-RPC 适合需要实时通信的应用。

#### 示例

使用 Web3.js 通过 HTTP 连接到 Geth 节点：

```js
const Web3 = require('web3');
const web3 = new Web3('http://localhost:8545');

// 查询当前区块高度
web3.eth.getBlockNumber().then(console.log);
```

使用 ethers.js 通过 HTTP 连接到 Geth 节点：

```js
import { providers } from 'ethers';

const provider = new providers.JsonRpcProvider('http://localhost:8545');

// 查询当前区块高度
provider.getBlockNumber().then(console.log);
```

### IPC-RPC

#### 定义

IPC-RPC（Inter-Process Communication Remote Procedure Call）是一种本地进程间通信协议，主要用于同一台机器上的进程间通信。

#### 特点

1. **本地通信**：IPC-RPC 通常用于同一台机器上的进程间通信，速度更快。
2. **低延迟**：由于通信发生在本地，所以通常比通过网络连接的 JSON-RPC 有更低的延迟。
3. **安全性**：通信数据不会暴露在网络中，更加安全。
4. **系统限制**：IPC-RPC 通常仅限于同一台机器上的进程间通信，跨平台支持较差。

#### 使用场景

1. **本地开发环境**：在本地开发环境中，使用 IPC-RPC 可以获得更快的响应速度。
2. **自动化脚本**：对于运行在同一台机器上的自动化脚本或工具，使用 IPC-RPC 更加高效。

#### 示例

使用 Web3.js 通过 IPC 连接到 Geth 节点：

```js
const Web3 = require('web3');
const web3 = new Web3(new Web3.providers.IpcProvider('/path/to/geth.ipc'));

// 查询当前区块高度
web3.eth.getBlockNumber().then(console.log);
```

