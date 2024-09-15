## 项目源码

[https://github.com/luode0320/solidity-demo](https://github.com/luode0320/solidity-demo)

## 继承

继承是面向对象编程很重要的组成部分，可以显著减少重复代码。如果把合约看作是对象的话，`Solidity`也是面向对象的编程，也支持继承。

我们介绍`Solidity`中的继承，包括简单继承，多重继承，以及修饰器（`Modifier`）和构造函数（`Constructor`）的继承。

## 规则

- `virtual`: 父合约中的函数，如果希望子合约重写，需要加上`virtual`关键字。
- `override`：子合约重写了父合约中的函数，需要加上`override`关键字。

**注意**：用`override`修饰`public`变量，会重写与变量同名的`getter`函数

```solidity
mapping(address => uint256) public override balanceOf;
```

## 简单继承

我们先写一个简单的爷爷合约`Yeye`，里面包含1个`Log`事件和3个`function`: `hip()`, `pop()`, `yeye()`，输出都是”Yeye”。

```solidity
contract Yeye {
    event Log(string msg);

    // 定义3个function: hip(), pop(), man()，Log值为Yeye。
    function hip() public virtual{
        emit Log("Yeye");
    }

    function pop() public virtual{
        emit Log("Yeye");
    }

    function yeye() public virtual {
        emit Log("Yeye");
    }
}
```

我们再定义一个爸爸合约`Baba`，让他继承`Yeye`爷爷合约，语法就是`contract Baba is Yeye`，非常直观。

在`Baba`爸爸合约里，我们重写一下`hip()`和`pop()`这两个函数，加上`override`关键字，并将他们的输出改为`”Baba”`；

并且加一个新的函数`baba`，输出也是`”Baba”`。

```solidity
contract Baba is Yeye{
    // 继承两个function: hip()和pop()，输出改为Baba。
    function hip() public virtual override{
        emit Log("Baba");
    }

    function pop() public virtual override{
        emit Log("Baba");
    }

    function baba() public virtual{
        emit Log("Baba");
    }
}
```

我们部署合约，可以看到`Baba`合约里有4个函数，其中`hip()`和`pop()`的输出被成功改写成`”Baba”`，而继承来的`yeye()`
的输出仍然是`”Yeye”`。

## 多重继承

`Solidity`的合约可以继承多个合约。规则：

1. 继承时要按辈分最高到最低的顺序排。
    - 比如我们写一个`Erzi`儿子合约，继承`Yeye`爷爷合约和`Baba`爸爸合约
    - 那么就要写成`contract Erzi is Yeye, Baba`，而不能写成`contract Erzi is Baba, Yeye`，不然就会报错。
2. 如果某一个函数在**多个继承的合约里都存在**，比如例子中的`hip()`和`pop()`，**在子合约里必须重写**，不然会报错。
3. **重写在多个**父合约中都重名的函数时，`override`关键字后面要加上所有父合约名字，例如`override(Yeye, Baba)`。

```solidity
contract Erzi is Yeye, Baba{
    // 继承两个function: hip()和pop()，输出值为Erzi。
    function hip() public virtual override(Yeye, Baba){
        emit Log("Erzi");
    }

    function pop() public virtual override(Yeye, Baba) {
        emit Log("Erzi");
    }
}
```

`Erzi`儿子合约里面重写了`hip()`和`pop()`两个函数，将输出改为`”Erzi”`，并且还分别从`Yeye`爷爷和`Baba`爸爸合约继承了`yeye()`
和`baba()`两个函数。

## 修饰器Modifier的继承

`Solidity`中的修饰器（`Modifier`）同样可以继承，用法与函数继承类似，在相应的地方加`virtual`和`override`关键字即可。

```solidity
contract Base1 {
    modifier exactDividedBy2And3(uint _a) virtual {
        require(_a % 2 == 0 && _a % 3 == 0);
        _;
    }
}

contract Identifier is Base1 {

    // 计算一个数分别被2除和被3除的值，但是传入的参数必须是2和3的倍数, 直接在代码中使用父合约中的`exactDividedBy2And3`修饰器
    function getExactDividedBy2And3(uint _dividend) public exactDividedBy2And3(_dividend) pure returns(uint, uint) {
        return getExactDividedBy2And3WithoutModifier(_dividend);
    }

    // 计算一个数分别被2除和被3除的值
    function getExactDividedBy2And3WithoutModifier(uint _dividend) public pure returns(uint, uint){
        uint div2 = _dividend / 2;
        uint div3 = _dividend / 3;
        return (div2, div3);
    }
}
```

`Identifier`合约可以直接在代码中使用父合约中的`exactDividedBy2And3`修饰器，也可以利用`override`关键字重写修饰器：

```solidity
modifier exactDividedBy2And3(uint _a) override {
    _;
    require(_a % 2 == 0 && _a % 3 == 0);
}
```

## 构造函数的继承

子合约有两种方法继承父合约的构造函数。举个简单的例子，父合约`A`里面有一个状态变量`a`，并由构造函数的参数来确定：

```solidity
// 构造函数的继承
abstract contract A {
    uint public a;

    constructor(uint _a) {
        a = _a;
    }
}
```

1. 在继承时声明父构造函数的参数，例如：`contract B is A(1)`
2. 在子合约的构造函数中声明构造函数的参数，例如：

```solidity
contract C is A {
    constructor(uint _c) A(_c) {}
}
```

## 调用父合约的函数

子合约有两种方式调用父合约的函数，直接调用和利用`super`关键字。

1. 直接调用：子合约可以直接用`父合约名.函数名()`的方式来调用父合约函数，例如`Yeye.pop()`

```solidity
function callParent() public{
    Yeye.pop();
}
```

2. `super`关键字：子合约可以利用`super.函数名()`来调用最近的父合约函数。`Solidity`继承关系按声明时从右到左的顺序是：

   `contract Erzi is Yeye, Baba`，那么`Baba`是最近的父合约，`super.pop()`将调用`Baba.pop()`而不是`Yeye.pop()`：

```solidity
function callParentSuper() public{
    // 将调用最近的父合约函数，Baba.pop()
    super.pop();
}
```

## 钻石继承

在面向对象编程中，钻石继承（菱形继承）指一个派生类同时有两个或两个以上的基类。

```
  God
 /  \
Adam Eve
 \  /
people
```

在多重+菱形继承链条上使用`super`关键字时，需要注意的是使用`super`会调用继承链条上的每一个合约的相关函数，而不是只调用最近的父合约。

我们先写一个合约`God`，再写`Adam`和`Eve`两个合约继承`God`合约，最后让创建合约`people`继承自`Adam`和`Eve`，每个合约都有`foo`
和`bar`两个函数。

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/* 继承树：
  God
 /  \
Adam Eve
 \  /
people
*/

contract God {
    event Log(string message);

    function foo() public virtual {
        emit Log("God.foo called");
    }

    function bar() public virtual {
        emit Log("God.bar called");
    }
}

contract Adam is God {
    function foo() public virtual override {
        emit Log("Adam.foo called");
        super.foo();
    }

    function bar() public virtual override {
        emit Log("Adam.bar called");
        super.bar();
    }
}

contract Eve is God {
    function foo() public virtual override {
        emit Log("Eve.foo called");
        super.foo();
    }

    function bar() public virtual override {
        emit Log("Eve.bar called");
        super.bar();
    }
}

contract people is Adam, Eve {
    function foo() public override(Adam, Eve) {
        super.foo();
    }

    function bar() public override(Adam, Eve) {
        super.bar();
    }
}
```

在这个例子中，调用合约`people`中的`super.bar()`会依次调用`Eve`、`Adam`，最后是`God`合约。

虽然`Eve`、`Adam`都是`God`的子合约，但整个过程中`God`合约只会被调用一次。原因是`Solidity`
借鉴了Python的方式，强制一个由基类构成的DAG（有向无环图）使其保证一个特定的顺序。

更多细节你可以查阅[Solidity的官方文档](https://solidity-cn.readthedocs.io/zh/develop/contracts.html?highlight=继承#index-16)。

## 完整代码

#### **Inheritance.sol**: 简单继承

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// 合约继承
contract Yeye {
    event Log(string msg);

    // 定义3个function: hip(), pop(), man()，Log值为Yeye。
    function hip() public virtual {
        emit Log("Yeye: hip()");
    }

    function pop() public virtual {
        emit Log("Yeye: pop()");
    }

    function yeye() public virtual {
        emit Log("Yeye: yeye()");
    }
}

contract Baba is Yeye {
    // 继承两个function: hip()和pop()，输出改为Baba。
    function hip() public virtual override {
        emit Log("Baba: hip()");
    }

    function pop() public virtual override {
        emit Log("Baba: pop()");
    }

    function baba() public virtual {
        emit Log("Baba: baba()");
    }
}

contract Erzi is Yeye, Baba {
    // 继承两个function: hip()和pop()，输出改为Erzi。
    function hip() public virtual override(Yeye, Baba) {
        emit Log("Erzi: hip()");
    }

    function pop() public virtual override(Yeye, Baba) {
        emit Log("Erzi: pop()");
    }

    function callParent() public {
        Yeye.pop();
    }

    function callParentSuper() public {
        super.pop();
    }
}

// 构造函数的继承
abstract contract A {
    uint public a;

    constructor(uint _a) {
        a = _a;
    }
}

// 1. 在继承时声明父构造函数的参数
contract B is A(1) {

}

// 2. 在子合约的构造函数中声明构造函数的参数
contract C is A {
    constructor(uint _c) A(_c * _c) {}
}

```

编写调试逻辑 `scripts\Inheritance.ts`:

```ts
import { ethers } from "hardhat";
import dotenv from "dotenv";

// 加载环境变量
dotenv.config();

// 需要部署的合约名称
const contractName: string = "Erzi";

// 调用合约方法
async function exec(contract: any) {
    // 定义事件监听器的回调函数, 事件触发是无序的
    const onLog = (msg: string) => {
        console.log(`Log event: ${msg}`);
    };

    // 设置事件监听器
    contract.on("Log", onLog);

    // 调用合约方法，触发事件. 事件触发是无序的
    await contract.hip(); // 触发 "Erzi" 事件
    await contract.pop(); // 触发 "Erzi" 事件
    await contract.yeye(); // 触发 "Yeye" 事件
    await contract.baba(); // 触发 "Baba" 事件
    await contract.callParent(); // 触发 "Yeye" 事件
    await contract.callParentSuper(); // 触发 "Yeye" 事件

    // 等待一段时间以确保事件被触发
    await new Promise(resolve => setTimeout(resolve, 5000));

    // 移除事件监听器
    contract.removeListener("Log", onLog);
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
$ yarn hardhat run scripts/Inheritance.ts 
yarn run v1.22.22
$ E:\solidity-demo\13.继承\node_modules\.bin\hardhat run scripts/Inheritance.ts
_________________________启动部署________________________________
部署地址: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
账户余额 balance(wei): 10000000000000000000000
账户余额 balance(eth): 10000.0
_________________________部署合约________________________________
合约地址: 0x5FbDB2315678afecb367f032d93F642f64180aa3
_________________________合约调用________________________________
Log event: Erzi: hip()
Log event: Erzi: pop()
Log event: Yeye: yeye()
Log event: Yeye: pop()
Log event: Baba: baba()
Log event: Baba: pop()
Done in 7.39s.
```

#### **ModifierInheritance.sol**: 修饰器继承

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract Base1 {
    modifier exactDividedBy2And3(uint _a) virtual {
        require(_a % 2 == 0 && _a % 3 == 0);
        _;
    }
}

contract Identifier is Base1 {

    //计算一个数分别被2除和被3除的值，但是传入的参数必须是2和3的倍数
    function getExactDividedBy2And3(uint _dividend) public exactDividedBy2And3(_dividend) pure returns(uint, uint) {
        return getExactDividedBy2And3WithoutModifier(_dividend);
    }

    //计算一个数分别被2除和被3除的值
    function getExactDividedBy2And3WithoutModifier(uint _dividend) public pure returns(uint, uint){
        uint div2 = _dividend / 2;
        uint div3 = _dividend / 3;
        return (div2, div3);
    }

    //重写Modifier: 不重写时，输入9调用getExactDividedBy2And3，会revert，因为无法通过检查
    //删掉下面三行注释重写Modifier，这时候输入9调用getExactDividedBy2And3， 会调用成功
    // modifier exactDividedBy2And3(uint _a) override {
    //     _;
    // }
}


```

编写调试逻辑 `scripts\ModifierInheritance.ts`:

```ts
import { ethers } from "hardhat";
import dotenv from "dotenv";

// 加载环境变量
dotenv.config();

// 需要部署的合约名称
const contractName: string = "Identifier";

// 调用合约方法
async function exec(contract: any) {
    // 测试合法情况
    console.log("调用 getExactDividedBy2And3(6):");
    try {
        const result = await contract.getExactDividedBy2And3(6);
        console.log(`getExactDividedBy2And3(6) 合法情况: (${result[0]}, ${result[1]})`);
    } catch (error: any) {
        console.error(`错误: ${error.message}`);
    }

    // 测试非法情况
    console.log("调用 getExactDividedBy2And3(9):");
    try {
        const result = await contract.getExactDividedBy2And3(9);
        console.log(`getExactDividedBy2And3(9) 非法情况: (${result[0]}, ${result[1]})`);
    } catch (error: any) {
        console.error(`错误: ${error.message}`);
    }

    // 测试不使用修饰符的情况
    console.log("调用 getExactDividedBy2And3WithoutModifier(9):");
    try {
        const result = await contract.getExactDividedBy2And3WithoutModifier(9);
        console.log(`getExactDividedBy2And3WithoutModifier(9) 不继承修饰符: (${result[0]}, ${result[1]})`);
    } catch (error: any) {
        console.error(`错误: ${error.message}`);
    }
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

1. 继承, 不重写

```sh
$ yarn hardhat run scripts/ModifierInheritance.ts 
yarn run v1.22.22
$ E:\solidity-demo\13.继承\node_modules\.bin\hardhat run scripts/ModifierInheritance.ts
_________________________启动部署________________________________
部署地址: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
账户余额 balance(wei): 10000000000000000000000
账户余额 balance(eth): 10000.0
_________________________部署合约________________________________
合约地址: 0x5FbDB2315678afecb367f032d93F642f64180aa3
_________________________合约调用________________________________
调用 getExactDividedBy2And3(6):
getExactDividedBy2And3(6) 合法情况: (3, 2)
调用 getExactDividedBy2And3(9):
错误: Transaction reverted without a reason string
调用 getExactDividedBy2And3WithoutModifier(9):
getExactDividedBy2And3WithoutModifier(9) 不继承修饰符: (4, 3)
Done in 2.46s.
```

2. 重写修饰符

```sh
$ yarn hardhat run scripts/ModifierInheritance.ts 
yarn run v1.22.22
$ E:\solidity-demo\13.继承\node_modules\.bin\hardhat run scripts/ModifierInheritance.ts
Compiled 1 Solidity file successfully (evm target: paris).
_________________________启动部署________________________________
部署地址: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
账户余额 balance(wei): 10000000000000000000000
账户余额 balance(eth): 10000.0
_________________________部署合约________________________________
合约地址: 0x5FbDB2315678afecb367f032d93F642f64180aa3
_________________________合约调用________________________________
调用 getExactDividedBy2And3(6):
getExactDividedBy2And3(6) 合法情况: (3, 2)
调用 getExactDividedBy2And3(9):
getExactDividedBy2And3(9) 非法情况: (4, 3)
调用 getExactDividedBy2And3WithoutModifier(9):
getExactDividedBy2And3WithoutModifier(9) 不继承修饰符: (4, 3)
Done in 2.85s.
```

#### **DiamondInheritance.sol**: 钻石继承

````solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/* 继承树：
  God
 /  \
Adam Eve
 \  /
people
*/

contract God {
    event Log(string message);

    function foo() public virtual {
        emit Log("God.foo called");
    }

    function bar() public virtual {
        emit Log("God.bar called");
    }
}

contract Adam is God {
    function foo() public virtual override {
        emit Log("Adam.foo called");
        super.foo();
    }

    function bar() public virtual override {
        emit Log("Adam.bar called");
        super.bar();
    }
}

contract Eve is God {
    function foo() public virtual override {
        emit Log("Eve.foo called");
        super.foo();
    }

    function bar() public virtual override {
        emit Log("Eve.bar called");
        super.bar();
    }
}

contract people is Adam, Eve {
    function foo() public override(Adam, Eve) {
        super.foo();
    }

    function bar() public override(Adam, Eve) {
        super.bar();
    }
}

````

编写调试逻辑 `scripts\DiamondInheritance.ts`:

```ts
import { ethers } from "hardhat";
import dotenv from "dotenv";

// 加载环境变量
dotenv.config();

// 需要部署的合约名称
const contractName: string = "people";

// 调用合约方法
async function exec(contract: any) {
    // 定义事件监听器的回调函数
    const onLog = (msg: string) => {
        console.log(`Log event: ${msg}`);
    };

    // 设置事件监听器
    contract.on("Log", onLog);

    // 调用合约方法，触发事件
    await contract.foo(); // 触发 "God.foo called", "Adam.foo called", "Eve.foo called"
    await contract.bar(); // 触发 "God.bar called", "Adam.bar called", "Eve.bar called"

    // 等待一段时间以确保事件被触发
    await new Promise(resolve => setTimeout(resolve, 5000));

    // 移除事件监听器
    contract.removeListener("Log", onLog);
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
$ yarn hardhat run scripts/DiamondInheritance.ts 
yarn run v1.22.22
$ E:\solidity-demo\13.继承\node_modules\.bin\hardhat run scripts/DiamondInheritance.ts
_________________________启动部署________________________________
部署地址: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
账户余额 balance(wei): 10000000000000000000000
账户余额 balance(eth): 10000.0
_________________________部署合约________________________________
合约地址: 0x5FbDB2315678afecb367f032d93F642f64180aa3
_________________________合约调用________________________________
Log event: Eve.foo called
Log event: Adam.foo called
Log event: God.foo called
Log event: Eve.bar called
Log event: Adam.bar called
Log event: God.bar called
Done in 7.37s.
```

## 总结

这一讲，我们介绍了`Solidity`继承的基本用法，包括简单继承，多重继承，修饰器和构造函数的继承、调用父合约中的函数，以及多重继承中的菱形继承问题。