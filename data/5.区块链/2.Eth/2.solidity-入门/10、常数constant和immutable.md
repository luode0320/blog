## 项目源码

[https://github.com/luode0320/solidity-demo](https://github.com/luode0320/solidity-demo)

## constant和immutable

介绍Solidity中和常量相关的两个关键字，`constant`（常量）和`immutable`（不变量）。

状态变量声明这两个关键字之后，不能在初始化后更改数值。这样做的好处是提升合约的安全性并节省`gas`。

另外，只有数值变量可以声明`constant`和`immutable`；`string`和`bytes`可以声明为`constant`，但不能为`immutable`。

### constant

`constant`变量必须在声明的时候初始化，之后再也不能改变。尝试改变的话，编译不通过。

```solidity
// constant变量必须在声明的时候初始化，之后不能改变
uint256 constant CONSTANT_NUM = 10;
string constant CONSTANT_STRING = "0xAA";
bytes constant CONSTANT_BYTES = "WTF";
address constant CONSTANT_ADDRESS = 0x0000000000000000000000000000000000000000;
```

### immutable

`immutable`变量可以在声明时或构造函数中初始化，因此更加灵活。

在`Solidity v8.0.21`以后，`immutable`变量不需要显式初始化。反之，则需要显式初始化。

若`immutable`变量既在声明时初始化，又在constructor中初始化，会使用constructor初始化的值。

```solidity
// immutable 变量可以在 constructor 里初始化，之后不能改变
uint256 public immutable IMMUTABLE_NUM = 9999999999;
address public immutable IMMUTABLE_ADDRESS;
uint256 public immutable IMMUTABLE_BLOCK;
uint256 public immutable IMMUTABLE_TEST;
```

你可以使用全局变量例如`address(this)`，`block.number` 或者自定义的函数给`immutable`变量初始化。

在下面这个例子，我们利用了`test()`函数给`IMMUTABLE_TEST`初始化为`9`：

```solidity
// 利用constructor初始化immutable变量，因此可以利用
constructor(){
    IMMUTABLE_ADDRESS = address(this);
    IMMUTABLE_NUM = 1118;
    IMMUTABLE_TEST = test();
}

function test() public pure returns(uint256){
    uint256 what = 9;
    return(what);
}
```

## 完整代码

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract Constant {
    // constant变量必须在声明的时候初始化，之后不能改变
    uint256 public constant CONSTANT_NUM = 10;
    string public constant CONSTANT_STRING = "0xAA";
    bytes public constant CONSTANT_BYTES = "WTF";
    address public constant CONSTANT_ADDRESS =
        0x0000000000000000000000000000000000000000;

    // immutable变量可以在constructor里初始化，之后不能改变
    uint256 public immutable IMMUTABLE_NUM = 9999999999;
    address public immutable IMMUTABLE_ADDRESS;
    uint256 public immutable IMMUTABLE_BLOCK;
    uint256 public immutable IMMUTABLE_TEST;

    // 利用constructor初始化immutable变量，因此可以利用
    constructor() {
        IMMUTABLE_ADDRESS = address(this);
        IMMUTABLE_NUM = 1118;
        IMMUTABLE_TEST = test();
    }

    function test() public pure returns (uint256) {
        uint256 what = 9;
        return (what);
    }
}

```

## 部署调试合约

修改 `.env` 中

```
# 部署的合约名称
DEPLOY_CONTRACT_NAME=Constant
```

编写调试逻辑 `scripts\deploy.ts`:

```ts
$ yarn hardhat run scripts/deploy.ts 
yarn run v1.22.22
$ E:\solidity-demo\9.常数constant和immutable\node_modules\.bin\hardhat run scripts/deploy.ts
Compiled 1 Solidity file successfully (evm target: paris).
_________________________启动部署________________________________
部署地址: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
账户余额 balance(wei): 10000000000000000000000
账户余额 balance(eth): 10000.0
_________________________部署合约________________________________
合约地址: 0x5FbDB2315678afecb367f032d93F642f64180aa3
_________________________合约调用________________________________
CONSTANT_NUM 默认值: 10n
CONSTANT_STRING 默认值: 0xAA
CONSTANT_BYTES 默认值: 0x575446
CONSTANT_ADDRESS 默认值: 0x0000000000000000000000000000000000000000
IMMUTABLE_NUM 默认值: 1118n
IMMUTABLE_ADDRESS 默认值 默认值: 0x5FbDB2315678afecb367f032d93F642f64180aa3
IMMUTABLE_BLOCK 默认值: 0n
IMMUTABLE_TEST 默认值: 9n
Done in 3.08s.
```

## 总结

这一讲，我们介绍了Solidity中两个关键字，`constant`（常量）和`immutable`（不变量），让不应该变的变量保持不变。

这样的做法能在节省`gas`的同时提升合约的安全性。