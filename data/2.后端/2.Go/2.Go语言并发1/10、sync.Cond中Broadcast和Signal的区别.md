# 简介

在 Go 语言的 `sync.Cond` 中，`Broadcast()` 和 `Signal()` 方法都是用来通知等待的 Goroutine 的。

它们的主要区别在于

- `Broadcast()` 会通知所有正在等待的 Goroutine
- 而 `Signal()` 只会通知一个等待的 Goroutine。



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
	fmt.Println("Signal 下发一个通知给已经获取锁的 goroutine...")
	cond.Signal()

	time.Sleep(time.Second * 1)
	fmt.Println("Broadcast 下发广播给所有等待的 goroutine...")
	cond.Broadcast()

	time.Sleep(time.Second * 3)
}
```

运行结果: 

```go
Signal 下发一个通知给已经获取锁的 goroutine...
当前 id 的值： 2 当前 x 的值： 1
Broadcast 下发广播给所有等待的 goroutine...
当前 id 的值： 6 当前 x 的值： 2 
当前 id 的值： 4 当前 x 的值： 3 
当前 id 的值： 8 当前 x 的值： 4 
当前 id 的值： 10 当前 x 的值： 5
```

在这个示例中，`Signal`会唤醒一个被阻塞的 goroutine 执行, `Broadcast`会唤醒所有被阻塞的 goroutine 执行