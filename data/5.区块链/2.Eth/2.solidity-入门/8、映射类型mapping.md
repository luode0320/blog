## 项目源码

[https://github.com/luode0320/solidity-demo](https://github.com/luode0320/solidity-demo)

## 映射Mapping

在映射中，人们可以通过键（`Key`）来查询对应的值（`Value`），比如：通过一个人的`id`来查询他的钱包地址。

声明映射的格式为`mapping(_KeyType => _ValueType)`，其中`_KeyType`和`_ValueType`分别是`Key`和`Value`的变量类型。

```solidity
mapping(uint => address) public idToAddress; // id映射到地址
mapping(address => address) public swapPair; // 币对的映射，地址到地址
```

## 映射的规则

- **规则1**：映射的`_KeyType`只能选择Solidity内置的值类型，比如`uint`，`address`等，不能用自定义的结构体。而`_ValueType`
  可以使用自定义的类型。

  ```solidity
  // 我们定义一个结构体 Struct
  struct Student{
      uint256 id;
      uint256 score; 
  }
  mapping(Student => uint) public testVar; // 用自定义的结构体会出错
  ```

- **规则2**：映射的存储位置必须是`storage`，因此可以用于合约的状态变量，函数中的`storage`
  变量和library函数的参数（见[例子](https://github.com/ethereum/solidity/issues/4635)）。不能用于`public`
  函数的参数或返回结果中，因为`mapping`记录的是一种关系 (key - value pair)。

- **规则3**：如果映射声明为`public`，那么Solidity会自动给你创建一个`getter`函数，可以通过`Key`来查询对应的`Value`。

- **规则4**：给映射新增的键值对的语法为`_Var[_Key] = _Value`，其中`_Var`是映射变量名，`_Key`和`_Value`对应新增的键值对。

  ```solidity
  function writeMap (uint _Key, address _Value) public{
      idToAddress[_Key] = _Value;
  }
  ```

## 映射的原理

- **原理1**: 映射不储存任何键（`Key`）的资讯，也没有length的资讯。
- **原理2**: 映射使用`keccak256(abi.encodePacked(key, slot))`当成offset存取value，其中`slot`是映射变量定义所在的插槽位置。
- **原理3**: 因为Ethereum会定义所有未使用的空间为0，所以未赋值（`Value`）的键（`Key`）初始值都是各个type的默认值，如uint的默认值是0。

## 映射（Mapping）始终存储在存储（Storage)

Solidity 中的映射（Mapping）确实是一种特殊的键值对数据结构，其键和值都持久化存储在存储（Storage）中。

映射不会存储在内存（Memory）中，而是始终持久化存储在存储（Storage）中

**映射（Mapping）的特点:**

1. **键值对结构**：
    - 映射是一种键值对数据结构，其中键（key）是唯一的，而值（value）可以是任意类型的数据。
2. **存储位置**：
    - 映射的键和值都存储在存储（Storage）中，而不是内存（Memory）中。这是因为映射需要持久化存储数据，并且需要在整个合约的生命周期内保持不变。
3. **只读特性**：
    - 映射不能直接在纯函数 (`pure`) 或视图函数 (`view`) 中使用，因为这些函数不允许修改存储中的数据。只有在非视图函数中才能修改映射中的数据。

**映射的限制:**

1. **键的类型**：

    - 映射的键只能是 `address` 或 `bytes32` 类型。这是因为 Solidity 需要将键哈希成一个固定大小的值。

2. **不可复制到内存**：

    - 你不能直接将映射复制到内存中，但如果需要在内存中处理映射中的数据，可以创建一个映射值的副本。

## 完整代码

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract Mapping {
    mapping(uint => address) public idToAddress; // id映射到地址
    mapping(address => address) public swapPair; // 币对的映射，地址到地址

    // 规则1. _KeyType不能是自定义的 下面这个例子会报错
    // 我们定义一个结构体 Struct
    // struct Student{
    //    uint256 id;
    //    uint256 score;
    //}
    // mapping(Struct => uint) public testVar;

    function writeMap(uint _Key, address _Value) public {
        idToAddress[_Key] = _Value;
    }
}
```

## 部署调试合约

修改 `.env` 中

```
# 部署的合约名称
DEPLOY_CONTRACT_NAME=Mapping
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
    await contract.writeMap(1, "0x5FbDB2315678afecb367f032d93F642f64180aa3");
    console.log("idToAddress(): id映射到地址:", await contract.idToAddress(1));
    console.log("idToAddress(): id映射到地址:", await contract.idToAddress(2));
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
    const contract = await contractFactory.deploy();
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
$ E:\solidity-demo\7.映射类型mapping\node_modules\.bin\hardhat run scripts/deploy.ts
_________________________启动部署________________________________
部署地址: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
账户余额 balance(wei): 10000000000000000000000
账户余额 balance(eth): 10000.0
_________________________部署合约________________________________
合约地址: 0x5FbDB2315678afecb367f032d93F642f64180aa3
_________________________合约调用________________________________
idToAddress(): id映射到地址: 0x5FbDB2315678afecb367f032d93F642f64180aa3
idToAddress(): id映射到地址: 0x0000000000000000000000000000000000000000
Done in 2.44s.
```

## 总结

这一讲，我们介绍了Solidity中哈希表——映射（`Mapping`
）的用法。至此，我们已经学习了所有常用变量种类，之后我们会学习控制流`if-else`，`while`等。