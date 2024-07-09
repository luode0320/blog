# 简介

在 Go 语言中，`defer` 语句用于安排函数延迟执行。

当你在一个函数中调用 `defer`，你实际上是将一个函数调用推入一个栈中，这个函数会在当前函数即将返回之前执行。

`defer` 的主要用途包括资源清理、日志记录以及在函数执行中添加恢复点以处理 panic。

`defer` 的执行顺序遵循“后进先出”（LIFO, Last In First Out）的原则。

- 这意味着最后一个被 `defer` 的函数将会首先执行
- 而第一个被 `defer` 的函数将会最后执行。
- 即使函数中发生了 `panic`，`defer` 的函数依然会被调用。

# 示例defer

```go
package main

import (
	"fmt"
)

func main() {
	fmt.Println("Start")

	defer fmt.Println("Deferred 1") // 第一个 defer
	defer fmt.Println("Deferred 2") // 第二个 defer
	defer fmt.Println("Deferred 3") // 第三个 defer

	fmt.Println("Middle")

	panic("An error occurred!") // 触发 panic
	fmt.Println("End")          // 这一行不会被执行
}
```

运行结果:

```go
Start
Middle
Deferred 3
Deferred 2
Deferred 1
panic: An error occurred!
```

可以看到，`defer` 的函数按照“后进先出”的顺序执行。

即使 `panic` 发生，`defer` 的函数依然按顺序执行直到所有 `defer` 的函数都被调用完毕，之后才抛出 `panic`。

# 示例recover

如果在 `defer` 函数中使用了 `recover`，并且在 `panic` 发生后调用了 `recover`，那么程序可以捕获 `panic`
并继续执行后续的 `defer` 函数。

例如：

```go
package main

import (
	"fmt"
)

func main() {
	fmt.Println("Start")

	defer func() {
		if r := recover(); r != nil {
			fmt.Println("Recovered in defer:", r)
		}
		fmt.Println("Deferred 1")
	}()

	defer fmt.Println("Deferred 2")

	fmt.Println("Middle")

	panic("出现错误!")
	fmt.Println("End") // 这一行不会被执行
}
```

运行结果:

```go
Start
Middle                       
Deferred 2                   
Recovered in defer: 出现错误!
Deferred 1 
```

在这个例子中，`recover` 成功捕获了 `panic`，并且 `defer` 的函数依然按照 LIFO 的顺序执行。