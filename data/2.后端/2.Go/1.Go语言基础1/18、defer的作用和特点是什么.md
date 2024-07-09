# 简介

`defer` 是 Go 语言中的一个关键字，用于安排函数在当前函数返回前执行。

# 作用

1. **资源清理**：通常用于在函数退出前释放资源，如关闭文件、解锁互斥锁、关闭数据库连接等。
2. **异常处理**：在函数中发生 panic 时，`defer` 的函数仍然会被调用，这对于清理资源和记录错误日志非常有用。
3. **流程控制**：可以在函数的开始处安排一些工作，在函数结束时自动执行，例如，开始时启动一个计时器，结束时记录经过的时间。

# 特点

1. **延迟调用**：`defer` 后跟的函数调用会被推迟到当前函数即将返回时执行。
2. **栈特性**：`defer` 函数的执行顺序遵循后进先出（LIFO）原则。这意味着最后被 `defer` 的函数将首先执行。
3. **作用域限制**：`defer` 的作用域仅限于它所在的函数内部。
4. **异常场景下的执行**：即使函数中发生 panic，`defer` 的函数调用仍然会被执行，这使得 `defer` 在资源清理方面非常可靠。
5. **参数计算**：在 `defer` 语句执行时，函数调用中的参数已经是定义 `defer` 时的状态，即使之后参数的值发生改变，`defer`
   调用的函数仍然使用定义时的值。

# 示例

```go
package main

import (
	"fmt"
	"os"
)

func main() {
	f, err := os.Open("example.txt")
	if err != nil {
		fmt.Println("错误打开文件:", err)
		return
	}
	defer f.Close() // 文件将在函数结束时被关闭

	// 进行文件读取等操作
	_, err = f.WriteString("Hello, world!")
	if err != nil {
		fmt.Println("错误写入文件:", err)
		return
	}

	fmt.Println("文件操作已完成.")
}
```

在这个例子中，无论文件操作是否成功，`f.Close()` 都会在函数返回前被调用，确保文件被正确关闭。

另一个示例展示了 `defer` 在 panic 情况下的行为：

```go
package main

import (
	"fmt"
	"log"
)

func main() {
	defer func() {
		if r := recover(); r != nil {
			log.Println("Recovered from panic:", r)
		}
	}()

	fmt.Println("启动操作.")
	panic("出了问题!")
	fmt.Println("无法到达此线路.")
}
```

运行结果:

```go
启动操作.
2024/07/09 23:06:02 Recovered from panic: 出了问题!
```

在这个例子中，即使函数中发生了 panic，`defer` 函数仍然会被调用，可以用来做恢复处理，如记录错误日志。