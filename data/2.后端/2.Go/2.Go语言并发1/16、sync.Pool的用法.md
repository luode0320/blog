# 简介

`sync.Pool` 是 Go 语言中的一个实用工具，用于缓存可复用的对象。

- 它的主要目的是为了提高性能，避免频繁地分配和销毁对象。
- `sync.Pool` 提供了一种线程安全的方式来存储和检索对象，这些对象可以在不同的 goroutine 之间共享。
- 待下次需要的时候直接使用，复用对象的内存，减轻 GC 的压力，提升系统的性能。



# 原理

下面是一些关于 `sync.Pool` 的关键原理：

1. **对象缓存**: `sync.Pool` 允许你缓存可重用的对象。当你从池中获取一个对象时，`sync.Pool` 会返回一个已存在的对象，如果池中没有对象，它会调用 `New` 函数来创建一个新对象。
2. **线程安全性**: `sync.Pool` 被设计成线程安全的，这意味着多个 goroutine 可以同时从池中获取和放回对象，而不需要额外的同步措施。
3. **对象生命周期管理**: 当你不再需要一个对象时，你可以将其放回池中，这样它就可以被其他 goroutine 重用。`sync.Pool` 会根据当前的负载和资源情况决定是否立即回收对象或者保留它以备后续使用。
4. **自动调整**: `sync.Pool` 会根据运行时的状况自动调整其内部对象的缓存策略。例如，在高负载情况下，它可能会保留更多的对象以减少内存分配的开销；而在低负载时，它可能会释放更多的对象以减少内存占用。
5. **垃圾收集的交互**: `sync.Pool` 不会阻止垃圾收集器（GC）回收对象，而是依赖于 GC 来决定何时释放池中的对象。当一个对象在池中长时间未被使用时，GC 可能会将其回收，这取决于 GC 的策略和系统的资源需求。
6. **局部性**: `sync.Pool` 试图保持对象的局部性，这意味着它会尽量让同一个 goroutine 或者在同一个 CPU 上运行的 goroutines 使用相同对象池中的对象，以减少跨 CPU 缓存的访问。
7. **非持久性对象**: 由于 `sync.Pool` 中的对象可能被任何 goroutine 使用，因此这些对象应该是无状态的，或者是状态可以在每次使用前被重置的，以避免数据竞争或状态混乱。
8. **自定义 `New` 函数**: `sync.Pool` 的 `New` 函数是一个可选的回调函数，当池中没有可用对象时被调用来创建新对象。这使得你可以控制对象的创建过程，例如，你可以创建特定类型的实例，或者预填充对象的一些字段。



# fmt包示例

创建一个`sync.Pool`

```go
var ppFree = sync.Pool{
    // 可选的回调函数，当池中没有可用对象时被调用来创建新对象。
	New: func() any { return new(pp) },
}
```

一个取出缓存对象的通用方法, 这个方法会在`fmt`使用其方法代码块的第一行调用:

```go
// 分配一个新的 pp 结构体或获取一个缓存的 pp 对象。
func newPrinter() *pp {
	// 从 sync.Pool 中获取一个 pp 对象，断言为 *pp 类型
	p := ppFree.Get().(*pp)

	// 重置 pp 对象的状态
	p.panicking = false
	p.erroring = false
	p.wrapErrs = false

	// 初始化 pp 对象的 fmt 字段，传入 pp 对象的 buf 字段作为缓冲区
	p.fmt.init(&p.buf)

	return p
}
```

将使用完成的缓存对象在返回池中的通用方法,这个方法会在`fmt`使用其方法代码块的`return`之前调用:

```go
// 将已使用的 pp 结构体保存在 ppFree 中，避免每次调用都进行内存分配。
func (p *pp) free() {
	// 使用 sync.Pool 需要确保每个存储的条目大致具有相同的内存成本。
	// 当存储的类型包含一个大小可变的缓冲区时，为了满足这个属性，
	// 我们对可以放回池中的最大缓冲区添加了一个硬限制。
	// 如果缓冲区大于限制，则丢弃缓冲区只回收打印机。
	//
	// 参见 https://golang.org/issue/23199
	if cap(p.buf) > 64*1024 {
		p.buf = nil // 如果缓冲区超过限制大小，直接置空
	} else {
		p.buf = p.buf[:0] // 否则将缓冲区重置为长度为 0
	}

	// 如果 wrappedErrs 缓冲区容量大于 8，则置空
	if cap(p.wrappedErrs) > 8 {
		p.wrappedErrs = nil
	}

	// 重置 pp 对象的相关字段，准备复用
	p.arg = nil
	p.value = reflect.Value{}
	p.wrappedErrs = p.wrappedErrs[:0] // 恢复 wrappedErrs 缓冲区长度为 0

	// 将 pp 对象放回到 sync.Pool 中进行复用
	ppFree.Put(p)
}
```



**`fmt`使用`sycn.Pool`的方式:**

`fmt.Fprintf()`:

```go
// Fprintf 根据格式说明符进行格式化，并写入到 w 中。
// 它返回写入的字节数以及遇到的任何写入错误。
func Fprintf(w io.Writer, format string, a ...any) (n int, err error) {
	// 分配一个新的 pp 对象
	p := newPrinter()

	// 使用 doPrintf 方法对格式说明符和参数进行格式化
	p.doPrintf(format, a)

	// 将格式化后的内容写入到 w 中，记录写入的字节数和可能的写入错误
	n, err = w.Write(p.buf)

	// 释放 pp 对象以便复用
	p.free()

	return // 返回写入的字节数和可能的错误
}
```

`fmt.Sprintf()`:

```go
// Sprintf 根据格式说明符进行格式化，并返回结果字符串。
func Sprintf(format string, a ...any) string {
	// 分配一个新的 pp 对象
	p := newPrinter()

	// 使用 doPrintf 方法对格式说明符和参数进行格式化
	p.doPrintf(format, a)

	// 将格式化后的内容转换为字符串
	s := string(p.buf)

	// 释放 pp 对象以便复用
	p.free()

	return s // 返回格式化后的字符串
}
```



# 示例

```go
package main

import (
	"fmt"
	"sync"
)

var pool = &sync.Pool{
    // 可选的回调函数，当池中没有可用对象时被调用来创建新对象。
	New: func() interface{} { return "" },
}

func main() {
	for i := 0; i < 10; i++ {
        // 从 Pool 中选择任意一个项，将其从 Pool 中移除，并将其返回给调用者
		s := pool.Get().(string)
		fmt.Printf("打印从池中得到字符串对象: %v \n", s)
		s += fmt.Sprintf("%d", i)
        // 将s添加到池中。
		pool.Put(s)
	}
}
```

运行结果:

```go
打印从池中得到字符串对象:
打印从池中得到字符串对象: 0         
打印从池中得到字符串对象: 01        
打印从池中得到字符串对象: 012       
打印从池中得到字符串对象: 0123      
打印从池中得到字符串对象: 01234     
打印从池中得到字符串对象: 012345    
打印从池中得到字符串对象: 0123456   
打印从池中得到字符串对象: 01234567  
打印从池中得到字符串对象: 012345678 
```



