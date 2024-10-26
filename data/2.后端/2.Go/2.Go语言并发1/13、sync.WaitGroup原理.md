# 简介

`sync.WaitGroup` 的原理是基于计数器的控制机制。

- 当你调用 `Add` 方法增加计数时，`WaitGroup` 的内部计数器就会增加。
- 每个调用 `Add` 方法都应该对应一个后续调用 `Done` 方法，以便减小计数。
- 而调用 `Wait` 方法会阻塞当前 Goroutine，直到内部计数器减为零。

通过这种方式，`sync.WaitGroup` 提供了一种简单而有效的机制，在主 Goroutine 中等待多个 Goroutine 完成其任务。

确保对 `Add` 和 `Done` 方法进行正确匹配，以避免计数器出现负值的情况。这样可以确保正确地控制 Goroutine 的并发执行，以及在合适的时机等待它们完成。



# 源码解析

`src/sync/waitgroup.go`

## 数据结构

```go
// WaitGroup 用于等待一组 Goroutine 完成。
// 主 Goroutine 调用 Add 方法设置需要等待的 Goroutine 数量。
// 然后每个 Goroutine 运行并在完成时调用 Done。
// 同时，可以使用 Wait 阻塞，直到所有 Goroutine 完成。
//
// WaitGroup 在首次使用后不得被复制。
type WaitGroup struct {
	noCopy noCopy        // 用于禁止 WaitGroup 被复制。
	state  atomic.Uint64 // 高 32 位为计数器，低 32 位为等待者计数, 原子操作
	sema   uint32        // 用于唤醒或者阻塞的信号
}
```



## Add()添加任务数量

```go
// Add 方法允许动态地添加任务数量。
// 注意，Add 必须在调用 Wait 之后调用，否则会导致 panic。
// 如果 Add 中的参数是负值，则表示正在完成一个任务。
// 如果 Add 中的参数是正值，则表示正在添加一个新的任务。
// 如果 Add 中的参数是零值，则没有影响。
func (wg *WaitGroup) Add(delta int) {
	// 开启竞态
	if race.Enabled {
		if delta < 0 {
			// 同步减少操作与 Wait。
			race.ReleaseMerge(unsafe.Pointer(wg))
		}
		race.Disable()
		defer race.Enable()
	}

	// 更新并获取当前 WaitGroup 的状态: 高 32 位为计数器，低 32 位为等待者计数
	state := wg.state.Add(uint64(delta) << 32)
	v := int32(state >> 32) // 高 32 位为计数器
	w := uint32(state)      // 低 32 位为等待者计数

	// 对竞态的增量情况进行检查
	if race.Enabled && delta > 0 && v == int32(delta) {
		// 第一个增量必须与 Wait 同步。
		// 需要将其建模为读取，因为可以有几个并发的 wg.counter 从 0 过渡。
		race.Read(unsafe.Pointer(&wg.sema))
	}

	// 检查计数器是否为负数
	if v < 0 {
		panic("sync: negative WaitGroup counter")
	}
	// 检查是否存在并发调用 Add 和 Wait 的情况
	if w != 0 && delta > 0 && v == int32(delta) {
		panic("sync: WaitGroup misuse: Add called concurrently with Wait")
	}

	// 如果计数器已经完成任务或等待计数器为零，直接返回
	// 1.如果计数器 v > 0: 表示还有任务, 不能唤醒等待的 goroutine
	// 2.如果等待计数器 w = 0: 表示没有可以唤醒的等待的 goroutine
	// 都可以直接返回
	if v > 0 || w == 0 {
		return
	}

	// 走到这里说明, 所有任务完成, 准备唤醒等待的 goroutine

	// 检查是否存在并发调用 Add 和 Wait 的情况
	if wg.state.Load() != state {
		panic("sync: WaitGroup misuse: Add called concurrently with Wait")
	}

	// 重置等待者数量为 0，并唤醒阻塞的 Goroutine
	wg.state.Store(0)
	for ; w != 0; w-- {
		runtime_Semrelease(&wg.sema, false, 0) // 唤醒被 wait 阻塞的 goroutine
	}
}
```

## Done()减少任务数量

```go
// Done 将WaitGroup计数器递减1。
func (wg *WaitGroup) Done() {
	wg.Add(-1)
}
```



##  Wait()阻塞直到计数器为零

```go
// Wait 方法阻塞直到 WaitGroup 计数器变为零。
func (wg *WaitGroup) Wait() {
	// 禁用竞态检查
	if race.Enabled {
		race.Disable()
	}

	for {
		// 获取当前 WaitGroup 的状态
		state := wg.state.Load()
		v := int32(state >> 32) // 高 32 位为计数器
		w := uint32(state)      // 低 32 位为等待者计数

		// 计数器为 0，无需等待
		if v == 0 {
			if race.Enabled {
				race.Enable()
				race.Acquire(unsafe.Pointer(wg))
			}
			return
		}

		// CAS 增加等待者数量
		if wg.state.CompareAndSwap(state, state+1) {
			if race.Enabled && w == 0 {
				// Wait 必须与第一个 Add 同步。
				// 需要将其建模为对非法数量读取来与 Add 中的读取竞争。
				// 因此，只对第一个等待者进行写入，
				// 否则并发的等待将相互竞争。
				race.Write(unsafe.Pointer(&wg.sema))
			}

			runtime_Semacquire(&wg.sema) // 阻塞当前 goroutine, 等待 Add/Done 方法唤醒

			// 在等待返回之前，WaitGroup被重用, 报错
			if wg.state.Load() != 0 {
				panic("sync: WaitGroup is reused before previous Wait has returned")
			}

			// 开启竞态检查
			if race.Enabled {
				race.Enable()
				race.Acquire(unsafe.Pointer(wg))
			}
			return
		}
	}
}
```