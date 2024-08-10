# 简介

在 Go 语言中，Channel 是一种用于 goroutine 间通信的机制。

- 它允许 goroutines 通过 `send` 和 `receive` 操作相互通信和同步。

- Channel 是并发原语，用于在并发运行的 goroutines 之间传递数据。

# 特性：

- Channel 是类型化的，意味着每个 Channel 只能发送特定类型的值。
- Channel 可以是有缓冲的或无缓冲的。
- 无缓冲 Channel 在发送或接收操作时会阻塞，直到有另一个 goroutine 准备接收或发送。
- 有缓冲 Channel 可以存储一定数量的值而不阻塞。

# 例子

```go
package main

import "fmt"

func main() {
    ch := make(chan int) // 创建一个无缓冲的整型 Channel

    go func() {          // 启动一个 goroutine
        ch <- 42         // 向 Channel 发送值
    }()

    value := <-ch       // 从 Channel 接收值
    fmt.Println(value)  // 输出: 42
}
```

