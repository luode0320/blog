# 简介

CSP思想就是 **不要通过共享内存来通信，而要通过通信来实现内存共享。**

这就是 Go 的并发哲学，它依赖 CSP 模型，基于 channel 通道, 从而实现线程直接的通信。



# CSP由来

CSP 全称是 `“Communicating Sequential Processes”`，是由计算机科学家 **Tony Hoare** 在 1978 年提出的一种用于描述并发系统的形式化方法。

- CSP 提供了一种清晰的方式来定义和理解并发程序的行为，它基于进程间的通信来实现同步和协调。

- 论文里指出一门编程语言应该重视 **input** 和 **output** 的原语，尤其是并发编程的代码。

在那篇文章发表的时代，人们正在研究模块化编程的思想，该不该用 goto 语句在当时是最激烈的议题。

彼时，面向对象编程的思想正在崛起，几乎没什么人关心并发编程。

在论文中，CSP 也是一门自定义的编程语言，作者定义了输入输出语句，用于处理 processes 间的通信（communication）。

- processes 被认为是需要输入驱动，并且产生输出，供其他 processes 消费，processes 可以是进程、线程、甚至是代码块。
- 输入命令是：!，用来向 processes 写入；
- 输出是：?，用来从 processes 读出。
- 这篇文章要讲的 channel 正是借鉴了这一设计。
- **Tony Hoare** 还提出了一个` -> `命令，如果` -> `左边的语句返回 false，那它右边的语句就不会执行。

通过这些输入输出命令， **Tony Hoare** 证明了如果一门编程语言中把 processes 间的通信看得第一等重要，那么并发编程的问题就会变得简单。

# Go中的CSP

Go 是第一个将 CSP 的这些思想引入，并且发扬光大的语言。CSP 经常被认为是 Go 在并发编程上成功的关键因素。

- 仅管内存同步访问控制（原文是 memory access synchronization）在某些情况下大有用处，Go 里也有相应的 sync 包支持，但是这在大型程序很容易出错。

- Go 一开始就把 CSP 的思想融入到语言的核心里，所以并发编程成为 Go 的一个独特的优势，而且很容易理解。
- **大多数的编程语言的并发编程模型是基于线程和内存同步访问控制，Go 的并发编程的模型则用 goroutine 和 channel 来替代。**
- Goroutine 和线程类似，channel 和 mutex (用于内存同步访问控制)类似。

Goroutine 解放了程序员，让我们更能贴近业务去思考问题。

而不用考虑各种像线程库、线程开销、线程调度等等这些繁琐的底层问题，Goroutine 天生替你解决好了。

Channel 则天生就可以和其他 Channel 组合。

- 我们可以把收集各种子系统结果的 Channel 输入到同一个 Channel 。
- Channel 还可以和 select, cancel, timeout 结合起来。而 mutex 就没有这些功能。

Go 的并发原则非常优秀，目标就是简单：

- 尽量使用 Channel；
- 把 Goroutine 当作免费的资源，随便用。

# Goroutine

Goroutine 是 Go 语言中的并发执行单元，它比操作系统线程更轻量级，可以由 Go 运行时在多个 OS 线程上调度执行。

创建一个 goroutine 非常简单，只需在函数调用前加上 `go` 关键字即可。

# Channel

Channel 是 goroutines 之间通信的媒介，它提供了一种类型安全的并发原语，可以用来发送和接收数据。

通过 channel，goroutines 可以同步数据和控制流，从而实现并发而不必担心竞态条件。

# 举例

下面是一个简单的 Go 语言 CSP 风格的并发程序示例，展示如何使用 goroutines 和 channels：

```go
package main

import (
	"fmt"
	"time"
)

func main() {
	// 创建一个整数类型的 无缓冲的 channel
	ch := make(chan int)

	// 创建一个 goroutine，用于生成数字
	go func() {
		for i := 0; i < 10; i++ {
			ch <- i // 将10个数字发送到 channel
			fmt.Println("写入: ", i)
			time.Sleep(time.Millisecond * 100)
		}
		close(ch) // 关闭 channel，表示没有更多的数据
	}()

	// 主 goroutine 从 channel 接收数字并打印
	for n := range ch {
		fmt.Println("输出: ", n)
	}
}
```

运行结果:

```go
写入:  0
输出:  0
写入:  1
输出:  1
写入:  2
输出:  2
写入:  3
输出:  3
写入:  4
输出:  4
写入:  5
输出:  5
```

在这个例子中

- 我们创建了一个 goroutine 来生成数字并将它们发送到 channel `ch`。

- 主 goroutine 通过 `for` 循环从 `ch` 接收数据并打印。
- 当没有更多的数据发送时，channel 被关闭，`for` 循环结束。

CSP 的核心思想是**通过通信而非共享**状态来实现并发，这在 Go 语言中得到了很好的体现，使得并发编程变得更加优雅和易于理解。

通过 goroutines 和 channels 的组合，开发者可以构建出高度并发且可维护的软件系统。

