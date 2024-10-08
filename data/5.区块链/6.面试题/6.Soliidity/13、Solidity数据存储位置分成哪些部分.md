### Solidity数据存储位置分成哪些部分

Solidity 数据存储位置有三类：`storage`，`memory`和`calldata`。不同存储位置的`gas`成本不同。

- `storage`类型的数据存在链上，类似计算机的硬盘，消耗`gas`多；
- `memory`和`calldata`类型的临时存在内存里，消耗`gas`少。

### 区分:

1. `storage`：合约里的状态变量默认都是`storage`，存储在链上。

2. `memory`：函数里的参数和临时变量一般用`memory`，存储在内存中，不上链。尤其是**如果返回数据类型是变长**的情况下，必须加memory修饰

    - 例如：**string, bytes, array和自定义结构**

3. `calldata`：和`memory`类似，存储在内存中，不上链。与`memory`的不同点在于`calldata`变量不能修改（`immutable`），一般用于函数的参数。