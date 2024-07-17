# 简介

在 Go 语言中，`sync.RWMutex` 是一种读写锁，它允许多个读取者同时访问共享资源，但只允许一个写入者在任何时刻独占访问。

这种锁机制特别适用于读多写少的场景，因为在读操作中不需要互相阻塞，只有写操作会排他性地锁定资源。



# 实现原理

```go
// RWMutex 是一个读写互斥锁。它可以被任意数量的读者或单个写者持有。
// 锁定的状态可以通过读取或写入操作来改变。零值表示一个解锁状态的 RWMutex。
//
// RWMutex 在首次使用后不应复制。
type RWMutex struct {
	w         Mutex  // 写锁
	writerSem uint32 // 写者信号量, 用于等待完成的读者的信号
	readerSem uint32 // 读者信号量, 用于等待完成的写者的信号

	// 当前读者的数量
	// 当读者加锁时， readerCount  +1
	// 当读者解锁时， readerCount  -1
	// 1.当 readerCount 大于 0 时，表示有读者持有读锁。
	// 2.如果 readerCount 等于 0，则表示当前没有读者持有读锁,其他写者可以尝试获取写锁
	// 3.当 readerCount < 0 , 说明有写者在等待， 读者需要等待写者释放写锁
	readerCount atomic.Int32

	// 写者等待读锁的数量
	// 当写者尝试获取写锁，但当前有读者持有读锁时，写者会被阻塞，并且 readerWait 会增加。
	// 当读者释放读锁时，如果有写者在等待读锁，readerWait 会减少，并且可能唤醒等待的写者
	// 1.readerCount > 0：表示有读者持有读锁。
	// 2.readerCount == 0 且 readerWait > 0：表示没有读锁, 但是写者还在阻塞中, 可能正处理唤醒阶段。
	// 3.readerCount == 0 且 readerWait == 0：表示当前没有读者持有读锁，且没有写者在等待读锁。此时其他写者可以尝试获取写锁。
	readerWait atomic.Int32
}
```

`RWMutex` 的实现基于 `Mutex`，但它增加了额外的字段来追踪读写者的数量和状态。`RWMutex` 包含以下主要字段：

- `w Mutex`：用于互斥地保护写入者，同时也用于保护读写锁的内部状态。
- `writerSem uint32`：写者信号量, 用于等待完成的读者的信号。
- `readerSem uint32`：读者信号量, 用于等待完成的写者的信号。
- `readerCount int32`：表示当前有多少读取者持有锁。
- `writerWaiting int32`：表示写入者正在等待多少读锁释放。



# RWMutex 的方法

`RWMutex` 提供了以下方法：

- `Lock()`：写入者调用此方法来获取写锁。如果已经有写入者或读取者持有锁，调用者将阻塞，直到锁可用。
- `Unlock()`：写入者调用此方法来释放写锁。
- `RLock()`：读取者调用此方法来获取读锁。读取者可以同时获取多个读锁，因为读操作不会互相阻塞。
- `RUnlock()`：读取者调用此方法来释放读锁。必须调用与 `RLock()` 相同次数的 `RUnlock()` 方法来完全释放读锁。



# 示例

```go
package main

import (
	"fmt"
	"sync"
	"time"
)

func main() {
	var rw sync.RWMutex
	data := "初始 data"

	// 启动一个 goroutine 作为读取者
	go func() {
		rw.RLock()
		fmt.Println("读1:", data)
		time.Sleep(1 * time.Second)
		fmt.Println("释放读1锁")
		rw.RUnlock()
	}()

	// 启动一个 goroutine 作为读取者
	go func() {
		rw.RLock()
		fmt.Println("读2:", data)
		time.Sleep(1 * time.Second)
		fmt.Println("释放读2锁")
		rw.RUnlock()
	}()

	// 启动一个 goroutine 作为读取者
	go func() {
		// 延迟操作, 使得这个读锁, 慢于加写锁的流程
		time.Sleep(500 * time.Millisecond)
		rw.RLock()
		fmt.Println("读3:", data)
		time.Sleep(1 * time.Second)
		fmt.Println("释放读3锁")
		rw.RUnlock()
	}()

	// 启动另一个 goroutine 作为写入者
	go func() {
		rw.Lock()
		data = "已更新 data"
		fmt.Println("写:", data)
		rw.Unlock()
	}()

	// 等待所有 goroutines 完成
	time.Sleep(3 * time.Second)
}

```

运行结果:

```go
读1: 初始 data
读2: 初始 data
释放读2锁
释放读1锁       
写: 已更新 data 
读3: 已更新 data
释放读3锁
```

1. 主函数中创建了一个 `sync.RWMutex` 类型的读写锁 `rw` 和一个字符串变量 `data`，并初始化为 "初始 data"。
2. 启动三个读取者 goroutine，它们分别获取读锁后打印当前的 `data` 值，然后睡眠 1 秒钟后释放读锁。这些读取者之间的启动顺序可能不同。
3. 启动一个写入者 goroutine，该 goroutine获取写锁后将 `data` 更新为 "已更新 data"，然后打印更新后的 `data` 值，最后释放写锁。
4. 由于写入者和第三个读取者之间存在一定的时间间隔，第三个读取者在获取读锁之前会延迟 500 毫秒，以确保在此之前写入者已经获取并释放写锁。
5. 主函数中等待所有的 goroutine 执行完毕，总共睡眠 3 秒钟，确保所有的读写操作都有足够的时间完成。



通过以上步骤展示了多个 goroutine 中对同一个数据进行并发读写的情况

**读取者可以同时持有读锁，但只有在没有其他 goroutine 持有写锁时，写入者才能获取写锁**



