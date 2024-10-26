## 项目源码

[https://github.com/luode0320/solidity-demo](https://github.com/luode0320/solidity-demo)

## 构造函数

构造函数（`constructor`）是一种特殊的函数，每个合约可以定义一个，并在部署合约的时候自动运行一次。

它可以用来初始化合约的一些参数，例如初始化合约的`owner`地址：

```solidity
address owner; // 定义owner变量

// 构造函数
constructor(address initialOwner) {
    owner = initialOwner; // 在部署合约的时候，将owner设置为传入的initialOwner地址
}
```

**注意**：构造函数在不同的Solidity版本中的语法并不一致，在Solidity 0.4.22之前，构造函数不使用 `constructor`

而是使用与合约名同名的函数作为构造函数，由于这种旧写法容易使开发者在书写时发生疏漏（例如合约名叫 `Parents`
，构造函数名写成 `parents`）

使得构造函数变成普通函数，引发漏洞，所以0.4.22版本及之后，采用了全新的 `constructor` 写法。

构造函数的旧写法代码示例：

```solidity
pragma solidity =0.4.21;
contract Parents {
    // 与合约名Parents同名的函数就是构造函数
    function Parents () public {
    }
}
```

## 修饰器

修饰器（`modifier`）是`Solidity`特有的语法，类似于面向对象编程中的装饰器（`decorator`）、AOP等，声明函数拥有的特性，并减少代码冗余。

它就像钢铁侠的智能盔甲，穿上它的函数会带有某些特定的行为。

![image-20240814021639934](../../../picture/nVwXsOVmrYu8rqvKKPMpg.jpg)

`modifier`的主要使用场景是运行函数前的检查，例如地址，变量，余额等。

我们来定义一个叫做onlyOwner的modifier：

```solidity
// 定义modifier
modifier onlyOwner {
   require(msg.sender == owner); // 检查调用者是否为owner地址
   _; // 如果是的话，继续运行函数主体；否则报错并revert交易
}
```

带有`onlyOwner`修饰符的函数只能被`owner`地址调用，比如下面这个例子：

```solidity
function changeOwner(address _newOwner) external onlyOwner{
   owner = _newOwner; // 只有owner地址运行这个函数，并改变owner
}
```

我们定义了一个`changeOwner`函数，运行它可以改变合约的`owner`，但是由于`onlyOwner`修饰符的存在，只有原先的`owner`
可以调用，别人调用就会报错。

这也是最常用的控制智能合约权限的方法。

### OpenZeppelin的Ownable标准实现

`OpenZeppelin`是一个维护`Solidity`标准化代码库的组织，他的`Ownable`
标准实现如下： [Ownable.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol)

## 完整代码

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract Owner {
    address public owner; // 定义owner变量

    // 构造函数
    constructor(address initialOwner) {
        owner = initialOwner; // 在部署合约的时候，将owner设置为传入的initialOwner地址
    }

    // 定义modifier
    modifier onlyOwner() {
        require(msg.sender == owner); // 检查调用者是否为owner地址
        _; // 如果是的话，继续运行函数主体；否则报错并revert交易
    }

    // 定义一个带onlyOwner修饰符的函数
    function changeOwner(address _newOwner) external onlyOwner {
        owner = _newOwner; // 只有owner地址运行这个函数，并改变owner
    }
}

```

## 部署调试合约

修改 `.env` 中

```
# 部署的合约名称
DEPLOY_CONTRACT_NAME=InsertionSort
```

编写调试逻辑 `scripts\deploy.ts`:

```ts
import { ethers } from "hardhat";
import dotenv from "dotenv";

// 加载环境变量
dotenv.config();

// 需要部署的合约名称
const contractName: string = process.env.DEPLOY_CONTRACT_NAME!;

// 调用合约方法
async function exec(contract: any) {
    // 获取合约所有者地址
    const currentOwner = await contract.owner();
    console.log("owner: 获取合约所有者地址:", currentOwner);

    console.log("只有owner地址运行这个函数,并改变owner...");
    // 新的所有者地址
    const newOwner = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
    // 使用 gasLimit 参数以避免 gas 估计问题
    await contract.changeOwner(newOwner, { gasLimit: 30000 });
    console.log("changeOwner: 新的所有者地址:", newOwner);
}

// 定义一个异步函数 main，用于部署合约。
async function main() {
    console.log("_________________________启动部署________________________________");
    const [deployer] = await ethers.getSigners();
    console.log("部署地址:", deployer.address);

    // 获取账户的余额
    const balance = await deployer.provider.getBalance(deployer.address);
    // 将余额转换为以太币 (ETH)
    console.log("账户余额 balance(wei):", balance.toString());
    const balanceInEther = ethers.formatEther(balance);
    console.log("账户余额 balance(eth):", balanceInEther);

    console.log("_________________________部署合约________________________________");
    // 获取合约工厂。
    const contractFactory = await ethers.getContractFactory(contractName);
    // 部署合约
    const contract = await contractFactory.deploy("0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266");
    //  等待部署完成
    await contract.waitForDeployment()
    console.log(`合约地址: ${contract.target}`);

    console.log("_________________________合约调用________________________________");
    await exec(contract);
}

// 执行 main 函数，并处理可能发生的错误。
main()
    .then(() => process.exit(0)) // 如果部署成功，则退出进程。
    .catch(error => {
        console.error(error); // 如果发生错误，则输出错误信息。
        process.exit(1); // 退出进程，并返回错误代码 1。
    });
```

运行结果:

```sh
$ yarn hardhat run scripts/deploy.ts 
yarn run v1.22.22
$ E:\solidity-demo\11.构造函数和modifier修饰器\node_modules\.bin\hardhat run scripts/deploy.ts
_________________________启动部署________________________________
部署地址: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
账户余额 balance(wei): 10000000000000000000000
账户余额 balance(eth): 10000.0
_________________________部署合约________________________________
合约地址: 0x5FbDB2315678afecb367f032d93F642f64180aa3
_________________________合约调用________________________________
owner: 获取合约所有者地址: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
只有owner地址运行这个函数,并改变owner...
changeOwner: 新的所有者地址: 0x5FbDB2315678afecb367f032d93F642f64180aa3
Done in 2.47s.
```

## 总结

这一讲，我们介绍了`Solidity`中的构造函数和修饰符，并写了一个控制合约权限的`Ownable`合约。