# 简介

在 Go 语言中，CAS 是 **Compare-and-Swap** 的缩写，是一种原子操作，用于实现多线程并发控制。

CAS 操作包括三个参数：

- 内存位置的引用
- 预期值 A 
- 新值 B

CAS 操作会比较内存位置的当前值与预期值 A，如果相等，则将该位置的值更新为新值 B。

整个比较和更新的过程是原子的，不会被其他线程中断，并且能够保证操作的一致性和可见性。



> 原子操作在执行过程中**只有一个 CPU 核心执行该操作，而且这个 CPU 必须在一次性完成整个原子操作，期间不能被切换到其他 CPU 执行其他任务**。
>
> 当一个 CPU 核心开始原子操作某个值时，会将这个值加载到自己的处理器缓存中，并标记为“独占”状态，表示该 CPU 正在对该值进行操作。
>
> 在这种情况下，其他 CPU 核心在尝试操作同一个值时，会触发**缓存一致性协议**，其他 CPU 核心会被禁止直接对该值进行操作



# 执行过程

假设包含 3 个参数内存位置(V)、预期原值(A)和新值(B)。

- V 表示要更新变量的源值，E 表示预期源值，N 表示要更新的新值。
- 仅当 V 值等于 E 值时，才会将 V 的值设为 N
- 如果 V 值和 E 值不同，则说明已经有其他线程在做更新，则当前线程什么都不做
- 最后 CAS 返回当前 V 的真实值。

CAS 操作时抱着乐观的态度进行的，它总是认为自己可以成功完成操作。

基于这样的原理，CAS 操作即使没有锁，也可以发现其他线程对于当前线程的干扰。



# 示例

```go
package main

import (
	"sync/atomic"
	"fmt"
)

func main() {
	var value int32 = 10

	// 使用 CAS 操作更新值
	newValue := atomic.CompareAndSwapInt32(&value, 10, 20)
	fmt.Println("CAS result:", newValue)

	// 使用 CAS 操作更新失败，因为预期值不匹配
	newValue = atomic.CompareAndSwapInt32(&value, 15, 30)
	fmt.Println("CAS result:", newValue)

	// value 的值已经更新为 20
	fmt.Println("New value:", value)
}
```

