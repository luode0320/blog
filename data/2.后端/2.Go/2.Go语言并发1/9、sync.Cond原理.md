# 简介

Go 语言中的 `Cond` 是一种条件变量，它允许多个 Goroutine 在满足某个条件时进行协作。

- `Cond` 提供了一种机制，可以让一个 Goroutine 在满足某种条件时通知其他 Goroutine，或者让其他 Goroutine 在满足某种条件时等待通知。



# 主要功能

- `Wait()`: goroutine 调用这个方法时会释放与 `Cond` 关联的锁，然后挂起自身，直到另一个 goroutine 调用 `Signal` 或 `Broadcast` 方法来唤醒它。
- `Signal()`: 唤醒一个正在等待的 goroutine。
- `Broadcast()`: 唤醒所有正在等待的 goroutine。



# 内部原理

`sync.Cond` 的内部原理：

1. **与锁相关联**: `sync.Cond` 必须与一个锁关联，通常是 `sync.Mutex` 或 `sync.RWMutex`。

   这是通过其构造函数 `sync.NewCond(Locker)` 来实现的，其中 `Locker` 必须实现 `Lock()` 和 `Unlock()` 方法。

2. **队列和列表**: 当一个 goroutine 调用 `Wait()` 方法时，它会被添加到一个等待队列中。

   当它被 `Signal` 或 `Broadcast` 唤醒时，它会从队列中移除并重新调度。

3. **信号和广播**:

   - `Signal()` 方法唤醒等待队列中的一个 goroutine。如果多个 goroutine 正在等待，那么其中一个会被选择并唤醒。
   - `Broadcast()` 方法唤醒等待队列中的所有 goroutine。

4. **重新获取锁**: 在调用 `Wait()` 后，goroutine 会释放锁并挂起。当它被唤醒时，它会尝试重新获取锁。

   

# 源码解析

`src/sync/cond.go`

## 结构体

```go
// Cond 实现了条件变量，是 Goroutine 在等待事件发生或宣布事件发生时的会合点。
//
// 每个 Cond 都有一个关联的锁 L（通常是 *Mutex 或 *RWMutex），
// 在改变条件和调用 Wait 方法时必须持有该锁。
//
// 在首次使用后，Cond 不得被复制。
//
// 在 Go 内存模型的术语中，Cond 会安排 Broadcast 或 Signal 的调用“与任何它解除阻塞的 Wait 调用同步”。
//
// 对于许多简单的用例，用户使用通道比使用 Cond 更好（Broadcast 对应于关闭通道，Signal 对应于在通道上发送）。
//
// 有关替代 sync.Cond 的更多信息，请参见 [Roberto Clapis 关于高级并发模式的系列文章]，以及 [Bryan Mills 关于并发模式的讲座]。
//
// [Roberto Clapis 关于高级并发模式的系列文章]: https://blogtitle.github.io/categories/concurrency/
// [Bryan Mills 关于并发模式的讲座]: https://drive.google.com/file/d/1nPdvhB0PutEJzdCq5ms6UI58dp50fcAN/view
type Cond struct {
	noCopy  noCopy      // noCopy 用于确保 Cond 不被复制
	L       Locker      // 表示可以锁定和解锁的对象（通常是 *Mutex 或 *RWMutex）。
	notify  notifyList  // notify 用于通知列表
	checker copyChecker // checker 用于检查复制
}
```



## NewCond创建

```go
// NewCond 返回一个带有（通常是 *Mutex 或 *RWMutex）的新 Cond。
func NewCond(l Locker) *Cond {
	return &Cond{L: l}
}
```



## Wait()等待唤醒

```go
// Wait 在原子性地解锁 c.L 并挂起调用 Goroutine 的执行。在稍后恢复执行后，
// Wait 在返回之前会锁定 c.L。不同于其他系统，在没有被 Broadcast 或 Signal 唤醒的情况下，Wait 无法返回。
//
// 因为在 Wait 等待时 c.L 没有被锁定，调用者通常不能假设条件在 Wait 返回时就为真。
// 在使用 Wait 之前, 你必须加锁 c.L.Lock():
//
//	c.L.Lock()
//	for !condition() {
//	    c.Wait()
//	}
//	... 利用条件 ...
//	c.L.Unlock()
func (c *Cond) Wait() {
	// 检查是否存在复制
	c.checker.check()
	// 此 goroutine 添加到通知列表
	t := runtime_notifyListAdd(&c.notify)
	// 解锁 c.L
	c.L.Unlock()
	// 等待通知列表通知, 当前 goroutine 此时被阻塞
	runtime_notifyListWait(&c.notify, t)

	// 唤醒之后立开始竞争锁, 只有竞争到锁的才会结束 Wait 方法
    // 保证共享数据的并发安全性
	c.L.Lock()
}
```



## Signal()唤醒一个

```go
// Signal 唤醒在 c 上等待的一个 Goroutine（如果有的话）。
func (c *Cond) Signal() {
	c.checker.check()
	runtime_notifyListNotifyOne(&c.notify)
}
```



## Broadcast唤醒所有

```go
// Broadcast 唤醒所有在 c 上等待的 Goroutine。
func (c *Cond) Broadcast() {
	c.checker.check()                      // 检查是否存在复制
	runtime_notifyListNotifyAll(&c.notify) // 通知列表唤醒所有 Goroutine
}
```



# 示例

```go
package main

import (
	"fmt"
	"sync"
	"time"
)

func main() {
	var locker = new(sync.Mutex)
	var cond = sync.NewCond(locker)

	x := 0 // 共享变量

	for i := 1; i <= 10; i++ {
		go func(id int) {
			cond.L.Lock()         // 获取锁
			defer cond.L.Unlock() // 释放锁

			// 只有 id 对 2 取模的协程才可以使用这个共享变量
			if id%2 == 0 {
				// 等待通知，阻塞当前 goroutine, 并且会释放 cond 的锁
				cond.Wait()
				// 对共享变量进行操作
				x++
				fmt.Println("当前 id 的值：", id, "当前 x 的值：", x)
			}
		}(i)
	}

	time.Sleep(time.Second * 1)
	fmt.Println("下发一个通知给已经获取锁的 goroutine...")
	cond.Signal()

	time.Sleep(time.Second * 1)
	fmt.Println("下发一个通知给已经获取锁的 goroutine...")
	cond.Signal()

	time.Sleep(time.Second * 1)
	fmt.Println("下发广播给所有等待的 goroutine...")
	cond.Broadcast()

	time.Sleep(time.Second * 3)
}
```

运行结果: 

```go
下发一个通知给已经获取锁的 goroutine...
当前 id 的值： 2 当前 x 的值： 1
下发一个通知给已经获取锁的 goroutine...
当前 id 的值： 4 当前 x 的值： 2
下发广播给所有等待的 goroutine...
当前 id 的值： 10 当前 x 的值： 3
当前 id 的值： 6 当前 x 的值： 4 
当前 id 的值： 8 当前 x 的值： 5 
```

在这个示例中，我们使用了 `sync.Cond` 来实现对共享变量 `x` 的操作

- 只允许对 `x` 进行操作的 goroutine 是根据其编号是否为偶数来确定的。

- 当每个 goroutine启动时，如果其编号为偶数，它将等待来自 `cond` 的通知。
- 一旦收到通知，它就会对共享变量 `x` 进行操作，递增 `x` 的值。
- 最后，在主函数中通过 `Signal` 和 `Broadcast` 方法向等待中的 goroutine 发送通知，唤醒等待的 goroutine。
- 这将触发满足条件的 goroutine 执行对共享变量 `x` 的操作。