# 简介

Go 语言中的 `context` 包提供了一种管理 goroutine 生命周期和传递请求-scoped数据的方式。

其原理围绕着取消信号、截止时间和传递值，这些特性都是通过构建一个层次化的 Context 对象树来实现的。



# 源码分析

`src/context/context.go`

## 数据结构

context 是一个接口, 它的功能是通过调用接口方法来实现

```go
// Context 接口定义了一个上下文，用于在 API 之间传递截止时间、取消信号和其他值。
//
// Context 的方法可以被多个 goroutines 同时调用。
type Context interface {
	// Deadline 返回工作应该被取消的时间。当没有设置截止时间时，Deadline 返回 ok == false。
	Deadline() (deadline time.Time, ok bool)

	// Done 返回一个通道，如果没有创建通道, 会创建一个 chan struct{} 空通道用于取消使用。
	//
	// WithCancel 在调用 cancel 时安排 Done 被关闭；
	// WithDeadline 在截止时间过期时安排 Done 被关闭；
	// WithTimeout 在超时时安排 Done 被关闭。
	Done() <-chan struct{}

	// Err 返回 ctx 上下文是否被取消, 如果没有取消会返回一个错误
	Err() error

	// Value 返回与此上下文关联的键的值，如果没有与键关联的值，则返回 nil。
	Value(key any) any
}
```

一个空的接口实现, 主要是为了第一个基础初始化, 没有其他多余的意义

```go
// emptyCtx 实现了 Context 接口, 但是实现的方法都返回默认值, 没有超时、没有通道、没有错误、没有kv
// 它是 backgroundCtx 和 todoCtx 的基础结构。
type emptyCtx struct{}

func (emptyCtx) Deadline() (deadline time.Time, ok bool) {
	return
}

func (emptyCtx) Done() <-chan struct{} {
	return nil
}

func (emptyCtx) Err() error {
	return nil
}

func (emptyCtx) Value(key any) any {
	return nil
}
```

cancelCtx,真正的 context 接口的实现

```go
// 可以被取消。当取消时，它也会取消任何实现了 canceler 接口的子上下文。
type cancelCtx struct {
	Context                        // 上下文接口, cancelCtx需要实现接口方法
	mu       sync.Mutex            // 同步锁, 用于保护以下字段
	done     atomic.Value          // 原子操作保存通道, 创建 chan struct{} 空通道保存在这里, 用于取消
	children map[canceler]struct{} // 在第一次取消调用时设为 nil
	err      error                 // 在第一次取消调用时设置为非 nil
	cause    error                 // 在第一次取消调用时设置为非 nil
}

// &cancelCtxKey 是cancelCtx为其返回自身的键。
var cancelCtxKey int

// Value 返回与此上下文关联的键的值，如果没有与键关联的值，则返回 nil。
func (c *cancelCtx) Value(key any) any {
	// 如果 key 是 cancelCtxKey，则返回当前 cancelCtx 实例本身
	if key == &cancelCtxKey {
		return c
	}
	// 否则，调用父上下文的 Value 方法继续查找 key 的值并返回
	return value(c.Context, key)
}

// Done 返回一个通道，如果没有创建通道, 会创建一个 chan struct{} 空通道用于取消使用。
func (c *cancelCtx) Done() <-chan struct{} {
	// 尝试加载已存在的 done 通道
	d := c.done.Load()
	if d != nil {
		return d.(chan struct{})
	}

	// 以下为处理当 done 通道尚未创建时的逻辑
	c.mu.Lock()
	defer c.mu.Unlock()

	// 再次加载 done 通道，避免竞态条件
	d = c.done.Load()
	if d == nil {
		// 创建一个新的无缓冲的空通道
		d = make(chan struct{})
		// 将新的通道存储到 done 字段中
		c.done.Store(d)
	}
	
	// 返回 done 通道
	return d.(chan struct{})
}

// Err 返回 ctx 上下文是否被取消, 如果没有取消会返回一个错误
func (c *cancelCtx) Err() error {
	c.mu.Lock()

	// c.err 是在 Context 被取消时设置的
	err := c.err

	c.mu.Unlock()
	return err
}

// 用于在父上下文取消时取消子上下文。它设置 cancelCtx 的父上下文。
func (c *cancelCtx) propagateCancel(parent Context, child canceler) {
	c.Context = parent

	// 父上下文永远不会被取消
	done := parent.Done()
	if done == nil {
		return
	}

	// 父上下文已经被取消
	select {
	case <-done:
		// 子上下文也取消
		child.cancel(false, parent.Err(), Cause(parent))
		return
	default:
	}

	// 父上下文是 *cancelCtx 类型，或者是从 *cancelCtx 类型派生出来的。
	if p, ok := parentCancelCtx(parent); ok {
		p.mu.Lock()
		if p.err != nil {
			// 父上下文已经被取消
			// 子上下文也取消
			child.cancel(false, p.err, p.cause)
		} else {
			if p.children == nil {
				p.children = make(map[canceler]struct{})
			}
			p.children[child] = struct{}{}
		}
		p.mu.Unlock()
		return
	}

	// 父上下文实现了 AfterFunc 方法。
	if a, ok := parent.(afterFuncer); ok {
		c.mu.Lock()
		stop := a.AfterFunc(func() {
			child.cancel(false, parent.Err(), Cause(parent))
		})
		c.Context = stopCtx{
			Context: parent,
			stop:    stop,
		}
		c.mu.Unlock()
		return
	}

	goroutines.Add(1)
	go func() {
		select {
		case <-parent.Done():
			// 父上下文已经被取消
			// 子上下文也取消
			child.cancel(false, parent.Err(), Cause(parent))
		case <-child.Done():
		}
	}()
}

// 关闭 c.done，取消 c 的每个子上下文，如果 removeFromParent 为 true，则从父上下文的子上下文列表中移除 c。
// 如果这是首次取消 c，则将 c.cause 设置为 cause。
func (c *cancelCtx) cancel(removeFromParent bool, err, cause error) {
	// 取消上下文, 必须将 err 设置为一个真正的错误
	if err == nil {
		panic("context: internal error: missing cancel error")
	}

	if cause == nil {
		cause = err
	}

	c.mu.Lock()

	// 已经被取消
	if c.err != nil {
		c.mu.Unlock()
		return
	}

	c.err = err
	c.cause = cause

	// 加载取消通道
	d, _ := c.done.Load().(chan struct{})
	if d == nil {
		// 没有则创建一个
		c.done.Store(closedchan)
	} else {
		// 如果有直接触发关闭通道
		close(d)
	}

	// 递归取消
	for child := range c.children {
		// 注意：在持有父上下文锁的同时获取子上下文的锁。
		child.cancel(false, err, cause)
	}

	c.children = nil
	c.mu.Unlock()

	// 从父级移除
	if removeFromParent {
		removeChild(c.Context, c)
	}
}
```



## 创建一个初始化的ctx

两个方法都可以创建一个默认的初始化的 context。

### Background()

```go
// Background 返回一个非 nil 的空 Context。
// 实现了 Context 接口, 但是实现的方法都返回默认值, 没有超时、没有通道、没有错误、没有kv
func Background() Context {
	return backgroundCtx{}
}

// 一个空的context
type backgroundCtx struct{ emptyCtx }
```



### TODO()

```go
// TODO 返回一个非 nil 的空 Context。
// 实现了 Context 接口, 但是实现的方法都返回默认值, 没有超时、没有通道、没有错误、没有kv
// 当不清楚要使用哪个 Context 或者尚未可用时，代码应该使用 context.TODO。
func TODO() Context {
	return todoCtx{}
}

// 一个空的context
type todoCtx struct{ emptyCtx }
```



## 创建一个可用的ctx

主要有这4个常用的创建方法:

```golang
// 用途: 创建一个带有取消功能的 Context。
// 参数: 接收一个父 Context，通常是 Background() 或 TODO()。
// 返回值:
// ctx: 子 Context，继承自父 Context，但添加了取消功能。
// cancel: 一个函数，调用它可以取消 ctx。一旦取消，ctx.Done() 通道将被关闭。
// 示例: 你可以使用这个函数来创建一个可以被外部信号取消的 Context，这对于控制长时间运行的函数很有用。
func WithCancel(parent Context) (ctx Context, cancel CancelFunc)
```

```go
// 参数: 创建一个指定时间取消的ctx
// 返回值:
// Context: 一个子 Context，它将在 deadline 到达时自动取消。
// CancelFunc: 一个取消函数，可以在 deadline 到达前手动取消 Context。
// 示例: 当你希望一个操作在特定时间点之前完成时，可以使用这个函数来创建 Context。
func WithDeadline(parent Context, deadline time.Time) (Context, CancelFunc)
```

```go
// 用途: 创建一个带有超时限制的 Context。
// 参数: 接收一个父 Context 和一个 time.Duration 类型的 timeout。
// 返回值:
// Context: 一个子 Context，它将在 timeout 时间后自动取消。
// CancelFunc: 一个取消函数，可以在 timeout 到达前手动取消 Context。
// 示例: 当你需要对操作设置一个最大等待时间时，可以使用这个函数。
func WithTimeout(parent Context, timeout time.Duration) (Context, CancelFunc)
```

```go
// 用途: 创建一个带有附加值的 Context。
// 参数: 接收一个父 Context，一个键 key 和一个值 val。key 必须是 interface{} 类型，但在实践中通常是一个 type 或 struct 类型的指针
// 返回值: 一个子 Context，它带有附加的键/值对。可以通过 ctx.Value(key) 访问这个值。
// 示例: 当你需要在请求的生命周期内传递额外信息（如认证令牌、跟踪 ID 等）时，可以使用这个函数。
func WithValue(parent Context, key, val interface{}) Context
```



### WithCancel() 创建一个带有取消功能的ctx

```go
// WithCancel 返回具有新 Done 完成通道的 parent 的副本。
// 当调用返回的 cancel 回调函数或父上下文的 Done 完成通道被关闭时，返回上下文的 Done 完成通道会被关闭。
func WithCancel(parent Context) (ctx Context, cancel CancelFunc) {
    // 创建一个
	c := withCancel(parent)
	// 返回一个ctx上下文, 和一个关闭通道的回调
	return c, func() { c.cancel(true, Canceled, nil) }
}
```



### WithDeadline()创建一个指定时间取消的ctx

```go
// WithDeadline 返回父上下文的副本，其中截止时间调整为不晚于 d。
// 如果父上下文的截止时间已经早于 d，则 WithDeadline(parent, d) 在语义上等同于 parent。
// 返回的 Context.Done 通道在截止时间到期时关闭，当调用返回的 cancel 函数时关闭，或当父上下文的 Done 通道关闭时关闭，以先发生者为准。
func WithDeadline(parent Context, d time.Time) (Context, CancelFunc) {
	return WithDeadlineCause(parent, d, nil)
}

// WithDeadlineCause 类似于 WithDeadline，但还在截止时间超过时设置返回的 Context 的原因。
// 返回的 CancelFunc 不设置原因。
func WithDeadlineCause(parent Context, d time.Time, cause error) (Context, CancelFunc) {
	// 初始化的 ctx 不能为 nil
	if parent == nil {
		panic("cannot create context from nil parent")
	}

	// 当前截止时间已经早于新的截止时间。
	if cur, ok := parent.Deadline(); ok && cur.Before(d) {
		return WithCancel(parent) // 返回一个正常的ctx
	}

	c := &timerCtx{
		deadline: d,
	}

	// 用于在父上下文取消时取消子上下文。它设置 cancelCtx 的父上下文。
	c.cancelCtx.propagateCancel(parent, c)
	dur := time.Until(d)
	// 截止时间已经过期
	if dur <= 0 {
		// 关闭ctx
		c.cancel(true, DeadlineExceeded, cause) // deadline has already passed
		return c, func() { c.cancel(false, Canceled, nil) }
	}

	c.mu.Lock()
	defer c.mu.Unlock()
	if c.err == nil {
		c.timer = time.AfterFunc(dur, func() {
			c.cancel(true, DeadlineExceeded, cause)
		})
	}
	
	return c, func() { c.cancel(true, Canceled, nil) }
}
```

### WithTimeout()创建一个带有超时限制的ctx

```go
// WithTimeout 创建一个带有超时限制的 Context。
// 实际上就是调用 WithDeadline 指定时间取消的ctx, 将指定的时间控制为我们要设置的超时的那个时间点
func WithTimeout(parent Context, timeout time.Duration) (Context, CancelFunc) {
	return WithDeadline(parent, time.Now().Add(timeout))
}
```

### WithValue()创建一个带有附加值的ctx

```go
// WithValue 创建一个子上下文, 包括k-v的键值对。
// 最终的上下文是一个链的形式, 每个子上下文都有一个父级上下文
// 根节点就是 backgroundCtx / todoCtx
func WithValue(parent Context, key, val any) Context {
	// 无法从 nil 父上下文创建上下文
	if parent == nil {
		panic("cannot create context from nil parent")
	}

	// nil 键
	if key == nil {
		panic("nil key")
	}

	// 因为对 key 的要求是可比较，因为之后需要通过 key 取出 context 中的值，可比较是必须的。
	if !reflectlite.TypeOf(key).Comparable() {
		panic("key is not comparable")
	}

	// 传入父上下文,和当前的k-v
	// 最终的value上下文是一个链的形式, 每个子上下文都有一个父级上下文
	// 根节点就是 backgroundCtx / todoCtx
	return &valueCtx{parent, key, val}
}
```

