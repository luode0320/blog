# 简介

在 Go 语言中，channel 发送和接收元素的本质是基于通信的同步机制，它允许不同的 goroutines 之间进行安全的数据交换。

- 具体来说，当一个 goroutine 向 channel 发送元素时，它实际上是将这个元素的值拷贝到 channel 的缓冲区中；
- 同样地，当另一个 goroutine 从 channel 接收元素时，它从缓冲区中取出元素的值拷贝到自己的作用域内。

- 或者是直接从 sender goroutine 到 receiver goroutine。
- 这一过程确保了数据的一致性和线程安全，因为 channel 作为通信的中介，控制了数据的流动。

# 拷贝本质

`runtime/stubs.go`

```go
// 将源地址 from 处开始的连续 n 个字节复制到目标地址 to 处

// to：要将数据复制到的目标内存地址
// from：要从中复制数据的源内存地址
// n：要复制的字节数
//
//go:noescape
func memmove(to, from unsafe.Pointer, n uintptr)
```

通过 channel 发送和接收元素的过程本质上是数据的值拷贝和同步控制，确保了在多 goroutine 环境下的数据完整性和线程安全。

这种机制使得 Go 成为了并发编程的一个强大工具，因为它简化了共享数据的处理，避免了常见的竞态条件和死锁问题。