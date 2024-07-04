# 简介

Goroutine 是 Go 语言中的一种轻量级线程，它是 Go 并发模型的核心组件之一。

它是一种轻量级的线程，由 Go 运行时管理，而不是由操作系统直接调度。

Goroutine 允许你在 Go 程序中以非常低的开销创建和管理数千甚至数百万个并发执行的任务。

# Goroutine 的特点

## 轻量级

Goroutine 的创建和上下文切换成本远低于传统的操作系统线程。

- 这是因为 Goroutines 由 Go 运行时调度，而非操作系统。
- 这意味着在 Goroutine 之间的切换不需要像线程那样涉及内核态和用户态的切换，从而大大降低了切换的开销。

## 高效调度

Go 运行时负责调度 Goroutines 在多个 CPU 核心上运行，这使得 Goroutines 能够充分利用多核处理器的优势。

运行时会根据系统的负载和可用资源动态调整 Goroutine 的执行，确保高效率的并行执行。

## 并发模型

Goroutine 是 Go 并发模型的基础。

Go 采用“共享一切，通信通过通道”的并发模式，其中 Goroutine 通过通道（channel）相互通信，而不是共享内存。

这种模型减少了死锁和竞态条件的风险，使得并发编程更加安全和易于管理。

## 易于创建和管理

创建一个 Goroutine 非常简单，只需在函数调用前加上 `go` 关键字即可。

# Goroutine 的创建

Goroutine 可以通过在函数调用前加上 `go` 关键字来创建。例如：

```go
go myFunction()
```

这行代码将异步调用 `myFunction`，这意味着 `myFunction` 将在后台执行，而不会阻塞当前的执行流。

# 如何停止 Goroutine

由于 Goroutine 是由 Go 运行时管理的，你不能直接“杀死”或“取消”一个 Goroutine。

但是，你可以设计你的 Goroutine 使其能够响应外部的停止信号。

这通常通过使用 Go 语言中的通道（channels）来实现。

## 创建一个通道

创建一个通道，通常使用布尔类型，用于发送停止信号。

```go
done := make(chan bool)
```

## 在 Goroutine 中监听通道

在 Goroutine 内部，使用 `select` 语句监听通道。当接收到信号时，Goroutine 可以选择退出。

```go
go func() {
    for {
        select {
        case <-done:
            return
        default:
            // 执行常规任务
        }
    }
}()
```

## 发送停止信号

当你需要停止 Goroutine 时，向通道发送一个值。

```go
close(done)
```

## 完整示例

```go
package main

import (
	"fmt"
	"time"
)

func main() {
	done := make(chan bool)
    
	go func() {
		for {
			select {
			case <-done:
				fmt.Println("Goroutine stopped.")
				return
			default:
				fmt.Println("Working...")
				time.Sleep(1 * time.Second)
			}
		}
	}()

	// 让 Goroutine 运行一段时间...
	time.Sleep(5 * time.Second)
    
	// 发送停止信号
	close(done)
}
```

在这个例子中，Goroutine 会持续打印 "Working..."，直到主程序发送一个停止信号。当 `done` 通道被关闭时，Goroutine 将退出循环并结束。