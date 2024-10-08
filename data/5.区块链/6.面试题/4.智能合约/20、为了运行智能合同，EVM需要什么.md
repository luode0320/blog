### 为了运行智能合同，EVM需要什么

它需要**合约的字节码**，是通过编译Solidity等或更高级别的语言编写的合约来生成字节码。

### 1. **智能合约代码**

- **Solidity 字节码**：智能合约通常是用 Solidity、Vyper 等高级语言编写，然后编译成 EVM 可执行的字节码。
- **合约 ABI**：Application Binary Interface (ABI) 描述了智能合约的接口，包括函数签名、事件等信息，用于解析合约数据。

### 2. **Gas 机制**

- **Gas Limit**：用户在发送交易时需要指定一个 Gas Limit，即交易执行过程中允许消耗的最大 Gas 量。
- **Gas Price**：用户需要指定一个 Gas Price，即每单位 Gas 的价格，以激励验证者执行交易。
- **Gas 计数器**：EVM 在执行过程中会跟踪已消耗的 Gas 量，并在达到 Gas Limit 时停止执行。

### 3. **操作码（Opcode）**

- **预定义操作码**：EVM 支持一系列预定义的操作码，每个操作码对应一个特定的功能，如算术运算、内存操作、控制流等。
- **操作码表**：EVM 维护一个操作码表，用于查找和执行每个操作码对应的指令。

### 4. **内存模型**

- **堆栈（Stack）**：EVM 使用一个 256 位宽的堆栈来临时存储操作数。
- **内存（Memory）**：用于存储较大的临时数据结构。
- **存储（Storage）**：用于持久化存储数据，存储在每个账户的状态树中。

### 5. **账户状态**

- **账户**：每个账户都有一个独立的存储空间，用于保存账户余额、代码、存储数据等。
- **状态树**：每个区块都有一个状态树（State Trie），记录了所有账户的状态信息。

### 6. **交易数据**

- **交易**：每个交易包含调用智能合约所需的数据，如函数名称、参数等。
- **交易上下文**：每个交易都有一个上下文，包含发送者地址、Gas Limit、Gas Price 等信息。

### 7. **EVM 规范**

- **执行规则**：EVM 规定了智能合约执行的具体规则，如异常处理、错误码等。
- **一致性要求**：EVM 确保所有节点在执行智能合约时得到相同的结果，维持了网络的一致性。

### 8. **安全性机制**

- **沙箱环境**：EVM 提供了一个隔离的执行环境，确保智能合约不能访问到系统级别的资源。
- **资源限制**：通过 Gas 机制来限制智能合约执行的资源消耗，防止无限循环和其他可能导致资源耗尽的问题。

### 9. **网络支持**

- **节点间通信**：EVM 的执行结果需要在整个网络中传播，确保所有节点达成共识。
- **区块传播**：新区块被打包后，需要在网络中传播，其他节点会验证区块的有效性。

### 10. **工具支持**

- **编译器**：如 solc（Solidity 编译器），用于将高级语言编写的智能合约代码编译成 EVM 字节码。
- **开发框架**：如 Truffle、Hardhat 等，提供了开发智能合约的完整工具链。
- **测试工具**：如 Ganache，用于本地测试智能合约。