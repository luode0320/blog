# 简介

在 Go 语言中，happened-before 是一种用于描述事件顺序的概念，它来自于并发编程理论。

- 在并发环境中，多个事件（如变量赋值、锁的获取和释放等）可能发生在不同的线程或 goroutine 中。
- 由于现代计算机架构的复杂性，这些事件的实际执行顺序可能与程序的逻辑顺序不同，这是因为编译器优化或处理器乱序执行等原因造成的。
- 然而，即使在这种情况下，有些事件的执行顺序必须保持不变，以维护程序的正确性。这就是 happened-before 关系的作用。

大概的意思就是, 你写的代码必须保证执行顺序符合要求, 并且这是你保证的,

类似于一种你应该遵守的并发开发规则, 并不是说你不这样写代码就会报错。

# Happened-before 规则

在 Go 语言中，happened-before 规则保证了在并发环境下，事件的顺序至少符合程序的直观预期。

Go 语言的内存模型定义了以下 happened-before 关系：

1. **程序顺序规则**：程序中的事件按照它们出现的顺序发生。也就是说，如果事件 A 在事件 B 之前在源代码中出现，那么 A
   happened-before B。
2. **锁定规则**：一个成功的锁获取（lock）happened-before 后续的锁释放（unlock）。同样，一个锁释放 happened-before 后续在同一锁上的锁获取。
3. **volatile 变量规则**：对 volatile 变量的写操作 happened-before 后续对该变量的读操作。
4. **通道规则**：
    - 第 n 个 send 操作 happened-before 第 n 个 receive finished。
    - 对于有缓冲的通道，第 n 个 receive 操作 happened-before 第 n+缓冲区大小 个 send finished。
    - 对于无缓冲的通道，第 n 个 receive 操作 happened-before 第 n 个 send finished。
    - channel 的关闭操作 happened-before 接收方接收到关闭通知。

# 示例

下面是一个使用通道的简单示例，展示了 happened-before 规则：

```go
package main

import (
	"fmt"
	"sync"
)

func sender(ch chan int, wg *sync.WaitGroup) {
	defer wg.Done()
	for i := 0; i < 3; i++ {
		ch <- i // 发送数据到通道
		fmt.Printf("Sent: %d\n", i)
	}
	close(ch) // 关闭通道
}

func main() {
	ch := make(chan int) // 创建一个无缓冲的整型通道
	var wg sync.WaitGroup

	wg.Add(1)
	go sender(ch, &wg) // 在一个新的 goroutine 中发送数据

	for val := range ch {
		fmt.Printf("Received: %d\n", val) // 接收数据，直到通道关闭
	}

	wg.Wait() // 等待发送数据的 goroutine 完成
	fmt.Println("All done.")
}
```

运行结果:

```go
Sent: 0
Received: 0
Received: 1
Sent: 1    
Sent: 2    
Received: 2
All done. 
```

在这个示例中：

- 每个 `ch <- i` 写入操作 happened-before 对应的 `val := <-ch` 接收操作。
- `close(ch)` 操作 happened-before 接收方感知到通道关闭。

通过遵守这些 happened-before 规则，Go 程序能够保证在并发执行时的正确性，即使在多核处理器上运行，也能维持数据的完整性和一致性。