# 简介

Go 语言中的 `Cond` 是一种条件变量，它允许多个 Goroutine 在满足某个条件时进行协作。

- `Cond` 提供了一种机制，可以让一个 Goroutine 在满足某种条件时通知其他 Goroutine，或者让其他 Goroutine 在满足某种条件时等待通知。



# 主要功能

- `Wait()`: goroutine 调用这个方法时会释放与 `Cond` 关联的锁，然后挂起自身，直到另一个 goroutine 调用 `Signal` 或 `Broadcast` 方法来唤醒它。
- `Signal()`: 唤醒一个正在等待的 goroutine。
- `Broadcast()`: 唤醒所有正在等待的 goroutine。



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