# 简介

在 Go 语言中，`sync.Mutex` 的内部状态主要由 `sync.Mutex` 结构体内的 `state` 字段控制，这是一个 32 位的整型变量，用于标记互斥锁的不同状态。

`state` 字段的每一位或几位组合起来可以表示不同的状态标志。

# 主要状态

以下是 `sync.Mutex` 的主要状态及其含义：

1. **mutexLocked**：这个状态表示锁是否被锁定。当 `state` 的最低位为 1 时，表示锁被锁定；为 0 时，表示锁未锁定。
    - 这个状态用来确保同一时间只有一个 goroutine 能够持有锁，避免竞争条件的发生。
2. **mutexWoken** ：这个状态表示是否有 goroutine 由于被唤醒而尚未获取锁。这是通过 `state` 的第二低位（即第 2位）来表示的。
    - 这个状态帮助避免唤醒大量 goroutine 而它们竞争同一个锁的情况，减少竞争，提高效率。
3. **mutexStarving** ：这个状态用于表示锁是否处于“饥饿”状态。
    - 当有 goroutine 因为长时间无法获取锁而进入饥饿状态时，此标志会被设置。这是通过 `state` 的第三低位（即第 3 位）来表示的。
    - 通过标记饥饿状态，锁可以优先为处于饥饿状态的 goroutine 提供服务，以避免其长时间无法获取锁的情况。
4. **mutexWaiterShift**：这个状态表示当前有多少个 goroutine 正在等待获取锁。
    - 这不是通过 `state` 的某个特定位来表示，而是通过 `Mutex`结构体的 `waiters` 字段（在底层实现中）来跟踪。
    - 通过这个状态，可以了解有多少个 goroutine 正在竞争锁，帮助调度器做出合适的决策，如唤醒等待的 goroutine。
    - **严格来说, 只有3种状态, 这个不算状态**

```go
const (
	// 将 iota 左移 0 位，相当于 1，表示互斥锁被锁定
	mutexLocked = 1 << iota
	// 这个状态表示一个 Goroutine 已经被唤醒，可以继续执行
	mutexWoken
	//这个状态表示一个 Goroutine 处于饥饿状态，即在只读模式下被锁阻塞等待锁
	mutexStarving
	// 表示一个用来保存等待 Goroutine 数量的位数
	mutexWaiterShift = iota
)
```

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



