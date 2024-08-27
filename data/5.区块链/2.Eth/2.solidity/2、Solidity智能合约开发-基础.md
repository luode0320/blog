## 智能合约 与 Solidity 语言

智能合约是运行在链上的程序，合约开发者可以通过智能合约实现与链上资产/数据进行交互，用户可以通过自己的链上账户来调用合约，访问资产与数据。

因为区块链保留区块历史记录的链式结构、去中心化、不可篡改等特征，智能合约相比传统应用来说能更公正、透明。

然而，因为智能合约需要与链进行交互，部署、数据写入等操作都会消耗一定费用，数据存储与变更成本也比较高，因此在设计合约时需要着重考虑资源的消耗。

此外，常规智能合约一经部署就无法进行修改，因此，合约设计时也需要多考虑其安全性、可升级性与拓展性。

Solidity 是一门面向合约的、为实现智能合约而创建的高级编程语言，在 EVM 虚拟机上运行，语法整体类似于
Javascript，是目前最流行的智能合约语言，也是入门区块链与 Web3 所必须掌握的语言。

针对上述的一些合约编写的问题，Solidity 也都有相对完善的解决方案支持，后续会详细讲解。

## 开发/调试工具

与常规编程语言不同，Solidity 智能合约的开发往往无法直接通过一个 IDE 或本地环境进行方便的调试，而是需要与一个链上节点进行交互。

开发调试往往也不会直接与主网（即真实资产、数据与业务所在的链）进行交互，否则需要承担高额手续费。

目前开发调试主要有以下几种方式与框架：

1. [Remix IDE(推荐)](https://remix.ethereum.org/): 通过 Ethereum 官方提供的基于浏览器的 Remix **开发工具**进行调试
    - Remix 会提供完整的 IDE、编译工具、部署调试的测试节点环境、账户等，可以很方便地进行测试，这是我学习使用时用的最多的工具。
    - Remix 还可以通过 MetaMask 插件与测试网、主网进行直接交互，部分生产环境也会使用它进行编译部署。
2. [Hardhat(推荐)](https://github.com/NomicFoundation/hardhat): Hardhat 是另一个基于 Javascript 的**开发框架**
   ，提供了非常丰富的插件系统，适合开发复杂的合约项目。
3. [Truffle(不推荐)](https://github.com/trufflesuite/truffle): Truffle 是一个非常流行的 Javascript 的 Solidity 合约*
   *开发框架**，提供了完整的开发、测试、调试工具链，可以与本地或远程网络进行交互。
4. [Brownie(不推荐)](https://github.com/eth-brownie/brownie): Brownie 是一个基于 Python 的 Solidity 合约**开发框架**
   ，以简洁的 Python 语法为调试和测试提供了便捷的工具链。

除了开发框架外，更好地进行 Solidity 还需要熟悉一些工具：

1. [Remix IDE](https://remix.ethereum.org/): 对于语法提示等并不完善，因此，可以使用 VSCode
   配合 [Solidity](https://marketplace.visualstudio.com/items?itemName=juanblanco.solidity) 进行编写，有更好的体验。
2. [MetaMask(推荐)](https://metamask.io/): 一个常用的钱包应用，开发过程中可以通过浏览器插件与测试网、主网进行交互，方便开发者进行调试。
3. [Infura(推荐)](https://infura.io/)。Infura 是一个 IaaS（Infrastructure as a Service）产品，我们可以申请自己的 Ethereum
   节点，通过 Infura 提供的 API 进行交互，可以很方便地进行调试，也更接近生产环境。
4. [Ganache(不推荐)](https://trufflesuite.com/ganache/)。Ganache 是一个开源的虚拟本地节点，提供了一个虚拟链网络，可以通过各类
   Web3.js、Remix 或一些框架工具与之交互，适合有一定规模的项目进行本地调试与测试。
5. [OpenZeppelin](https://www.openzeppelin.com/)。OpenZeppelin 提供了非常多的合约开发库与应用，能兼顾安全、稳定的同时给予开发者更好的开发体验，降低合约开发成本。

## 合约编译/部署

Solidity 合约是以 `.sol` 为后缀的文件，无法直接执行，需要编译为 EVM（Ethereum Virtual Machine）可识别的字节码才能在链上运行。

![compile_solidity](../../../picture/compile_solidity.png)

编译完成后，由合约账户进行部署到链上，其他账户可通过钱包与合约进行交互，实现链上业务逻辑。

## 核心语法

经过上文，我们对 Solidity 的开发、调试与部署有了一定了解。接下来我们就具体学习一下 Solidity 的核心语法。

### 数据类型

与我们常见的编程语言类似，Solidity 有一些内置数据类型。

#### 基本数据类型

- `boolean`，布尔类型有 `true` 和 `false` 两种类型，可以通过 `bool public boo = true;` 来定义，默认值为 `false`
- `int`，整数类型，可以指定 `int8` 到 `int256`，默认为 `int256`，通过 `int public int = 0;` 来定义，默认值为 `0`
  ，还可以通过 `type(int).min` 和 `type(int).max` 来查看类型最小和最大值
- `uint`，非负整数类型，可以指定 `uint8`、`uint16`、`uint256`，默认为 `uint256`，通过 `uint8 public u8 = 1;`
  来定义，默认值为 `0`
- `address`，地址类型，可以通过 `address public addr = 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c;`
  来定义，默认值为 `0x0000000000000000000000000000000000000000`
- `bytes`，`byte[]` 的缩写，分为固定大小数组和可变数组，通过 `bytes1 a = 0xb5;` 来定义

还有一些相对复杂的数据类型，我们单独进行讲解。

#### Enum

`Enum` 是枚举类型，可以通过以下语法来定义

```typescript
enum Status {
    Unknown,
    Start,
    End,
    Pause
}
```

并通过以下语法来进行更新与初始化

```typescript

// 实例化枚举类型
Status public status;

// 更新枚举值
function pause() public {
    status = Status.Pause;
}

// 重置枚举值
function reset() public {
    delete status;
}
```

#### 数组

数组是一种存储同类元素的有序集合，通过 `uint[] public arr;` 来进行定义

- 在定义时可以预先指定数组大小，如 `uint[10] public myFixedSizeArr;`

- 需要注意的是，我们可以在内存中创建数组（关于 `memory` 与 `storage` 等差异后续会详细讲解），但是必须固定大小
    - 如 `uint[] memory a = new uint[](5);`。

数组类型有一些基本操作方法，如下：

```typescript
// 定义数组类型
uint[7] public arr;

// 添加数据
arr.push(7);

// 删除最后一个数据
arr.pop();

// 删除某个索引值数据
delete arr[1];

// 获取数组长度
uint len = arr.length;
```

#### mapping

`mapping` 是一种映射类型，使用 `mapping(keyType => valueType)` 来定义

- 其中键需要是内置类型，如 `bytes`、`string`或合约类型，而值可以是任何类型，如嵌套 `mapping` 类型。
- 需要注意的是，`mapping` 类型是不能被迭代遍历的，需要遍历则需要自行实现对应索引。

下面说明一下各类操作：

```typescript
// 定义嵌套 mapping 类型
mapping(string => mapping(string => string)) nestedMap;

// 设置值
nestedMap[id][key] = "0707";

// 读取值
string value = nestedMap[id][key];

// 删除值
delete nestedMap[id][key];
```

#### Struct

`struct` 是结构类型，对于复杂业务，我们经常需要定义自己的结构，将关联的数据组合起来，可以在合约内进行定义

```typescript
contract Struct {
    // 定义结构体
    struct Data {
    	string id;
    	string hash;
    }

    Data public data;

    // 添加数据
    function create(string calldata _id) public {
    	data = Data{id: _id, hash: "111222"};
    }

    // 更新数据
    function update(string _id) public {
    	// 查询数据
    	string id = data.id;

        // 更新
        data.hash = "222333"
    }
}
```

也可以单独文件定义所有需要的结构类型，由合约按需导入

```typescript
// 'StructDeclaration.sol'

struct Data {
	string id;
	string hash;
}
```

```typescript
// 'Struct.sol'

import "./StructDeclaration.sol" // 导入

contract Struct {
    // 引用Data
	Data public data;
}
```

### 变量/常量/`Immutable`

#### 变量

变量是 Solidity 中可改变值的一种数据结构，分为以下三种：

- `local` : 定义在方法中，而不会存储在链上

  ```typescript
  string var = "Hello";
  ```

- `state` : 定义在方法之外, 会存储在链上，写入值时会发送交易，而读取值则不会；

  ```typescript
  string public var;
  ```

- `global` : 提供了链信息的全局变量

    - 如当前区块时间戳变量，合约调用者地址变量

      ```typescript
      uint timestamp = block.timestamp;
      address sender = msg.sender;
      ```

变量可以通过不同关键字进行声明，表示不同的存储位置。

- `storage`: 会存储在链上
- `memory`: 在内存中，只有方法被调用的时候才存在
- `calldata`: 作为调用方法传入参数时存在

#### 常量

常量是一种不可以改变值的变量，使用常量可以节约 gas 费用

```typescript
string public constant MY_CONSTANT = "0707";
```

#### immutable

`immutable` 则是一种特殊的类型，它的值可以在 `constructor` 构造器中初始化，但不可以再次改变。

**灵活使用这几种类型可以有效节省 gas 费并保障数据安全。**

### 函数

在 Solidity 中，函数用来定义一些特定业务逻辑。

#### 权限声明

函数分为不同的可见性，用户不同的关键字进行声明：

- `public`: 任何合约都可调用
- `private`: 只有定义了该方法的合约内部可调用
- `internal`: 只有在继承合约可调用
- `external`: 只有其他合约和账户可调用

查询数据的合约函数也有不同的声明方式：

- `view`:  可以读取变量，但不能更改
- `pure`:  不可以读也不可以修改

#### 函数修饰符

`modifier` 函数修饰符可以在函数运行前/后被调用，主要用来进行权限控制、对输入参数进行校验以及防止重入攻击等。

这三种功能修饰符可以通过以下语法定义：

```typescript
// modifier: 修改器，用于在函数执行前或后添加额外的操作。
// onlyOwner: 这个修改器确保只有合约的所有者才能执行该函数。
modifier onlyOwner() {
    require(msg.sender == owner, "Not owner"); // 如果消息发送者不是合约所有者，则抛出错误信息"Not owner"
   _; // 执行被修饰的函数体
}

// validAddress: 这个修改器确保传入的地址参数是一个有效的地址。
modifier validAddress(address _addr) {
    require(_addr != address(0), "Not valid address"); // 如果传入的地址为零地址，则抛出错误信息"Not valid address"
    _; // 执行被修饰的函数体
}

// noReentrancy: 这个修改器防止重入攻击，即当一个函数正在执行时，不允许再次进入同一个函数。
modifier noReentrancy() {
    require(!locked, "No reentrancy"); // 如果已经锁定（表示另一个函数正在执行），则抛出错误信息"No reentrancy"
    locked = true; // 锁定状态，防止重入
    _; // 执行被修饰的函数体
    locked = false; // 解除锁定状态
}
```

使用函数修饰符则是需要在函数声明时添加对应修饰符，如：

```typescript
// 函数名称：changeOwner
// 参数：_newOwner - 新的合约所有者的地址
// 描述：这个函数允许合约所有者改变自己的地址。只有合约所有者才能调用此函数，并且新地址必须是有效地址。
function changeOwner(address _newOwner) public onlyOwner validAddress(_newOwner) {
    owner = _newOwner; // 将新的所有者地址赋给owner变量
}

// 函数名称：decrement
// 参数：i - 要减去的数值
// 描述：这个函数递减x的值，递归地减少i的值直到i等于1为止。为了防止重入攻击，这个函数使用了noReentrancy修改器。
function decrement(uint i) public noReentrancy {
    x -= i; // 减少x的值

    if (i > 1) { // 如果i大于1
        decrement(i - 1); // 递归调用decrement函数，将i减1作为参数传递
    }
}
```

#### 函数选择器

当函数被调用时，`calldata` 的前四个字节要指定以确认调用哪个函数，被称为函数选择器。

```typescript
// transfer(address,uint256): 调用addr合约的"transfer(address,uint256)"函数。
// 0xSomeAddress: 是需要转账的目标地址
// 123: 是要转移的数量。
addr.call(abi.encodeWithSignature("transfer(address,uint256)", 0xSomeAddress, 123))
```

上述代码 `abi.encodeWithSignature() `返回值的前四个字节就是函数选择器。

我们如果在执行前预先计算函数选择器的话可以节约一些 `gas` 费。

```typescript
// contract FunctionSelector:
// 这是一个名为FunctionSelector的智能合约，它提供了一个名为getSelector的外部纯函数。
contract FunctionSelector {
    // 函数名称：getSelector
    // 参数：_func - 字符串类型的函数名
    // 返回值：bytes4 - 函数选择器
    // 描述：这个函数接受一个字符串类型的函数名作为输入，然后通过keccak256哈希算法计算出其函数选择器并返回。
    function getSelector(string calldata _func) external pure returns (bytes4) {
        return bytes4(keccak256(bytes(_func))); // 使用keccak256哈希算法对函数名进行哈希处理，得到函数选择器
    }
}
```

### 条件/循环结构

#### 条件

Solidity 使用 `if`、`else if`、`else` 关键字来实现条件逻辑：

```typescript
if (x < 10) {
	return 0;
} else if (x < 20) {
	return 1;
} else {
	return 2;
}
```

也可以使用简写形式：

```typescript
x < 20 ? 1 : 2;
```

#### 循环

Solidity 使用 `for`、`while`、`do while` 关键字来实现循环逻辑，但是因为后两者容易达到 `gas limit` 边界值，所以基本上用`for`
就可以了。

```typescript
for (uint i = 0; i < 10; i++) {
	// 业务逻辑
}
```

```typescript
uint j;
while (j < 10) {
	j++;
}
```

### 合约

#### 构造器

Solidity 的 `constructor` 构造器可以在创建合约的时候执行，主要用来初始化

```typescript
constructor(string memory _name) {
	name = _name;
}
```

如果合约之间存在继承关系，`constructor` 也会按照继承顺序。

#### 接口

`Interface`，通过声明接口来进行合约交互，有以下要求：

- 不能实现任何方法
- 可以继承其他接口
- 所有方法都必须声明为 `external`(只有其他合约和账户可调用的类型)
- 不能声明构造方法
- 不能声明状态变量

接口用如下语法进行定义：

```typescript
pragma solidity ^0.8.0;

// 合约名称：Counter
// 描述：这是一个简单的计数器合约，它有一个公共的变量count，并且提供了一个外部函数increment来增加count的值。
contract Counter {
    uint public count; // 定义一个公共无符号整型变量count
    
    function increment() external { // 定义一个外部函数increment
        count += 1; // 每次调用此函数时，将count加一
    }
}

// 接口名称：ICounter
// 描述：这是Counter合约对应的接口定义，用于其他合约或账户调用Counter合约的方法。
interface ICounter {
    // external: 表示只有其他合约和账户可以调用这个函数
    // view: 表示这个函数只能读取变量，而不能修改变量

    // 函数名称：count
    // 描述：返回当前count的值
    function count() external view returns (uint); 

    // 函数名称：increment
    // 描述：增加count的值
    function increment() external;
}
```

调用则是通过

```typescript
// 定义智能合约
contract MyContract {
    // 定义一个外部函数incrementCounter，用于增加_counter所指向的计数器的值
    function incrementCounter(address _counter) external {
        // 使用ICounter接口来调用_counter地址上的increment方法
        // 注意这里假设_counter地址上部署了一个实现了ICounter接口的智能合约
        ICounter(_counter).increment(); 
    }

    // 定义一个外部只读函数getCount，用于获取_counter所指向的计数器的当前值
    function getCount(address _counter) external view returns (uint) {
        // 使用ICounter接口来调用_counter地址上的count方法，并返回结果
        // 同样地，这里假设_counter地址上部署了一个实现了ICounter接口的智能合约
        return ICounter(_counter).count(); 
    }
}
```

#### 继承

Solidity 合约支持继承，且可以同时继承多个，使用 `is` 关键字。

函数可以进行重写，需要被继承的合约方法需要声明为 `virtual`，重写方法需要使用 `override` 关键字。

```typescript
// 定义父合约 A
contract A {
    // 定义一个名为foo的公共纯函数，返回一个字符串内存变量
    // 纯函数意味着它们不与区块链的状态交互，因此不会消耗 gas
    // pure关键字表明不可以读也不可以修改
    // virtual关键字表明该函数可以被子类覆盖
    function foo() public pure virtual returns (string memory) {
        return "A"; // 返回字符串"A"
    }
}

// B 合约继承 A 合约并重写函数foo
contract B is A {
    // 重写父合约A中的foo函数
    // pure关键字表明不可以读也不可以修改
    // virtual关键字表明该函数可以被子类覆盖
    // override关键字表明重写方法
    function foo() public pure virtual override returns (string memory) {
        return "B"; // 返回字符串"B"
    }
}

// D 合约继承 B 和 C 合约，并重写了函数foo
contract D is B, C {
    // 重写B和C合约中的foo函数
    // pure关键字表明不可以读也不可以修改
    // override关键字表明重写方法
    function foo() public pure override(B, C) returns (string memory) {
        // 使用super关键字调用父类B的foo函数
        return super.foo(); // 返回父类B的foo函数的结果
    }
}
```

有几点需要注意的是，继承顺序会影响业务逻辑，`state` 状态变量是不可以被继承的。

如果子合约想调用父合约，除了直接调用外，还可以通过 `super` 关键字来调用，如下：

```typescript
contract B is A {
    // virtual关键字表明该函数可以被子类覆盖
    // override关键字表明重写方法
	function foo() public virtual override {
        // 直接调用
		A.foo();
	}

    // virtual关键字表明该函数可以被子类覆盖
    // override关键字表明重写方法
	function bar() public virtual override {
    	// 通过 super 关键字调用
		super.bar();
	}
}
```

#### 合约创建

Solidity 中可以从另一个合约中使用 `new` 关键字来创建另一个合约

```typescript
// 函数名称：create
// 参数：
// _owner - 新创建汽车的所有者地址
// _model - 新创建汽车的型号
// 描述：这个函数用于创建一个新的汽车实例，并将其添加到cars数组中。
function create(address _owner, string memory _model) public {
    // 创建一个新的Car合约实例，传入_owner和_model作为参数
    Car car = new Car(_owner, _model);

    // 将新创建的汽车实例添加到cars数组中
    cars.push(car);
}
```

而 `solidity 0.8.0` 后支持 `create2` 特性创建合约

```typescript
// 函数名称：create2
// 参数：
// _owner - 新创建汽车的所有者地址
// _model - 新创建汽车的型号
// _salt - 随机数种子，用于生成唯一的合约地址
// 描述：这个函数用于创建一个新的汽车实例，并将其添加到cars数组中。与create不同的是，它使用了随机数种子来生成唯一的合约地址。
function create2(address _owner, string memory _model, bytes32 _salt) public {
    // 使用随机数种子生成唯一的合约地址，然后创建一个新的Car合约实例，传入_owner和_model作为参数
    Car car = (new Car){salt: _salt}(_owner, _model);

    // 将新创建的汽车实例添加到cars数组中
    cars.push(car);
}
```

#### 导入合约/外部库

复杂业务中，我们往往需要多个合约之间进行配合，这时候可以使用 `import` 关键字来导入合约

- 分为本地导入 :

  ```typescript
  import "./Foo.sol";
  ```

- 与外部导入:

  ```typescript
  import "https://github.com/owner/repo/blob/branch/path/to/Contract.sol";
  ```

外部库和合约类似，但不能声明状态变量，也不能发送资产。

如果库的所有方法都是 `internal` (只有在继承合约可调用) 的话会被嵌入合约，如果非 `internal`，需要提前部署库并且链接起来。

```typescript
// 定义一个名为 SafeMath 的库，用于提供安全数学运算的函数
library SafeMath {
    // 定义一个名为 add 的内部纯函数，该函数接收两个无符号整数 x 和 y
    // internal关键字表明只有在继承合约可调用
    // pure关键字表明不可以读也不可以修改
    function add(uint x, uint y) internal pure returns (uint) {
        // 执行加法操作并将结果存储在变量 z 中
        uint z = x + y;

        // 检查加法是否导致溢出（即 z 是否小于 x）
        // 如果发生溢出，则会抛出异常，异常消息为 "uint overflow"
        require(z >= x, "uint overflow");

        // 如果没有发生溢出，则返回计算结果 z
        return z;
    }
}
```

```typescript
// 定义一个名为 TestSafeMath 的智能合约
contract TestSafeMath {
    // 使用 SafeMath 库提供的安全数学运算功能扩展 uint 类型
    using SafeMath for uint;
}
```

#### 事件

事件机制是合约中非常重要的一个设计。

事件允许将信息记录到区块链上，DApp 等应用可以通过监听事件数据来实现业务逻辑，存储成本很低。

以下是一个简单的日志抛出机制：

```typescript
// 定义事件
event Log(address indexed sender, string message);
event AnotherLog();

// 抛出事件
emit Log(msg.sender, "Hello World!"); // 发送一个包含发送者地址和消息内容的事件
emit Log(msg.sender, "Hello EVM!"); // 再次发送一个包含发送者地址和不同消息内容的事件
emit AnotherLog(); // 发送另一个不带参数的事件
```

定义事件时可以传入 `indexed` 属性，但最多三个，加了后可以对这个属性的参数进行过滤

```typescript
// 创建一个名为 transfer 的事件
var event = myContract.transfer({value: ["99","100","101"]});
```

### 错误处理

链上错误处理也是合约编写的重要环节。Solidity 可以通过以下几种方式抛出错误。

`require` 都是在执行前验证条件，不满足则抛出异常:

```typescript
function testRequire(uint _i) public pure {
	require(_i > 10, "Input must be greater than 10");
}
```

`revert` 用来标记错误与进行回滚:

```typescript
// 定义一个名为 testRevert 的公共纯函数，接受一个无符号整数参数 _i
function testRevert(uint _i) public pure {
    // 如果输入的_i小于等于10，则抛出错误并回滚交易
    if (_i <= 10) {
        revert("Input must be greater than 10"); // 错误消息为“输入必须大于10”
    }
}
```

`assert` 要求一定要满足条件:

```typescript
// 定义一个名为 testAssert 的公共只读函数
function testAssert() public view {
    // 使用 assert 关键字验证 num 变量的值是否为0
    // 如果 num 的值不是0，那么函数将立即终止，并且智能合约的状态不会改变。
    assert(num == 0);
}
```

注意，在 Solidity 中，当出现错误时会回滚交易中发生的所有状态改变，包括所有的资产，账户，合约等。

`try / catch` 也可以捕捉错误，但只能捕捉来自外部函数调用和合约创建的错误。

```typescript
// 定义两个事件：Log 和 LogBytes
event Log(string message);
event LogBytes(bytes data);

// 定义一个名为 tryCatchNewContract 的公共函数，接受一个地址参数 _owner
function tryCatchNewContract(address _owner) public {
    // 使用 try-catch 语句尝试创建一个新的 Foo 合约实例
    try new Foo(_owner) returns (Foo foo) {
        emit Log("Foo created"); // 如果成功创建，发出一个 Log 事件，消息为 "Foo created"
    } catch Error(string memory reason) {
        emit Log(reason); // 如果遇到错误，发出一个 Log 事件，消息为错误原因
    } catch (bytes memory reason) {
        emit LogBytes(reason); // 如果遇到未知错误，发出一个 LogBytes 事件，携带原始错误数据
    }
}
```

### `payable` 关键字接收 `ether`

我们可以通过声明 `payable` 关键字设置方法可从合约中接收 `ether`。

```typescript
// 定义一个名为 owner 的可支付地址变量，公开可见
address payable public owner;

// 构造函数，同时标记为可支付
constructor() payable {
    // 将构造函数的发起者设置为 owner 变量
    owner = payable(msg.sender);
}

// 定义一个名为 deposit 的公共可支付函数
function deposit() public payable {}
```

### 与 `Ether` 交互 [#](https://guide.pseudoyu.com/zh/docs/solidity/learn_solidity_from_scratch_basic/#与-ether-交互)

与 `Ether` 交互是智能合约的重要应用场景，主要分为发送和接收两部分，分别有不同的方法实现。

#### 发送

主要通过 `transfer`、`send` 与 `call` 方法实现，其中 `call` 优化了对重入攻击的防范，在实际应用场景中建议使用（但一般不用来调用其他函数）。

```typescript
// 定义一个名为 SendEther 的智能合约
contract SendEther {

  // 定义一个名为 sendViaCall 的公共可支付函数，接受一个可支付的目标地址参数_to
  // 当你调用 sendViaCall 函数并向其发送以太币时，这些以太币将被转移到 _to 参数指定的地址
  function sendViaCall(address payable _to) public payable {
  
      // 调用目标地址的call方法，并传入空字符串作为参数
      // value: msg.value 表示将当前交易的所有以太币都转给目标地址
      (bool sent, bytes memory data) = _to.call{value: msg.value}("");

      // 确保转账成功，否则抛出错误
      require(sent, "Failed to send Ether");
  }
}
```

而如果需要调用另一个函数，则一般使用 `delegatecall`。

```typescript
// 定义一个名为 B 的智能合约
contract B {
	// 定义一个名为 num 的公共无符号整数变量
	uint public num;

	// 定义一个名为 sender 的公共地址变量
	address public sender;

	// 定义一个名为 value 的公共无符号整数变量
	uint public value;

	// 定义一个名为 setVars 的公共可支付函数，接受一个无符号整数参数_num
	function setVars(uint _num) public payable {
		// 设置 num 变量的值为_num
		num = _num;

		// 设置 sender 变量的值为当前交易的发起者
		sender = msg.sender;

		// 设置 value 变量的值为当前交易的价值
		value = msg.value;
	}
}

// 定义一个名为 A 的智能合约
contract A {
	// 定义一个名为 num 的公共无符号整数变量
	uint public num;

	// 定义一个名为 sender 的公共地址变量
	address public sender;

	// 定义一个名为 value 的公共无符号整数变量
	uint public value;

	// 定义一个名为 setVars 的公共可支付函数，接受一个地址参数_contract和一个无符号整数参数_num
	function setVars(address _contract, uint _num) public payable {
		// 使用 delegatecall 调用另一个合约的方法，并将结果存储在(success, data)中
		(bool success, bytes memory data) = _contract.delegatecall(
			// 使用 abi.encodeWithSignature 函数编码方法签名和参数
			abi.encodeWithSignature("setVars(uint256)", _num)
		);
	}
}
```

#### 接收

接收 `Ether` 主要用两种:

```typescript
// external 只有其他合约和账户可调用
// payable 设置方法可从合约中接收 ether

// receive() 方法是一个特殊的外部可支付函数，仅在合约接收到以太币时触发。
// 如果没有其他函数匹配，receive() 方法会被自动调用。
// receive() 方法不能有任何参数，也不能返回任何值。
function receive() external payable {}

// fallback() 方法也是一个特殊的外部可支付函数，在以下两种情况下触发：
// 1. 当以太币被发送至合约但没有其他函数匹配时；
// 2. 当以太币被发送至合约并且 receive() 方法未实现时。
// fallback() 方法不能有任何参数，也不能返回任何值。
function () external payable {}
```

当一个不接受任何参数也不返回任何参数的函数、当 `Ether` 被发送至某个合约但 `receive()` 方法未实现或 `msg.data`
非空时，会调用 `fallback()` 方法。

```typescript
// 定义一个名为 ReceiveEther 的智能合约
contract ReceiveEther {

	// 当 msg.data 为空时，即没有任何额外的数据传递时
	// receive() 方法会被自动调用
	receive() external payable {}

    // 当 msg.data 非空时，即有额外的数据传递时
	// fallback() 方法会被自动调用
	fallback() external payable {}

	// 定义一个名为 getBalance 的公共视图函数，返回当前合约的余额
	function getBalance() public view returns (uint) {
		// 返回当前合约的余额
		return address(this).balance;
	}
}
```

### Gas 费

在 EVM 中执行交易需要耗费 gas 费

- `gas spent` 表示需要多少 gas 量
- `gas price` 为 gas 的单位价格
- `Ether` 和 `Wei` 是价格单位，1 ether == 1e18 wei

合约会对 Gas 进行限制

- `gas limit` : 由发起交易的用户设置，最多花多少 gas
- `block gas limit`: 由区块链网络决定，这个区块中最多允许多少 gas

我们在合约开发中要尤其考虑尽量节约 gas 费，有以下几个常用技巧：

1. 使用 `calldata` 来替换 `memory`
2. 将状态变量载入内存
3. 使用 `i++` 而不是 `++i`
4. 缓存数组元素

```typescript
// 定义一个名为 sumIfEvenAndLessThan99 的外部函数，接受一个无符号整数数组参数_nums
function sumIfEvenAndLessThan99(uint[] calldata nums) external {
	// 初始化一个名为_total 的局部变量，初始值为 total 变量的值
	uint _total = total;

	// 获取_nums 数组的长度
	uint len = nums.length;

	// 循环遍历_nums 数组中的每个元素
	for (uint i = 0; i < len; ++i) {
		// 获取当前循环迭代的元素
		uint num = nums[i];

		// 判断当前元素是否是偶数且小于99
		if (num % 2 == 0 && num < 99) {
			// 如果满足条件，则将其加到_total 上
			_total += num;
		}
	}

	// 更新 total 变量的值为_total
	total = _total;
}
```

这段代码展示了如何在一个智能合约中对一组数字进行筛选并求和。

![image-20240815235518928](../../picture/image-20240815235518928.png)

![image-20240815235601220](../../picture/image-20240815235601220.png)

![image-20240815235833525](../../picture/image-20240815235833525.png)

![image-20240816001445771](../../picture/image-20240816001445771.png)

## 总结

以上就是我们系列第一篇，Solidity 基础知识，后续文章会对其常见应用和实用编码技巧进行学习总结，欢迎大家持续关注。

## 示例

### BNB智能合约

```typescript
/**
 *Submitted for verification at Etherscan.io on 2017-07-06
*/

pragma solidity ^0.4.8;

/**
 * Math operations with safety checks
 */
contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}
contract BNB is SafeMath{
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
	address public owner;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
	mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);
	
	/* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint256 value);
	
	/* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function BNB(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
        ) {
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        totalSupply = initialSupply;                        // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
		owner = msg.sender;
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) {
        if (_to == 0x0) throw;                               // Prevent transfer to 0x0 address. Use burn() instead
		if (_value <= 0) throw; 
        if (balanceOf[msg.sender] < _value) throw;           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                     // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value)
        returns (bool success) {
		if (_value <= 0) throw; 
        allowance[msg.sender][_spender] = _value;
        return true;
    }
       

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (_to == 0x0) throw;                                // Prevent transfer to 0x0 address. Use burn() instead
		if (_value <= 0) throw; 
        if (balanceOf[_from] < _value) throw;                 // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  // Check for overflows
        if (_value > allowance[_from][msg.sender]) throw;     // Check allowance
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                           // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                             // Add the same to the recipient
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) returns (bool success) {
        if (balanceOf[msg.sender] < _value) throw;            // Check if the sender has enough
		if (_value <= 0) throw; 
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      // Subtract from the sender
        totalSupply = SafeMath.safeSub(totalSupply,_value);                                // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }
	
	function freeze(uint256 _value) returns (bool success) {
        if (balanceOf[msg.sender] < _value) throw;            // Check if the sender has enough
		if (_value <= 0) throw; 
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      // Subtract from the sender
        freezeOf[msg.sender] = SafeMath.safeAdd(freezeOf[msg.sender], _value);                                // Updates totalSupply
        Freeze(msg.sender, _value);
        return true;
    }
	
	function unfreeze(uint256 _value) returns (bool success) {
        if (freezeOf[msg.sender] < _value) throw;            // Check if the sender has enough
		if (_value <= 0) throw; 
        freezeOf[msg.sender] = SafeMath.safeSub(freezeOf[msg.sender], _value);                      // Subtract from the sender
		balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
        Unfreeze(msg.sender, _value);
        return true;
    }
	
	// transfer balance to owner
	function withdrawEther(uint256 amount) {
		if(msg.sender != owner)throw;
		owner.transfer(amount);
	}
	
	// can accept ether
	function() payable {
    }
}
```

### 区块链音乐版权管理DApp

[musical-manage-DApp](https://github.com/luode0320/musical-manage-DApp)

## 参考资料

> 1. [Solidity by Example](https://solidity-by-example.org/)
> 2. [Ethereum 區塊鏈！智能合約(Smart Contract)與分散式網頁應用(dApp)入門](http://gasolin.idv.tw/learndapp/)
> 3. [区块链入门指南](https://www.pseudoyu.com/blockchain-guide/)
> 4. [Uright - 区块链音乐版权管理ÐApp](https://github.com/pseudoyu/uright)