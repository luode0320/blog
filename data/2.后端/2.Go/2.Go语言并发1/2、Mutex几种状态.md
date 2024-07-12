# 简介

在 Go 语言中，`sync.Mutex` 的内部状态主要由 `sync.Mutex` 结构体内的 `state` 字段控制，这是一个 32 位的整型变量，用于标记互斥锁的不同状态。

`state` 字段的每一位或几位组合起来可以表示不同的状态标志。

以下是 `sync.Mutex` 的主要状态及其含义：

1. **Locked** (`mutexLocked`)：表示锁是否被锁定。当 `state` 的最低位为 1 时，表示锁被锁定；为 0 时，表示锁未锁定。
2. **Woken** (`mutexWoken`)：表示是否有 goroutine 被从阻塞状态唤醒，但尚未获取锁。这是通过 `state` 的第二低位（即第 2
   位）来表示的。
3. **Starving** (`mutexStarving`)：表示锁是否处于“饥饿”状态。当有 goroutine
   因为长时间无法获取锁而进入饥饿状态时，此标志会被设置。这是通过 `state` 的第三低位（即第 3 位）来表示的。
4. **Waiter**：表示有多少个 goroutine 正在等待锁。这不是通过 `state` 的某个特定位来表示，而是通过 `Mutex`
   结构体的 `waiters` 字段（在底层实现中）来跟踪。

# 示例

实际的 `sync.Mutex` 内部状态和操作是由 Go 的标准库内部处理的，用户通常无需直接操作这些状态：

```go
package main

import (
	"fmt"
	"sync"
	"time"
)

func main() {
	var mu sync.Mutex

	// 锁定 Mutex
	mu.Lock()
	fmt.Println("Mutex locked")

	// 在这里执行一些受保护的操作

	// 解锁 Mutex
	mu.Unlock()
	fmt.Println("Mutex unlocked")

	// 尝试在一个 goroutine 中锁定 Mutex
	go func() {
		mu.Lock()
		fmt.Println("Goroutine acquired lock")
		time.Sleep(1 * time.Second) // 模拟长时间运行的任务
		mu.Unlock()
	}()

	// 在主线程中尝试立即锁定 Mutex
	// 这将阻塞直到 goroutine 释放锁
	mu.Lock()
	fmt.Println("Main thread acquired lock")
	mu.Unlock()
}
```

运行结果:

```go
Mutex locked
Mutex unlocked           
Main thread acquired lock
```

在这个示例中

- `sync.Mutex` 在不同的时间点被锁定和解锁。
- 当 goroutine 尝试获取已经锁定的锁时，它将被阻塞，直到锁被释放。
- `sync.Mutex` 内部的状态会自动管理这些操作，包括在多个 goroutines 之间公平分配锁，以及处理饥饿状态，以防止某些 goroutines
  长时间无法获取锁。

这些状态的管理是内部实现的细节，对用户而言通常是透明的。



