#### 这样发送1个以太对吗：.send({value:1})

不对，这样发送的是1 wei。 交易中总是以wei为单位。

使用 `.send()` 方法来转移以太币（ETH）时，确实可以通过设置 `value` 属性来指定要转移的数量。

然而，传递给 `value` 的值应该是**以 Wei 为单位的大数值（BigNumber）**，而不是直接传递一个数字或字符串。

这是因为以太坊中的最小单位是 Wei，1 ETH = 10^18 Wei。

### 示例代码

假设你想通过智能合约转移 1 ETH，正确的做法如下：

1. **将 1 ETH 转换为 Wei**：由于 1 ETH = 10^18 Wei，你需要将 1 ETH 转换成 Wei。
2. **使用 BigNumber 或 web3.utils 方法**：确保 `value` 是一个有效的 Wei 数值。

#### 示例代码：

```js
const web3 = new Web3(window.ethereum);

// 获取合约实例
const contractInstance = new web3.eth.Contract(abi, contractAddress);

// 设置转移的数量（1 ETH）
const valueInWei = web3.utils.toWei('1', 'ether'); // 将 1 ETH 转换成 Wei

// 设置交易选项
const options = {
  from: '0xabc123...', // 发送者的地址
  value: valueInWei // 转移的数量
};

// 调用合约的 transfer 方法并发送交易
contractInstance.methods.transfer('0x1234567890...', 100)
  .send(options)
  .then(txReceipt => {
    console.log(`Transaction receipt: ${txReceipt.transactionHash}`);
  })
  .catch(error => {
    console.error('Error sending transaction:', error);
  });
```

### 解释

1. `web3.utils.toWei`：将 1 ETH 转换成 Wei。`toWei` 方法接受两个参数：一个是数值，另一个是单位（如 `'ether'`）。
2. `options` 对象：包含交易的元数据，如发送者的地址和转移的数量。
3. `contractInstance.methods.transfer(...)`：调用合约的 `transfer` 方法。
4. `.send(options)`：发送交易，并等待交易确认。

### 更完整的示例

为了使示例更完整，这里提供一个更详细的示例代码，包括连接到 MetaMask 并请求用户授权：

```js
import Web3 from 'web3';

const web3 = new Web3(window.ethereum);

// 检查是否有注入式的 Web3 提供器（如 MetaMask）
if (window.ethereum) {
  try {
    // 请求用户授权
    await window.ethereum.enable();
  } catch (error) {
    console.error('User denied account access...', error);
  }
} else {
  console.error('No Ethereum browser detected. You should consider trying MetaMask!');
}

// 获取合约实例
const contractInstance = new web3.eth.Contract(abi, contractAddress);

async function transferEth() {
  try {
    // 获取用户授权的账户
    const accounts = await web3.eth.getAccounts();
    const senderAccount = accounts[0];

    // 设置转移的数量（1 ETH）
    const valueInWei = web3.utils.toWei('1', 'ether'); // 将 1 ETH 转换成 Wei

    // 设置交易选项
    const options = {
      from: senderAccount, // 发送者的地址
      value: valueInWei // 转移的数量
    };

    // 调用合约的 transfer 方法并发送交易
    const txReceipt = await contractInstance.methods.transfer('0x1234567890...', 100)
      .send(options);

    console.log(`Transaction receipt: ${txReceipt.transactionHash}`);
  } catch (error) {
    console.error('Error sending transaction:', error);
  }
}

transferEth();
```

### 总结

使用 `.send()` 方法来转移以太币时，需要确保 `value` 属性是以 Wei 为单位的大数值。

使用 `web3.utils.toWei` 方法可以方便地将以太币转换成 Wei。

通过这种方式，你可以确保交易中的数值是正确的，并且交易可以成功执行。