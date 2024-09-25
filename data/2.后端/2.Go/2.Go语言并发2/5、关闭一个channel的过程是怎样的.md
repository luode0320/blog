# 简介

在 Go 语言中，关闭一个 channel 主要涉及到以下步骤：

1. **确认发送方已经完成发送**：通常在所有的发送操作完成之后，发送方的 goroutine 会负责关闭 channel。这是因为一旦 channel
   被关闭，就无法再向其发送数据。

2. **使用 `close()` 函数**：发送方的 goroutine 使用内置的 `close()` 函数来关闭 channel。这将标记 channel 为已关闭状态。

3. **通知接收方**：关闭 channel 会立即通知所有正在从该 channel 接收数据的 goroutines

   如果 channel 缓冲区为空，接收操作将立即返回零值和一个 `false` 的第二返回值（如果使用了 `recv, ok := <-ch` 的形式）。

4. **垃圾回收**：如果没有任何 goroutine 引用该 channel，即使没有被显式关闭，它也会被垃圾回收器回收。

# closechan源码

`runtime/chan.go`

关闭某个 channel，会执行函数 `closechan`：

```go
// 关闭一个通道。
// 如果通道为 nil，将触发 panic。
// 如果通道已经被关闭，再次调用此函数也将触发 panic。
func closechan(c *hchan) {
	// 检查通道是否为 nil
	if c == nil {
		panic(plainError("close of nil channel"))
	}

	// 加锁通道，防止其他 goroutines 修改通道状态
	lock(&c.lock)

	// 如果通道已经关闭，解锁并触发 panic
	if c.closed != 0 {
		unlock(&c.lock)
		panic(plainError("close of closed channel"))
	}

	// 如果启用了竞争检测
	if raceenabled {
		callerpc := getcallerpc()                                             // 获取调用者 PC
		racewritepc(c.raceaddr(), callerpc, abi.FuncPCABIInternal(closechan)) // 记录对通道的写操作
		racerelease(c.raceaddr())                                             // 释放竞争检测锁
	}

	// 标记通道为已关闭
	c.closed = 1

	// 创建一个列表，用于保存等待的 goroutines
	var glist gList

	// 释放所有接收者
	for {
		// 从接收队列中移除一个 sudog
		sg := c.recvq.dequeue()
		// 如果队列为空，退出循环
		if sg == nil {
			break
		}
		// 如果 sudog 持有数据
		if sg.elem != nil {
			typedmemclr(c.elemtype, sg.elem) // 清除数据
			sg.elem = nil                    // 清空 sudog 的 elem 字段
		}
		// 如果设置了释放时间
		if sg.releasetime != 0 {
			sg.releasetime = cputicks() // 更新释放时间
		}

		gp := sg.g                    // 获取 sudog 所属的 goroutine
		gp.param = unsafe.Pointer(sg) // 设置 goroutine 参数为 sudog
		sg.success = false            // 标记接收操作失败

		// 如果启用了竞争检测
		if raceenabled {
			raceacquireg(gp, c.raceaddr()) // 通知竞争检测器 goroutine 访问通道
		}

		// 将接收者 goroutine 添加到列表中
		glist.push(gp)
	}

	// 释放所有写者（他们将会 panic, 发送者本身如果发现通道被关闭会触发 panic）
	for {
		// 从发送队列中移除一个 sudog
		sg := c.sendq.dequeue()
		if sg == nil {
			break // 如果队列为空，退出循环
		}

		sg.elem = nil // 清空 sudog 的 elem 字段
		// 如果设置了释放时间
		if sg.releasetime != 0 {
			sg.releasetime = cputicks() // 更新释放时间
		}

		gp := sg.g                    // 获取 sudog 所属的 goroutine
		gp.param = unsafe.Pointer(sg) // 设置 goroutine 参数为 sudog
		sg.success = false            // 标记发送操作失败

		// 如果启用了竞争检测
		if raceenabled {
			raceacquireg(gp, c.raceaddr()) // 通知竞争检测器 goroutine 访问通道
		}
		// 将 goroutine 添加到列表中
		glist.push(gp)
	}

	// 解锁通道
	unlock(&c.lock)

	// 当我们已经释放了通道锁，现在准备好所有 Gs。

	// 遍历列表中的所有 goroutines
	for !glist.empty() {
		gp := glist.pop() // 移除列表中的一个 goroutine
		gp.schedlink = 0  // 清除调度链接
		goready(gp, 3)    // 将 goroutine 设置为可运行状态
	}
}
```

1. **检查通道**：首先检查通道是否为 `nil` 或者已经关闭，如果是，则触发 panic。
2. **加锁通道**：加锁通道，防止其他 goroutines 在关闭过程中修改通道状态。
3. **标记通道关闭**：将通道的 `closed` 标志设为 `1`，表示通道已关闭。
4. **释放所有等待接收的 goroutines**：遍历接收队列，清除每个 sudog 的数据，将 sudog 的 `success` 字段设为 `false`，并将
   goroutine 添加到 `glist` 列表中。
5. **释放所有等待发送的 goroutines**：遍历发送队列，将 sudog 的 `elem` 字段清空，将 sudog 的 `success` 字段设为 `false`，并将
   goroutine 添加到 `glist` 列表中。
6. **解锁通道**：完成所有内部操作后，解锁通道。
7. **唤醒所有等待的 goroutines**：遍历 `glist` 列表，将所有等待的 goroutines 设置为可运行状态，使它们可以继续执行。

# 示例

```go
package main

import (
	"fmt"
	"time"
)

func sendData(ch chan int) {
	for i := 0; i < 10; i++ {
		ch <- i // 向 channel 发送数据
		fmt.Printf("Sent: %d\n", i)
		time.Sleep(1 * time.Second)
	}
	close(ch) // 关闭 channel
}

func main() {
	ch := make(chan int) // 创建一个无缓冲的整型 channel

	go sendData(ch) // 在新的 goroutine 中发送数据

	for v := range ch {
		fmt.Printf("Received: %d\n", v)
	}
	fmt.Println("All data received and channel closed.")
}
```

