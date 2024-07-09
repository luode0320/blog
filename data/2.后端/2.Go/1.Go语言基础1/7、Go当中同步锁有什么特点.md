# 简介

在 Go 语言中，同步锁主要用于控制多个 goroutine 访问共享资源的顺序，以防止数据竞争和不一致状态。

Go 提供了两种主要的锁类型：`sync.Mutex` 和 `sync.RWMutex`

# `sync.Mutex`（互斥锁）

- **互斥性**：当一个 goroutine 持有 `Mutex` 锁时，其他试图获取该锁的 goroutine 将被阻塞，直到锁被释放。这意味着在任何时刻只有一个
  goroutine 能够访问被保护的资源。
- **原子操作**：`Mutex` 提供了 `Lock` 和 `Unlock` 方法，这两个操作是原子的，即它们要么全部成功要么全部失败，不会被其他
  goroutine 中断。
- **不可重入**: `Mutex` 是不可重入锁, 只能加锁一次, 不可对相同的锁重复加锁。
- **预防死锁**：Go 的 `Mutex` 实现了锁所有权检查，如果一个已经持有锁的 goroutine 尝试再次获取同一把锁，将会 panic，这有助于预防死锁。

```go
package main

import (
    "fmt"
    "sync"
    "time"
)

var counter int
var mutex sync.Mutex // 定义互斥锁

// 加锁累加
func incrementCounter() {
    for i := 0; i < 100000; i++ {
        mutex.Lock()
        counter++
        mutex.Unlock()
    }
}

func main() {
    var wg sync.WaitGroup

    // 启动多个goroutine并发累加
    for i := 0; i < 10; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            incrementCounter()
        }()
    }

    wg.Wait()

    fmt.Println("Final counter:", counter)
}
```

在这个例子中，`mutex.Lock()` 和 `mutex.Unlock()` 确保了 `counter` 的更新是原子的，避免了数据竞争。

# `sync.RWMutex`（读写锁）

- **读写分离**：`RWMutex` 支持读写分离，允许多个 goroutine 同时读取资源，但不允许同时写入。当有 goroutine
  正在写入时，所有读取和写入操作都将被阻塞。
- **写优先**：当有 goroutine 请求写锁时，所有正在进行的读操作将被阻塞，直到写操作完成。这是为了保证数据的一致性，因为在写入期间读取可能看到不完整或未提交的数据。
- **升级锁**：从读锁升级到写锁通常需要先释放读锁再获取写锁，即便在写锁请求被阻塞期间有新的读锁请求加入，写锁的请求者也必须等待所有读锁都被释放后才能获得写锁。
- **可重入**: 一个已经持有读锁的 goroutine 可以再次获取同一把锁，不会引起 panic。尽管多个 goroutines
  可以同时获取读锁，但写锁具有独占性，即当一个 goroutine 持有写锁时，所有其他 goroutines 的读锁和写锁请求都会被阻塞，直到写锁被释放。

```go
package main

import (
	"fmt"    // 标准库包，用于格式化输入输出
	"sync"   // 提供同步原语，如互斥锁和条件变量
	"time"   // 时间相关的函数和类型
)

// Cache 结构体用于表示一个简单的键值对缓存。
// 使用 RWMutex 来支持并发读取和独占写入。
type Cache struct {
	data map[string]string // 存储缓存数据的 map
	lock sync.RWMutex      // 读写锁，允许多个读取者同时访问，但写入时独占
}

// NewCache 是一个工厂函数，用于创建一个新的 Cache 实例。
func NewCache() *Cache {
	return &Cache{
		data: make(map[string]string), // 初始化一个空的字符串键值对 map
	}
}

// Get 方法用于从缓存中获取指定键的值。
// 使用 RLock 和 RUnlock 来确保读取操作是线程安全的。
func (c *Cache) Get(key string) string {
	c.lock.RLock() // 获取读锁
	defer c.lock.RUnlock() // 延迟解锁，确保在函数返回前解锁
	return c.data[key]     // 返回缓存中对应键的值
}

// Set 方法用于将键值对存入缓存。
// 使用 Lock 和 Unlock 来确保写入操作是线程安全的。
func (c *Cache) Set(key string, value string) {
	c.lock.Lock()   // 获取写锁
	defer c.lock.Unlock() // 延迟解锁，确保在函数返回前解锁
	c.data[key] = value // 更新缓存中的键值对
}

// readFromCache 函数模拟读取缓存的操作。
// 它会多次调用 Get 方法来读取缓存中的一个特定键。
func readFromCache(cache *Cache, key string) {
	for i := 0; i < 10000; i++ {
		cache.Get(key) // 读取缓存中的值
	}
}

// writeToCache 函数模拟写入缓存的操作。
// 它会多次调用 Set 方法来更新缓存中的一个特定键。
func writeToCache(cache *Cache, key string, value string) {
	for i := 0; i < 100; i++ {
		cache.Set(key, value) // 更新缓存中的键值对
	}
}

func main() {
	cache := NewCache() // 创建一个新的缓存实例
	cache.Set("key", "value") // 初始化缓存中的一个键值对

	var wg sync.WaitGroup // 创建一个 WaitGroup，用于等待所有 goroutine 完成

	// 启动 10 个 goroutine 来读取缓存中的值
	for i := 0; i < 10; i++ {
		wg.Add(1) // 增加 WaitGroup 的计数
		go func() { // 启动一个匿名 goroutine
			defer wg.Done() // 当 goroutine 完成时减少 WaitGroup 的计数
			readFromCache(cache, "key") // 读取缓存中的值
		}()
	}

	// 启动一个 goroutine 来写入更新缓存中的值
	wg.Add(1)
	go func() {
		defer wg.Done() // 当 goroutine 完成时减少 WaitGroup 的计数
		writeToCache(cache, "key", "new_value") // 更新缓存中的键值对
	}()

	// 等待所有启动的 goroutine 完成
	wg.Wait()

	// 输出最终的缓存值
	fmt.Println("Final cache value:", cache.Get("key"))
}
```

在这个例子中，`RWMutex` 允许多个 goroutine 同时读取缓存，但在写入时确保了独占访问，防止了数据竞争。

这在读操作远多于写操作的场景下可以提供更好的并发性能。