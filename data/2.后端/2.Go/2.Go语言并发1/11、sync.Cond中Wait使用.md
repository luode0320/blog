# 简介

在 Go 语言中，`sync.Cond` 是一个条件变量，它提供了一种等待某个条件发生的方法。

你可以通过 `Cond` 对象的 `Wait()` 方法来阻塞当前线程，直到其他线程满足了这个条件。



# 原理

- `Wait()`会自动释放 c.L 锁，并挂起调用者的 goroutine。

- 之后恢复执行，`Wait()`会在返回时对 c.L 加锁。

- 除非被 `Signal` 或者 `Broadcast` 唤醒，否则 `Wait()` 不会返回, 会一直阻塞。



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
	fmt.Println("Broadcast 下发广播给所有等待的 goroutine...")
	cond.Broadcast()

	time.Sleep(time.Second * 3)
}
```

运行结果: 

```go
Broadcast 下发广播给所有等待的 goroutine...
当前 id 的值： 8 当前 x 的值： 1 
当前 id 的值： 4 当前 x 的值： 2 
当前 id 的值： 2 当前 x 的值： 3 
当前 id 的值： 6 当前 x 的值： 4 
当前 id 的值： 10 当前 x 的值： 5
```

