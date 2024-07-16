# 简介

在 Go 语言中，goroutine 的调度时机由运行时调度器（Go Scheduler）决定，它根据多种情况和条件来确定何时调度或重新调度一个 goroutine。



# 常见时机

1. **goroutine 创建时**：

   - 当使用 `go` 关键字启动一个新的 goroutine 时，调度器会立即将其放入可运行队列，并唤醒一个等待的处理器 p。

2. **goroutine 完成执行时**：

   - 当一个 goroutine 执行完毕，调度器会检查当前机器线程（M）上是否有其他可运行的 goroutine
   - 如果没有，可能会选择休眠或窃取其他处理器（P）的工作。

3. **goroutine 阻塞时**：

   - 当一个 goroutine 遇到 I/O 操作、channel 操作、锁等待等阻塞调用时，它会被置于等待状态, 加入网络阻塞队列
   - 调度器会选择另一个可运行的 goroutine 来执行。

4. **goroutine 主动放弃 CPU 时间**：

   - 当 goroutine 调用 `runtime.Gosched()` 函数时，它会主动放弃 CPU 时间，让调度器有机会选择另一个 goroutine 来执行。

5. **时间片到期**：

   - Go 使用时间片轮询策略，每个 goroutine 在获得 CPU 时间后只能执行一定时间，时间片到期后，调度器会抢占当前 goroutine 并调度另一个 goroutine。

6. **资源可用时**：

   - 当一个 goroutine 正在等待的资源（如 channel 通信）变得可用时，调度器会将该 goroutine 移回到可运行队列。
   - 唤醒网络阻塞队列

7. **响应外部事件**：

   - 如定时器触发或外部信号到达时，调度器可能会重新调度 goroutines 以处理这些事件。

8. **工作窃取**：

   - 如果一个处理器（P）上的 goroutine 队列空了，它可以从其他处理器的队列中窃取 goroutine 来执行，这时调度器会重新安排工作负载。

9. **垃圾回收**：

   - 当 Go 运行时进行垃圾回收时，它会暂停所有的 goroutine，然后重新调度它们。

10. **系统调用返回时**：

    - 当一个 goroutine 执行系统调用并返回时，调度器会重新调度该 goroutine。

    
