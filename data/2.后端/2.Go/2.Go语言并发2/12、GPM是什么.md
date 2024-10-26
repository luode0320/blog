# 简介

Go 语言的 GPM 调度模型是其运行时调度器的核心概念，其中 GPM 分别代表 Goroutine、Processor 和 Machine。

这个模型是 Go 语言实现高效并发的关键，它允许大量的 goroutine 在有限数量的机器线程上运行，从而最大化 CPU 利用率和响应速度。



# GPM 的各部分定义：

1. **Goroutine (G)**：这是 Go 语言中的轻量级线程，由 `go` 关键字创建。每个 goroutine 都有自己的独立栈，它们的上下文切换成本远低于传统线程，因为切换发生在用户空间，无需内核介入。
2. **Processor (P)**：在 Go 调度器中，Processor 是一个逻辑上的概念，它代表了一个调度单元，负责管理一组 goroutine 的调度和执行。每个 P 都有自己的就绪队列、等待队列和其他数据结构，用于跟踪和管理其管辖范围内的 goroutine。
3. **Machine (M)**：Machine 指的是实际的操作系统线程，每个 M 都与一个或多个 P 关联，负责执行 P 上的 goroutine。M 的数量通常不会超过系统中的逻辑 CPU 核心数，以确保高效的 CPU 利用率。



# GPM 模型的运作方式：

- **Goroutine 创建**：当使用 `go` 关键字创建一个 goroutine 时，Go 调度器会将这个 goroutine 加入某个 P 的就绪队列中。
- **调度与执行**：当 M 从 P 的就绪队列中选取一个 goroutine 来执行时，它会将该 goroutine 的状态从就绪变为运行中，并将控制权交给这个 goroutine。一旦 goroutine 完成执行，M 会将控制权交回给调度器，调度器会从 P 的就绪队列中选择下一个 goroutine 来执行。
- **工作窃取**：如果一个 P 的就绪队列为空，而另一个 P 的队列中有可运行的 goroutine，那么前一个 P 可以从后一个 P 的队列中“窃取” goroutine 来执行，以保持 CPU 占用率。
- **上下文切换**：当 goroutine 遇到 I/O 阻塞、channel 操作或其他同步点时，Go 调度器会暂停这个 goroutine，并将其状态设置为等待。当阻塞条件解除时，goroutine 会被重新加入 P 的就绪队列。



GPM 三足鼎力，共同成就 Go scheduler。

- G 需要在 M 上才能运行，M 依赖 P 提供的资源，P 则持有待运行的 G。

- M 会从与它绑定的 P 的本地队列获取可运行的 G，也会从全局队列里获取可运行的 G，还会从其他 P 偷 G。

