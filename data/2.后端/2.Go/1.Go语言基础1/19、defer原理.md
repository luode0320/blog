# 简介

Go 语言中的 `defer` 关键字用于延迟函数调用，通常用于确保某些清理或资源释放操作在周围函数返回前被执行。

# 基本语法

`defer` 语句的基本形式如下：

Go浅色版本

```go
defer f(args...)
```

这里 `f` 是要延迟调用的函数，`args...` 是传递给函数的参数。

# 工作流程

1. 声明 `defer` 语句
    - 当你在一个函数中声明 `defer` 语句时，Go 运行时会为这个 `defer` 分配一个栈上的结构体，这个结构体包含了要调用的函数、传递给函数的参数以及其他必要的信息。
2. 延迟队列的管理
    - Go 运行时维护了一个延迟队列，每当一个 `defer` 语句被声明时，它就会被添加到这个队列中。
3. 函数返回时执行 `defer`
    - 当周围的函数返回时，Go 运行时会检查是否有延迟调用，并按照逆序执行它们。
    - 在执行 `defer` 语句之前，Go 运行时会保存当前函数的栈帧状态，以便稍后恢复。
    - 每个 `defer` 语句都被执行，直到队列为空。
4. 恢复上下文
    - 所有的 `defer` 调用完成后，Go 运行时会恢复原来的函数上下文，并继续执行后续的操作。

# 源码

`src/runtime/runtime2.go`

## 数据结构

```go
// _defer 结构体用来存储一个被延迟调用的函数条目。
// 如果在这个结构体中添加新的字段，请确保在 deferProcStack 函数中也添加相应的清理代码。
// 这个结构体必须与 cmd/compile/internal/ssagen/ssa.go 文件中的 deferstruct 和 state.call 函数保持一致。
// 一些 _defer 实例会被分配在栈上，而另一些则会分配在堆上。
// 所有的 _defer 实例都属于栈的一部分，因此不需要写屏障来初始化它们。
// 所有的 _defer 实例都需要手动扫描，并且对于堆上的 _defer 实例，需要进行标记。
type _defer struct {
	started bool // 表示该延迟调用是否已经开始执行。
	heap    bool // 表示该 _defer 实例是否分配在堆上。
	// 表示这个 _defer 是为包含开放编码（即内联编码）的延迟调用的函数帧准备的。
	// 我们只为整个帧保留一个 _defer 记录（该帧可能当前有 0 个、1 个或者多个活跃的延迟调用）。
	openDefer bool    // 表示该 _defer 是否为一个带有开放编码延迟调用的帧。
	sp        uintptr // 当前延迟调用发生时的栈指针（sp）。
	pc        uintptr // 当前延迟调用发生时的程序计数器（pc）。
	fn        func()  // 被延迟调用的函数，可以为 nil，如果使用了开放编码的延迟调用。
	_panic    *_panic // 当前正在执行延迟调用的 panic 结构体，如果是 nil 则表示没有 panic。
	link      *_defer // 指向同一个 goroutine 中下一个 _defer 结构体的指针；它可以指向栈上或堆上的 _defer！

	// 如果 openDefer 为 true，则下面的字段记录了与包含开放编码延迟调用的栈帧及其关联函数相关的值。
	fd   unsafe.Pointer // funcdata 指针，指向与该帧关联的函数的函数数据。
	varp uintptr        // varp 的值，varp 是栈帧中的一个指针，指向函数局部变量的开始。
	// 是与栈帧关联的当前程序计数器（pc）。
	// 通过 framepc/sp 可以继续追踪栈帧，以完成栈跟踪。
	framepc uintptr
}
```

```go
// _panic 结构体用来存储关于一个活跃的 panic 的信息。
//
// _panic 值只能存在于栈上。
//
// argp 和 link 字段是栈指针，但是它们不需要特别的处理来进行栈增长：
// 因为它们是指针类型，并且 _panic 值只存在于栈上，
// 所以常规的栈指针调整就能正确处理它们。
type _panic struct {
	argp      unsafe.Pointer // 当 panic 发生时，此指针指向延迟调用的参数。
	arg       any            // 这个参数通常是一个错误或异常对象，用来描述发生了什么问题。
	link      *_panic        // 指向前一个 panic 的链接,这形成了一条链表，用来记录在当前 goroutine 中发生的 panic 序列。
	pc        uintptr        // 表示如果此 panic 被绕过（例如通过 recover），则应该返回到 runtime 中的位置。
	sp        unsafe.Pointer // 如果此 panic 被绕过（例如通过 recover），则返回到 runtime 的栈指针
	recovered bool           // 表示此 panic 是否已经被处理。如果 recover 成功，则将此字段设置为 true。
	aborted   bool           // 表示此 panic 是否被中止。如果在 panic 处理过程中发生了其他 panic，那么当前的 panic 可能会被中止。
	goexit    bool           // 如果一个 panic 没有被捕获，并且一直传播到了 goroutine 的顶层，那么这个 goroutine 将会退出。
}
```

## 关键方法

- `deferproc()`: 编译器将 defer 语句转换为对此函数的调用, 从堆中分配
    - `newdefer()`: 分配一个 Defer 结构体, 从堆中分配
- `deferprocStack()`: 编译器将 defer 语句转换为对此函数的调用, 从栈中分配(99%的情况下)

- `deferreturn()`: 编译器会在任何调用了 defer 的函数末尾插入对该函数的调用。

## deferproc() 创建一个defer, 从堆中分配

```go
// 创建一个新的延迟函数 fn，该函数没有参数和结果。
// 编译器将 defer 语句转换为对此函数的调用。
func deferproc(fn func()) {
	// 获取当前 goroutine 的 g 结构体。
	gp := getg()

	// 如果当前 goroutine 不是当前正在运行的 goroutine，则抛出异常。
	if gp.m.curg != gp {
		throw("defer on system stack")
	}

	// 创建一个新的延迟调用记录。
	d := newdefer()

	// 检查新创建的延迟调用记录是否意外地包含了非 nil 的 panic 结构体。
	if d._panic != nil {
		throw("deferproc: d.panic != nil after newdefer")
	}

	d.link = gp._defer   // 将新创建的延迟调用记录链接到当前 goroutine 的延迟调用链表。
	gp._defer = d        // 更新当前 goroutine 的延迟调用链表头。
	d.fn = fn            // 设置延迟调用记录中的函数。
	d.pc = getcallerpc() // 获取调用 deferproc 的函数的程序计数器。

	// 获取调用 deferproc 的函数的栈指针。
	// 必须在调用 getcallersp 和存储结果到 d.sp 之间避免抢占，
	// 因为 getcallersp 的结果是一个 uintptr 类型的栈指针。
	d.sp = getcallersp()

	// 正常情况下是返回0，然后执行defer后面的逻辑，最后在f中执行return时调用deferreturn
	// 异常情况下（panic-recover）返回1，直接执行deferreturn
	return0()
	// 此处不能有代码，因为 C 语言的返回寄存器已经被设置，不能被覆盖
}
```

1. **获取当前 goroutine 的 g 结构体**:
    - 使用 `getg()` 函数获取当前 goroutine 的 `g` 结构体。
2. **检查是否在系统栈上执行 defer**:
    - 如果当前 goroutine 不是当前正在运行的 goroutine，则说明 defer 语句是在系统栈上执行的，这种情况下无法支持 defer
      语句，因此抛出异常。
3. **创建一个新的延迟调用记录**:
    - 使用 `newdefer()` 函数创建一个新的延迟调用记录。
4. **检查新创建的延迟调用记录是否意外地包含了非 nil 的 panic 结构体**:
    - 如果新创建的延迟调用记录中包含了非 nil 的 `_panic` 结构体，则抛出异常。
5. **更新延迟调用链表**:
    - 将新创建的延迟调用记录链接到当前 goroutine 的延迟调用链表，并更新当前 goroutine 的延迟调用链表头。
6. **设置延迟调用记录中的函数**:
    - 设置延迟调用记录中的 `fn` 字段为传入的 `fn` 函数。
7. **获取调用 deferproc 的函数的程序计数器**:
    - 使用 `getcallerpc()` 函数获取调用 deferproc 的函数的程序计数器。
8. **获取调用 deferproc 的函数的栈指针**:
    - 使用 `getcallersp()` 函数获取调用 deferproc 的函数的栈指针。
9. **返回 0**:
    - 使用 `return0()` 函数返回 0。如果延迟函数阻止了 panic，则 deferproc 返回 1。
10. **禁止在此处添加代码**:
    - 此处不能有代码，因为 C 语言的返回寄存器已经被设置，不能被覆盖。

### newdefer() 分配一个 Defer 结构体, 从堆中分配

```go
// 分配一个 Defer 结构体，通常使用每个 P 的局部缓存池, 从堆中分配
// 每个分配的 defer 都必须通过 freedefer 进行释放。此时 defer 并未加入任何 defer 链表中。
func newdefer() *_defer {
	var d *_defer
	mp := acquirem() // 获取一个 m 结构体用于访问 P 结构体。
	pp := mp.p.ptr() // 获取当前 m 结构体关联的 P 结构体。

	// 如果当前 P 的 defer 缓存池为空并且调度器的 defer 缓存池不为空，则从调度器的 defer 缓存池获取 defer。
	if len(pp.deferpool) == 0 && sched.deferpool != nil {
		// 加锁以保护共享 defer 缓存池。
		lock(&sched.deferlock)

		// 当前 P 的 defer 缓存池数量少于其容量的一半时，尝试从调度器的 defer 缓存池中取出 defer。
		for len(pp.deferpool) < cap(pp.deferpool)/2 && sched.deferpool != nil {
			d := sched.deferpool
			sched.deferpool = d.link               // 将调度器 defer 缓存池的头部指向下一个 defer。
			d.link = nil                           // 将取出的 defer 的 link 设为 nil，表示它不再链接到任何链表。
			pp.deferpool = append(pp.deferpool, d) // 将取出的 defer 加入当前 P 的 defer 缓存池。
		}

		// 解锁。
		unlock(&sched.deferlock)
	}

	// 从当前 P 的 defer 缓存池中取出一个 defer。
	if n := len(pp.deferpool); n > 0 {
		d = pp.deferpool[n-1]
		pp.deferpool[n-1] = nil
		// 从 defer 缓存池中移除最后一个 defer。
		pp.deferpool = pp.deferpool[:n-1]
	}

	releasem(mp)      // 释放 m 结构体以便其他 goroutine 可以使用。
	mp, pp = nil, nil // 清除对 m 和 p 的引用以避免内存泄漏。

	// 如果当前 P 的 defer 缓存池为空，则分配一个新的 defer。
	if d == nil {
		// Allocate new defer.
		d = new(_defer)
	}
	// 标记 defer 是从堆中分配的（即使是从缓存池获取的）。
	d.heap = true
	// 返回分配好的 defer。
	return d
}
```

1. **获取一个 m 结构体**:
    - 使用 `acquirem()` 函数获取一个 m 结构体，这允许我们访问与之关联的 P 结构体。
2. **获取当前 P 结构体**:
    - 使用 `mp.p.ptr()` 获取当前 m 结构体关联的 P 结构体。
3. **从调度器的 defer 缓存池获取 defer**:
    - 如果当前 P 的 defer 缓存池为空并且调度器的 defer 缓存池不为空，则从调度器的 defer 缓存池获取 defer。
    - 使用 `lock` 和 `unlock` 函数来保护共享的 defer 缓存池。
4. **从当前 P 的 defer 缓存池获取 defer**:
    - 如果当前 P 的 defer 缓存池不为空，则从缓存池中取出一个 defer。
5. **释放 m 结构体**:
    - 使用 `releasem()` 函数释放 m 结构体，以便其他 goroutine 可以使用。
6. **分配新的 defer**:
    - 如果当前 P 的 defer 缓存池为空，则分配一个新的 defer。
7. **标记 defer 来源**:
    - 将 `d.heap` 字段设为 `true` 表示这个 defer 是从堆中分配的（即使是从缓存池获取的）。
8. **返回 defer**:
    - 返回分配好的 defer。

## deferprocStack() 创建一个defer, 从栈上分配

```go
// 在栈上排队一个新延迟执行的函数。
// 该函数接收一个已经在栈上分配好的 _defer 结构体作为参数。
// 参数 d 的 fn 字段应该已经被初始化。
// 使用 nosplit 标记是因为栈上的指针字段未初始化。
//
//go:nosplit
func deferprocStack(d *_defer) {
	// 获取当前 goroutine 的状态信息。
	gp := getg()

	// 如果当前 goroutine 不是正在执行的 goroutine，则抛出异常。
	// 这意味着不能在系统栈上进行延迟调用。
	if gp.m.curg != gp {
		throw("defer on system stack")
	}

	// 初始化 _defer 结构体中的一些字段。
	// 注意：fn 字段已经由调用者初始化。
	d.started = false    // 表示延迟调用是否已经开始执行。
	d.heap = false       // 标记该结构体是在栈上分配的。
	d.openDefer = false  // 表示这不是一个开放的延迟调用。
	d.sp = getcallersp() // 获取调用者的栈指针。
	d.pc = getcallerpc() // 获取调用者的程序计数器。
	d.framepc = 0        // 调用者函数的帧地址（对于栈上分配不重要）。
	d.varp = 0           // 变量的地址（对于栈上分配不重要）。

	// 下面的代码使用了 *(*uintptr) 指针来间接修改结构体中的字段。
	// 这是为了避免触发写屏障(write barrier)，因为这些字段都位于栈上，
	// 并且在进入 deferprocStack 时还未经初始化。

	// 初始化 _defer 结构体中的 panic 字段。
	// 由于这是栈上的数据，无需触发写屏障。
	*(*uintptr)(unsafe.Pointer(&d._panic)) = 0

	// 初始化 _defer 结构体中的 fd 字段（用于保存文件描述符等信息）。
	// 由于这是栈上的数据，无需触发写屏障。
	*(*uintptr)(unsafe.Pointer(&d.fd)) = 0

	// 初始化 _defer 结构体中的 link 字段，指向当前 goroutine 的 _defer 链表。
	// 由于这是栈上的数据，无需触发写屏障。
	*(*uintptr)(unsafe.Pointer(&d.link)) = uintptr(unsafe.Pointer(gp._defer))

	// 更新当前 goroutine 的 _defer 链表，将新创建的 _defer 结构体添加进去。
	// 由于我们显式地标记所有 _defer 结构体，因此无需触发写屏障。
	*(*uintptr)(unsafe.Pointer(&gp._defer)) = uintptr(unsafe.Pointer(d))

	// 返回0() 是一个空操作，用于确保 C 语言返回寄存器被设置，防止之后的代码覆盖它。
	// 注意：这里不允许有任何其他代码，因为 C 语言返回寄存器已经被设置，不能被破坏。
	return0()
	// 此处不能有代码，因为 C 语言的返回寄存器已经被设置，不能被覆盖
}
```

## deferreturn() 执行defer的函数

```go
// 为调用者的帧运行延迟调用的函数。
// 编译器会在任何调用了 defer 的函数末尾插入对该函数的调用。
func deferreturn() {
	// 获取当前 goroutine 的 g 结构体。
	gp := getg()

	// 循环处理延迟调用。
	for {
		// 获取当前 goroutine 的第一个延迟调用记录。
		d := gp._defer
		// 如果延迟调用记录为空，则结束循环。
		if d == nil {
			return
		}

		// 获取调用者函数的栈指针。
		sp := getcallersp()

		// 如果延迟调用记录中的栈指针与当前函数的栈指针不匹配，则说明当前延迟调用记录不属于当前函数，因此结束循环
		if d.sp != sp {
			return
		}

		// 如果延迟调用记录使用了开放编码（即内联编码）。
		if d.openDefer {
			// 执行开放编码的延迟调用。
			done := runOpenDeferFrame(d)
			// 如果没有完成所有开放编码的延迟调用，则抛出异常。
			if !done {
				throw("unfinished open-coded defers in deferreturn")
			}
			// 更新当前 goroutine 的延迟调用记录链表。
			gp._defer = d.link
			// 释放当前延迟调用记录。
			freedefer(d)
			// 如果该帧使用开放编码的延迟调用，则这必须是该帧唯一的延迟调用记录，
			// 因此可以结束循环。
			return
		}

		// 执行延迟调用。
		fn := d.fn         // 获取要执行的函数。
		d.fn = nil         // 清除函数指针，避免重复执行。
		gp._defer = d.link // 更新当前 goroutine 的延迟调用记录链表。使其指向下一个延迟调用记录
		freedefer(d)       // 释放当前延迟调用记录。释放后，该延迟调用记录不可再使用
		fn()               // 执行延迟调用函数。
	}
}
```

1. **将延迟调用记录的链接字段设置为 nil**:
    - 将 `d.link` 设置为 `nil`，以避免可能的引用循环。
2. **释放与延迟调用相关的 panic 结构体**:
    - 如果延迟调用记录中包含 `_panic` 结构体，则调用 `freedeferpanic` 函数来释放它。
3. **释放与延迟调用相关的函数**:
    - 如果延迟调用记录中包含 `fn` 字段，则调用 `freedeferfn` 函数来释放它。
4. **检查延迟调用记录是否分配在堆上**:
    - 如果延迟调用记录不是分配在堆上，则直接返回，因为它不需要额外的释放操作。
5. **获取 m 结构体**:
    - 调用 `acquirem` 函数来获取一个 `m` 结构体，用于访问 P 结构体。
6. **获取当前 P 结构体的指针**:
    - 调用 `mp.p.ptr()` 来获取当前 P 结构体的指针。
7. **检查 P 结构体的延迟调用池是否已满**:
    - 如果 P 结构体的延迟调用池已满，则将一半的本地缓存转移到中心缓存。
8. **锁定延迟调用池的互斥锁**:
    - 使用 `lock` 函数锁定延迟调用池的互斥锁。
9. **将本地缓存的延迟调用记录连接到中心缓存**:
    - 将本地缓存的延迟调用记录连接到中心缓存。
10. **解锁延迟调用池的互斥锁**:
    - 使用 `unlock` 函数解锁延迟调用池的互斥锁。
11. **清空延迟调用记录的内容**:
    - 使用 `*d = _defer{}` 清空延迟调用记录的内容。
12. **将延迟调用记录添加回 P 结构体的延迟调用池**:
    - 使用 `append` 函数将延迟调用记录添加回 P 结构体的延迟调用池。
13. **释放 m 结构体**:
    - 使用 `releasem` 函数释放 m 结构体。
14. **释放局部变量，避免内存泄漏**:
    - 将 `mp` 和 `pp` 设置为 `nil`，以避免内存泄漏。

### runOpenDeferFrame() 运行指定延迟调用

```go
// runOpenDeferFrame 运行指定帧中的活动开放编码(defer)的延迟调用。
// 它通常会处理帧中所有活动的延迟调用，但如果某个延迟调用成功地捕获了一个 panic，则会立即停止。
// 如果帧中没有剩余的延迟调用需要运行，则返回 true。
func runOpenDeferFrame(d *_defer) bool {
	var done bool = true // 默认情况下认为所有延迟调用都已经处理完毕。
	fd := d.fd           // 获取函数数据指针。

	// 读取延迟调用位图的偏移量以及延迟调用的数量。
	deferBitsOffset, fd := readvarintUnsafe(fd)
	nDefers, fd := readvarintUnsafe(fd)

	// 从 varp 指针减去偏移量得到延迟调用位图。
	deferBits := *(*uint8)(unsafe.Pointer(d.varp - uintptr(deferBitsOffset)))

	// 逆序遍历延迟调用位图，从最高位到最低位。
	for i := int(nDefers) - 1; i >= 0; i-- {
		// 读取当前延迟调用的闭包偏移量。
		var closureOffset uint32
		closureOffset, fd = readvarintUnsafe(fd)

		// 如果当前位为 0，则跳过此延迟调用。
		if deferBits&(1<<i) == 0 {
			continue
		}

		// 获取当前延迟调用的闭包。
		closure := *(*func())(unsafe.Pointer(d.varp - uintptr(closureOffset)))

		// 设置当前延迟调用的函数。
		d.fn = closure

		// 清除已执行的延迟调用位。
		deferBits = deferBits &^ (1 << i)

		// 更新延迟调用位图。
		*(*uint8)(unsafe.Pointer(d.varp - uintptr(deferBitsOffset))) = deferBits

		// 获取当前 panic 结构体。
		p := d._panic

		// 调用延迟调用函数。注意这可能会改变 d.varp 如果栈发生了移动。
		deferCallSave(p, d.fn)

		// 检查是否发生了 panic 被中止的情况。
		if p != nil && p.aborted {
			break
		}

		// 清除延迟调用函数。
		d.fn = nil

		// 如果延迟调用函数成功地捕获了一个 panic，则检查是否还有剩余的延迟调用。
		if d._panic != nil && d._panic.recovered {
			done = deferBits == 0
			break
		}
	}

	return done
}
```

1. **初始化 done 变量**:
    - `done` 初始化为 `true`，表示默认情况下认为所有延迟调用都已经处理完毕。
2. **获取函数数据指针**:
    - 从传入的 `_defer` 结构体中获取 `fd`，即函数数据指针。
3. **读取延迟调用位图的偏移量和延迟调用的数量**:
    - 使用 `readvarintUnsafe` 函数读取延迟调用位图的偏移量 `deferBitsOffset` 和延迟调用的数量 `nDefers`。
4. **从 varp 指针减去偏移量得到延迟调用位图**:
    - 使用 `unsafe.Pointer` 和指针算术来获取延迟调用位图 `deferBits`。
5. **逆序遍历延迟调用位图**:
    - 从最高位到最低位遍历延迟调用位图。
6. **读取当前延迟调用的闭包偏移量**:
    - 使用 `readvarintUnsafe` 函数读取当前延迟调用的闭包偏移量 `closureOffset`。
7. **如果当前位为 0，则跳过此延迟调用**:
    - 如果当前位为 0，则表示该延迟调用尚未激活，因此跳过。
8. **获取当前延迟调用的闭包**:
    - 使用 `unsafe.Pointer` 和指针算术来获取当前延迟调用的闭包。
9. **设置当前延迟调用的函数**:
    - 将当前延迟调用的闭包赋值给 `_defer` 结构体中的 `fn` 字段。
10. **清除已执行的延迟调用位**:
    - 使用位运算符 `&^` 来清除已执行的延迟调用位。
11. **更新延迟调用位图**:
    - 使用 `unsafe.Pointer` 和指针算术来更新延迟调用位图。
12. **调用延迟调用函数**:
    - 使用 `deferCallSave` 函数调用延迟调用函数。这可能会改变 `d.varp` 如果栈发生了移动。
13. **检查是否发生了 panic 被中止的情况**:
    - 如果当前 panic 结构体不为 `nil` 且已经被中止，则跳出循环。
14. **清除延迟调用函数**:
    - 清除 `_defer` 结构体中的 `fn` 字段。
15. **检查是否还有剩余的延迟调用**:
    - 如果延迟调用函数成功地捕获了一个
      panic，则检查是否还有剩余的延迟调用需要运行。如果所有延迟调用都已经处理完毕，则设置 `done` 为 `true`。
16. **返回 done 变量**:
    - 返回 `done` 变量，指示是否所有延迟调用都已经处理完毕

# 分配在堆栈的区分

### 何时使用 `deferproc()` 从堆中分配 `_defer` 结构体

`deferproc()` 函数通常用于创建需要在堆上分配的 `_defer` 结构体。这种情况通常发生在：

1. **延迟调用的函数或参数需要逃逸到堆上**：如果延迟调用的函数或参数需要存活到函数返回之后，那么 `_defer`
   结构体需要在堆上分配，以确保其生命周期足够长。
2. **延迟调用的函数引用了函数外部的变量**
   ：如果延迟调用的函数引用了函数外部定义的变量，那么这些变量也需要存活到函数返回之后。在这种情况下，`_defer`
   结构体通常需要在堆上分配，以确保这些变量的生命周期。

### 何时使用 `deferprocStack()` 从栈上分配 `_defer` 结构体

`deferprocStack()` 函数通常用于创建可以直接在栈上分配的 `_defer` 结构体。这种情况通常发生在：

1. **延迟调用的函数不引用任何外部变量**：如果延迟调用的函数不需要引用函数外部定义的变量，那么 `_defer`
   结构体可以在栈上分配。这是因为 `_defer` 结构体仅在其所在函数返回时有效，之后就会被销毁。
2. **延迟调用的函数和参数都在函数内部定义**：如果延迟调用的函数及其参数都在函数内部定义，那么 `_defer`
   结构体可以在栈上分配。这意味着这些变量的生命周期不会超出函数范围。

### 总结

- **堆上分配**：如果延迟调用的函数或参数需要存活到函数返回之后，或者函数引用了外部变量，那么 `_defer` 结构体需要在堆上分配。
- **栈上分配**：如果延迟调用的函数和参数都在函数内部定义，并且不需要存活到函数返回之后，那么 `_defer` 结构体可以在栈上分配。

实际上一般来说只要我们不在同一个函数中写几百个`defer`都是在栈上分配的





