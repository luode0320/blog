# 简介

在 Go 语言中，`context` 是一个用于携带**截止时间、取消信号、携带任意类型的数据**的包。

它主要用于组织和控制在 goroutine 之间的函数调用，特别是在处理长时间运行的请求或异步操作时，它可以帮助你优雅地取消这些操作，避免资源泄漏。

随着 context 包的引入，标准库中很多接口因此加上了 context 参数。

context 几乎成为了并发控制和超时控制的标准做法。

# 主要类型

`context` 包提供了几种主要的类型：

1. **`context.Context`**: 这是一个接口，定义了所有 `context`
   类型必须实现的方法。这些方法包括 `Done()`，`Err()`，`Value(key interface{}) interface{}` 等。
2. **`context.Background()`**: 返回一个空的 Context，通常用于初始化顶层的 Context, **经常作为下面的 parent 参数使用**。
3. **`context.TODO()`**: 与 `Background()` 类似，但是表示缺少 Context 的情况，通常用于测试或调试。
4. **`context.WithCancel(parent Context)`**: 返回一个子 Context 和一个 Cancel 回调函数，可以调用 Cancel 回调函数来取消子
   Context。
5. **`context.WithDeadline(parent Context, deadline time.Time)`**: 返回一个子 Context，该 Context 将在指定的截止时间后自动取消。
6. **`context.WithTimeout(parent Context, timeout time.Duration)`**: 类似于 `WithDeadline`，但在给定的时间间隔后取消
   Context。

使用 `context` 的一个常见模式是创建一个带有取消功能的 Context，然后将这个 Context 传递给可能运行很长时间的函数。

如果需要取消这个操作，可以调用返回的 Cancel 回调函数。

# 示例

这是一个优雅的退出 goroutine 的方式

```go
package main

import (
	"context"
	"fmt"
	"time"
)

// 传递一个上下文携带截止时间、取消信号
func doSomething(ctx context.Context) {
	// 定时器: 100ms 一次
	ticker := time.NewTicker(100 * time.Millisecond)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			fmt.Println("滴答定时器...")
		case <-ctx.Done():
			fmt.Println("goroutine 操作已取消.")
			return
		}
	}
}

func main() {
	// 返回一个子 Context 和一个 cancel 回调函数，可以调用 cancel 回调函数来取消子 Context
	ctx, cancel := context.WithCancel(context.Background())
	go doSomething(ctx)

	// 等待一段时间，然后取消 Context
	time.Sleep(500 * time.Millisecond)
	// 取消: 表示停止
	cancel()

	// 程序会在这里等待 doSomething 函数返回，但它会因为取消而提前返回
	fmt.Println("主要功能已完成.")
}
```

在这个示例中:

- `doSomething` 函数会每 100 毫秒打印一次 "Tick..."，直到 Context 被取消。
- 在 `main` 函数中，我们创建了一个带有取消功能的 Context，并在 500 毫秒后调用了 `cancel` 函数，导致 `doSomething` 函数提前退出。
- 这展示了如何使用 `context` 来优雅地管理长时间运行的 goroutine 的生命周期。