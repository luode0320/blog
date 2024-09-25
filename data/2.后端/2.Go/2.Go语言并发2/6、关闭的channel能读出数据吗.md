# 简介

在 Go 语言中，从一个已经关闭的 channel 读取数据是可以的，但是有一些重要的事情需要注意：

1. **读取剩余数据**：如果你在一个有缓冲的 channel 上调用 `close()`，那么在 channel 中任何尚未读取的数据仍然可以被读取出来。

   一旦所有的数据都被读取完毕，再尝试读取 channel 将会立即返回零值和 `false` 的第二返回值。

   只能取出缓冲区的数据, 哪些被阻塞的 goroutine 已经被释放了, 就不能取这些数据了。

2. **读取零值**：对于无缓冲的 channel 或者当缓冲区中的所有数据都被读取完毕后，从关闭的 channel
   读取数据会立即返回零值和 `false` 的第二返回值。

   这里的零值取决于 channel 元素的类型。

# 读取的部分源码

`runtime/chan.go/chanrecv()`

```go
	if c.closed != 0 {
		if c.qcount == 0 {
			if raceenabled {
				raceacquire(c.raceaddr())
			}
			unlock(&c.lock)
			if ep != nil {
				typedmemclr(c.elemtype, ep)
			}
			return true, false
		}
		// 通道已关闭，但通道的缓冲中有数据, 不必理会, 就算关闭了, 也可以继续读取。
	} else {
		...
	}

	if c.qcount > 0 {
		// 直接从队列接收。
		// 计算队列中数据的位置
		qp := chanbuf(c, c.recvx)
		...
		return true, true // 返回 true 表示已成功从通道接收数据，且通道有数据
	}
```

# 示例

```go
package main

import (
	"fmt"
	"time"
)

func sendData(ch chan int) {
	for i := 0; i < 5; i++ {
		ch <- i // 向 channel 发送数据
	}
	close(ch) // 关闭 channel
}

func main() {
	ch := make(chan int, 10) // 创建一个有缓冲的整型 channel

	go sendData(ch) // 在新的 goroutine 中发送数据
	// 睡眠 3s, 保证通道被关闭
	time.Sleep(3)

	for {
		val, ok := <-ch // 从 channel 读取数据
		if !ok {
			fmt.Println("Channel is closed, no more data.")
			break // 一旦 channel 关闭且没有更多数据，退出循环
		}
		fmt.Printf("Received: %d\n", val)
	}
	fmt.Println("All data received.")
}

```

运行结果:

```go
Received: 0
Received: 1                     
Received: 2                     
Received: 3                     
Received: 4                     
Channel is closed, no more data.
All data received. 
```

在这个示例中：

- `sendData` 函数在一个 goroutine 中向 channel 发送数字，然后关闭 channel。
- 主 goroutine 使用 `for` 循环和 `val, ok := <-ch` 形式从 channel 接收数据。
- 当 `ok` 是 `false` 时，表示 channel 已经关闭并且没有更多的数据可以读取，此时退出循环。

当所有的数据都被读取后，再尝试读取 channel 将会得到 `false` 的 `ok` 值，这意味着 channel 已经关闭并且没有更多的数据。

在有缓冲的 channel 中，你可能需要读取多次才能完全消耗掉缓冲区中的所有数据，之后才会得到 `false` 的 `ok` 值。

在无缓冲的 channel 中，一旦 channel 被关闭，第一次尝试读取就会立即返回 `false` 的 `ok` 值。


