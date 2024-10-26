# 简介

在 Go 语言中，`recover` 函数用于捕获在当前 goroutine 中发生的 panic。

当一个 goroutine 中发生 panic 时，该 goroutine 将会终止，并且不会继续执行后续的代码。

然而，通过使用 `defer` 语句和 `recover` 函数，你可以捕获 panic 并采取适当的措施，比如清理资源、记录错误信息，或者恢复
goroutine 的正常执行。

# 基本原理

1. **Panic 发生**：
    - 当 panic 发生时，Go 运行时会遍历当前 goroutine 的所有延迟调用（`defer`），从最后声明的 `defer`
      开始执行，直到找到一个调用了 `recover` 的 `defer` 函数为止。
2. **执行延迟调用**：
    - 如果有一个 `defer` 函数调用了 `recover`，那么它会捕获当前的 panic 并返回 panic 的值（通常是 `interface{}`
      类型）。此时，该 `defer` 函数可以决定如何处理 panic，例如打印错误信息、记录错误、恢复资源等。
3. **恢复执行**：
    - 如果 `recover` 成功捕获了 panic，那么当前 goroutine 的执行将继续进行，从调用 `recover` 的 `defer` 函数之后的代码开始执行。否则，如果
      panic 没有被捕获，goroutine 将会被终止。

# 示例

```go
package main

import "fmt"

func main() {
	defer func() {
		fmt.Println("defer: 1")
	}()
	defer func() {
		fmt.Println("defer: 2")
		if r := recover(); r != nil {
			fmt.Println("在主函数 main 恢复:", r)
		}
	}()
	defer func() {
		fmt.Println("defer: 3")
	}()

	fmt.Println("调用示例.")
	example()
	fmt.Println("离开示例.")
}

func example() {
	fmt.Println("Panic!")
	panic("示例：Panic")
}
```

运行结果：

```go
调用示例.
Panic!                         
defer: 3                       
defer: 2                       
在主函数 main 恢复: 示例：Panic
defer: 1 
```

# 内部实现

在 Go 语言的内部实现中，`recover` 函数的工作机制大致如下：

1. **检查当前 goroutine 的状态**：
    - `recover` 函数首先检查当前 goroutine 是否处于 panic 状态。
2. **捕获 panic**：
    - 如果当前 goroutine 处于 panic 状态，`recover` 函数会返回 panic 的值。
3. **清除 panic 标记**：
    - 如果 `recover` 成功捕获了 panic，它会清除当前 goroutine 的 panic 标记，使得 goroutine 可以继续执行。
4. **返回 nil**：
    - 如果当前 goroutine 不处于 panic 状态，`recover` 函数返回 `nil`。

# 源码

`src/runtime/panic.go`

## gopanic发生 panic 时，这个函数会被调用

```go
// 函数实现了预声明的 panic 函数。
// 当一个 goroutine 中发生 panic 时，这个函数会被调用。
func gopanic(e any) {
	// 如果 panic 的原因 e 为 nil，则根据调试标志决定是否使用默认 PanicNilError。
	if e == nil {
		if debug.panicnil.Load() != 1 {
			e = new(PanicNilError)
		} else {
			// 如果设置了不使用默认 PanicNilError，则增加非默认 PanicNilError 的计数。
			panicnil.IncNonDefault()
		}
	}

	// 获取当前 goroutine 的状态信息。
	gp := getg()

	// 如果当前 goroutine 不是当前正在执行的 goroutine，则打印 panic 信息并抛出异常。
	// 这意味着 panic 发生在系统栈上。
	if gp.m.curg != gp {
		print("panic: ")
		printany(e)
		print("\n")
		throw("panic on system stack")
	}

	// 如果当前 goroutine 正在执行内存分配，则打印 panic 信息并抛出异常。
	if gp.m.mallocing != 0 {
		print("panic: ")
		printany(e)
		print("\n")
		throw("panic during malloc")
	}

	// 如果当前 goroutine 的抢占被禁用，则打印 panic 信息和禁用原因，并抛出异常。
	if gp.m.preemptoff != "" {
		print("panic: ")
		printany(e)
		print("\n")
		print("preempt off reason: ")
		print(gp.m.preemptoff)
		print("\n")
		throw("panic during preemptoff")
	}

	// 如果当前 goroutine 持有锁，则打印 panic 信息并抛出异常。
	if gp.m.locks != 0 {
		print("panic: ")
		printany(e)
		print("\n")
		throw("panic holding locks")
	}

	var p _panic                                        // 创建一个新的 _panic 结构体。
	p.arg = e                                           // e 通常是导致 panic 的错误或异常的值
	p.link = gp._panic                                  // 代表当前 goroutine 中发生的最新的 panic
	gp._panic = (*_panic)(noescape(unsafe.Pointer(&p))) //  p 的地址在后续操作中不会被垃圾回收器释放

	// 增加当前正在运行的 panic 的 defer 数量计数。
	runningPanicDefers.Add(1)

	// 计算当前 goroutine 的调用者 PC 和 SP，避免扫描 gopanic 函数的栈帧。
	addOneOpenDeferFrame(gp, getcallerpc(), unsafe.Pointer(getcallersp()))

	for {
		// 内部最深层的一个 defer。
		d := gp._defer
		if d == nil {
			break
		}

		// 如果 defer 已经开始执行（由之前的 panic 或 Goexit 触发），则从列表中移除。
		if d.started {
			if d._panic != nil {
				// 如果 defer 与一个 panic 相关联，则将 panic 的 aborted(是否终止) 字段设置为 true。
				d._panic.aborted = true
			}
			// 清除 defer 与 panic 的关联。
			d._panic = nil
			if !d.openDefer {
				// 对于非开放编码(defer)的 defer，需要从列表中移除。
				// 清除 defer 的 fn 字段。
				d.fn = nil
				// 更新当前 goroutine 的 _defer 指针，将其设置为 d.link，从而从列表中移除 d。
				gp._defer = d.link
				// 释放 defer 占用的资源。
				freedefer(d)
				continue
			}
		}

		// 标记 defer 为已开始执行，但仍保留在列表中，以便在执行 d.fn 之前可以找到并更新 defer 的参数帧。
		d.started = true

		// 记录正在运行 defer 的 panic。
		d._panic = (*_panic)(noescape(unsafe.Pointer(&p)))

		// 标志表示 defer 是否已完成执行。
		done := true

		if d.openDefer {
			// 如果 defer 是开放编码(defer)的，则调用 runOpenDeferFrame 函数来执行 defer。
			done = runOpenDeferFrame(d)
			if done && !d._panic.recovered {
				// 如果 defer 已完成执行且没有被 recover 捕获，则需要添加一个新的空的开放编码(defer)帧。
				addOneOpenDeferFrame(gp, 0, nil)
			}
		} else {
			// 如果 defer 不是开放编码(defer)的，则直接调用 defer 的 fn 字段所指向的函数。
			p.argp = unsafe.Pointer(getargp())
			d.fn() // 真正调用defer定义的函数
		}
		p.argp = nil

		// 如果延迟函数没有引发 panic，则移除 defer。
		if gp._defer != d {
			// 如果 gp._defer 不等于 d，则表示 defer 的状态与预期不符。
			throw("bad defer entry in panic")
		}
		// 清除 defer 与 panic 的关联。
		d._panic = nil

		// 触发栈收缩以测试栈复制。参见 stack_test.go:TestStackPanic
		// GC()

		pc := d.pc                 // 保存 defer 的 PC 和 SP 值。
		sp := unsafe.Pointer(d.sp) // 必须是指针类型，以便在栈复制期间进行调整。

		// 如果 defer 已完成执行，则执行以下操作：
		if done {
			// 清除 defer 的 fn 字段。
			d.fn = nil
			// 更新当前 goroutine 的 _defer 指针，将其设置为 d.link，从而从列表中移除 d。
			gp._defer = d.link
			// 释放 defer 占用的资源。
			freedefer(d)
		}

		// 如果 panic 被 recover 捕获，则更新 gp._panic。
		if p.recovered {
			gp._panic = p.link

			// 如果下一个 panic 是 goexit 类型且已被中止，则需要特殊处理。
			if gp._panic != nil && gp._panic.goexit && gp._panic.aborted {
				// 一个正常的 recover 会绕过/中止 Goexit。相反，
				// 我们返回到 Goexit 的处理循环。
				gp.sigcode0 = uintptr(gp._panic.sp)
				gp.sigcode1 = uintptr(gp._panic.pc)
				mcall(recovery)
				throw("bypassed recovery failed") // mcall 应该不会返回
			}

			// 减少正在运行的 panic 的 defer 数量计数。
			runningPanicDefers.Add(-1)

			// 在 recover 之后，移除任何剩余的未开始执行的、开放编码(defer)的 defer 条目。
			d := gp._defer
			var prev *_defer
			if !done {
				// 跳过当前帧（如果没有完成），它是完成 deferreturn() 中剩余 defer 所需的。
				prev = d
				d = d.link
			}
			for d != nil {
				if d.started {
					// 这个 defer 已经开始执行，但我们正处于 defer-panic-recover 的中间过程，
					// 因此不要移除它或任何进一步的 defer 条目。
					break
				}
				if d.openDefer {
					// 如果 prev 为 nil，则表示 d 是列表的第一个元素。
					if prev == nil {
						gp._defer = d.link
					} else {
						// 如果 prev 不为 nil，则表示 d 不是列表的第一个元素。
						prev.link = d.link
					}
					// 释放 defer 占用的资源。
					newd := d.link
					freedefer(d)
					// 更新 d 为下一个 defer。
					d = newd
				} else {
					// 更新 prev 为 d，即当前 defer。
					prev = d
					// 更新 d 为下一个 defer。
					d = d.link
				}
			}

			gp._panic = p.link
			// 已被标记为中止的 panic 仍然保留在 g.panic 列表中。
			// 从列表中移除它们。
			for gp._panic != nil && gp._panic.aborted {
				gp._panic = gp._panic.link
			}
			if gp._panic == nil { // 必须通过信号完成
				gp.sig = 0
			}
			// 传递有关恢复帧的信息给 recovery。
			gp.sigcode0 = uintptr(sp)
			gp.sigcode1 = pc
			mcall(recovery)          // 调用 recover 后，撤销栈并安排继续执行
			throw("recovery failed") // mcall 应该不会返回
		}
	}

	// 没有剩余的 defer 调用 - 现在进行旧式的 panic 处理。
	// 为了避免在冻结世界后调用任意用户代码的不安全性，我们在 startpanic 之前调用 preprintpanics，
	// 以便调用所有必要的 Error 和 String 方法来准备 panic 字符串。
	preprintpanics(gp._panic)

	fatalpanic(gp._panic) // 应该不会返回
	*(*int)(nil) = 0      // 不应达到此处
}
```

## gorecover 预声明的 recover 函数, mcall调用recover过程中执行

```go
// 实现预声明的 recover 函数。
// 由于需要可靠地找到调用者的栈段，因此不能分割栈。
//
// TODO(rsc): 一旦我们承诺始终使用 CopyStackAlways，
// 这个函数就不需要 nosplit 属性了。
//
//go:nosplit
func gorecover(argp uintptr) any {
	// 必须在 panic 期间作为 defer 调用的一部分运行的函数中调用。
	// 必须从最顶层的函数调用（即 defer 语句中使用的函数）中调用。
	// p.argp 是最顶层的 defer 函数调用的参数指针。
	// 与调用者报告的 argp 进行比较。
	// 如果匹配，那么调用者就是可以进行 recover 的一方。
	// 调用 getg() 获取当前 goroutine (gp)
	gp := getg()
	// 当前 goroutine 的 _panic 结构体
	p := gp._panic
	// 检查是否正在进行 goexit (!p.goexit)。
	// 检查是否已经被 recover 捕获 (!p.recovered)
	// 检查 argp 是否与 _panic 结构体中的 argp 匹配
	if p != nil && !p.goexit && !p.recovered && argp == uintptr(p.argp) {
		// 如果以上条件都满足，则将 p.recovered 设置为 true，表示 panic 已被捕获
		p.recovered = true
		// 返回 panic 时传递的值。
		return p.arg
	}
	return nil
}
```

## recovery 调用 recover 后，撤销栈并安排继续执行

```go
// 在一个 defer 函数调用 recover 后，撤销栈并安排继续执行，就好像 defer 函数的调用者正常返回一样。
func recovery(gp *g) {
	// 有关在 G 结构中传递的 defer 的信息。
	sp := gp.sigcode0
	pc := gp.sigcode1

	// d 的参数需要在栈中。
	if sp != 0 && (sp < gp.stack.lo || gp.stack.hi < sp) {
		// 如果栈指针不在 goroutine 的栈范围内，则打印错误信息并抛出异常。
		print("recover: ", hex(sp), " not in [", hex(gp.stack.lo), ", ", hex(gp.stack.hi), "]\n")
		throw("bad recovery")
	}

	// 使 deferproc 对于这个 d 再次返回，
	// 这次返回 1。调用函数将会跳转到标准返回尾声。
	gp.sched.sp = sp
	gp.sched.pc = pc
	gp.sched.lr = 0
	// 恢复支持帧指针的平台上的 bp。
	// 注意：对于不支持帧指针的平台，不设置任何值也是可以的，因为没有东西会消费它们。
	switch {
	case goarch.IsAmd64 != 0:
		// 在 x86 架构中，架构 bp 存储在栈指针下方两个字的位置。
		gp.sched.bp = *(*uintptr)(unsafe.Pointer(sp - 2*goarch.PtrSize))
	case goarch.IsArm64 != 0:
		// 在 arm64 架构中，架构 bp 指向比 sp 高一个字的位置。
		gp.sched.bp = sp - goarch.PtrSize
	}

	// 设置返回值，表示 defer 函数正常返回。
	gp.sched.ret = 1
	gogo(&gp.sched) // defer恢复执行。
}
```

