# 简介

在 Go 语言中，goroutine 的退出可以通过几种不同的方式来实现，具体取决于你的需求和场景。

向一个通道发送一个值，以此来通知 goroutine 应该退出

```go
ctx, cancel := context.WithCancel(context.Background())
go func() {
    for {
        select {
        case <-ctx.Done():
            // 收到退出信号，退出循环并结束 goroutine
            return
        default:
            // 执行其他工作
        }
    }
}()
// ...
// 当需要退出时
cancel()
```



吊毛, 肯定不是说这个啊!!!



# 退出的整个过程

推出之前我们先回忆一下调用的方法:

```go
// 调度器的一个循环：找到一个可运行的 goroutine 并执行它，同时也处理了各种边界情况
// 如锁持有、自旋状态、冻结世界、调度禁用等，以维护系统的稳定性和一致性
// 该函数永不返回。
func schedule() {
	...

top:
	// 获取当前 M 的 P，并清除抢占标志
	pp := mp.p.ptr()
	...

	// 调用 findRunnable 函数寻找可运行的 goroutine，如果找不到则阻塞等待
	// 它尝试从其他 P（处理器）偷取 goroutine，从本地或全局队列中获取 goroutine，或者轮询网络。
	gp, inheritTime, tryWakeP := findRunnable()
	...

	// execute 函数是永远不会返回的，因为它通过 gogo(&gp.sched) 直接跳转到了 goroutine 的执行代码中。
	// 但是，当 goroutine 结束后，控制权回到了调度器，这通常发生在 goroutine 的执行代码中调用了 goexit 或者当 goroutine 的主函数执行完毕时。
	// 因此，尽管 execute 不会返回到 schedule，但 schedule 会不断地被调用来寻找下一个可运行的 goroutine。
	// 这就是为什么 schedule 函数看起来像是在循环，因为它会一直运行，直到程序结束或所有 goroutine 都已完成。
	// 原理是执行完成一个goroutine之后并不是直接调用销毁,而是底层继续调用goexit0退出方法, 这个退出方法会重新调用到这个 schedule 函数
	execute(gp, inheritTime) // 执行找到的 goroutine。
}
```



## goexit1非主 goroutine 退出

`runtime/proc.go`

非主 goroutine 退出, 直接调用 `runtime·goexit1`：

```go

// 完成当前 goroutine 的执行。
// 这个函数确保在 goroutine 结束前执行一些清理工作，
// 如 race detector 和 trace 的结束通知，然后调用 mcall(goexit0) 实际完成退出。
func goexit1() {
	// 如果 race detector 已启用，则通知 race detector 当前 goroutine 即将结束。
	if raceenabled {
		racegoend()
	}

	// 如果 trace 功能已启用，则通知 trace 当前 goroutine 即将结束。
	if traceEnabled() {
		traceGoEnd()
	}

	// 调用 mcall(goexit0)，这是一个低级别的调用，直接调用到汇编语言代码，
	// 这里的 goexit0 是最终完成 goroutine 退出的函数。
	// mcall 通常用于调用不需要 GC（垃圾回收）保护的函数。
	mcall(goexit0)
}
```

这里有几个关键点需要理解：

- `raceenabled` 是一个全局变量，表示是否启用了数据竞赛检测器（race detector）。如果启用，`racegoend` 函数会被调用，它会记录当前 goroutine 的结束信息，帮助 race detector 发现潜在的数据竞赛问题。
- `traceEnabled()` 是一个函数，检查是否启用了 trace 功能。如果启用，`traceGoEnd` 函数会被调用，它负责记录当前 goroutine 结束的 trace 事件。
- `mcall` 是一个运行时函数，用于调用一个不需要 GC 保护的函数。在这里，它被用来调用 `goexit0`，这是一个更低级别的函数，负责实际的 goroutine 退出操作。`mcall` 的调用跳过了 GC 的安全检查，因为它假定被调用的函数不会修改堆上的数据，因此不需要 GC 的干预。

整个过程确保了在 goroutine 结束之前，任何需要的通知和清理工作都得到了妥善处理，然后通过 `mcall(goexit0)` 来实际完成 goroutine 的退出。



## mcall函数实际完成退出

`runtime/asm_wasm.s`

这里的参数是传递过来的`goexit0`, 这里会作为会回调执行

```c
// func mcall(fn func(*g))
// 切换到 m->g0 的栈上，调用 fn(g)。
// fn 函数不应该返回，它应该调用 gogo(&g->sched) 来继续运行 g。
TEXT runtime·mcall(SB), NOSPLIT, $0-8
	// CTXT = fn
	MOVD fn+0(FP), CTXT // 将 fn 参数的值传给 CTXT

	// R1 = g.m
	MOVD g_m(g), R1 // 获取当前 Goroutine 的 m 字段的值，存放到 R1 中
	// R2 = g0
	MOVD m_g0(R1), R2 // 通过 R1 获取当前 m 的 g0 值，存放到 R2 中

	// 将状态保存在 g->sched 结构中
	MOVD 0(SP), g_sched+gobuf_pc(g)     // 保存调用者的 PC 寄存器的值到 g->sched.pc
	MOVD $fn+0(FP), g_sched+gobuf_sp(g) // 保存调用者的 SP 寄存器的值到 g->sched.sp

	// 如果 g == g0，则调用 badmcall
	Get g
	Get R2
	I64Eq
	If
		JMP runtime·badmcall(SB) // 当 g 等于 g0 时，跳转到 runtime·badmcall 函数，这通常表示错误
	End

	// 切换到 g0 的栈上
	I64Load (g_sched+gobuf_sp)(R2) // 获取 g0 的栈顶地址
	I64Const $8					   // 减去 8 以调整栈指针，为即将压入的参数预留空间
	I64Sub
	I32WrapI64                      // 将 64 位结果转换为 32 位，适用于 SP
	Set SP                          // 设置 SP 为 g0 的栈顶地址

	// 将参数设置为当前的 g
	MOVD g, 0(SP)                   // 将当前 goroutine 的地址压入栈中作为 fn 的参数

	// 切换到 g0
	MOVD R2, g                      // 将 R2（g0 的地址）存入 g，这样 g 现在指向了 g0

	// 调用 fn
	Get CTXT                        // 获取 CTXT，即 fn 函数的地址
    I32WrapI64                      // 转换为 64 位地址
    I64Load $0                      // 从 CTXT 加载 fn 函数的地址
    CALL                            // 调用 fn 函数, 到这里，就会去执行 goexit0 函数

    Get SP                          // 读取当前 SP
    I32Const $8                     // 加上 8，移除参数
    I32Add
    Set SP                          // 更新 SP

	JMP runtime·badmcall2(SB) // 跳转到 runtime·badmcall2 函数,处理意外情况
```

## goexit0退出时要执行的流程

```go
// goexit0 函数在 g0 上继续执行 goexit 流程。
func goexit0(gp *g) {
	// 获取当前 goroutine 所在的 m 对象。
	mp := getg().m
	// 获取 m 对象关联的 p 对象。
	pp := mp.p.ptr()

	// 将 gp 的状态从运行中 (_Grunning) 改为已死亡 (_Gdead)。
	casgstatus(gp, _Grunning, _Gdead)
	// 计算并添加 gp 的可扫描栈大小到 pp 的扫描控制器中，用于 GC。
	gcController.addScannableStack(pp, -int64(gp.stack.hi-gp.stack.lo))

	// 如果 gp 是系统 goroutine，则减少系统 goroutine 的计数。
	if isSystemGoroutine(gp, false) {
		sched.ngsys.Add(-1)
	}

	gp.m = nil                     // 清理 gp 的 m 字段，避免资源泄漏。
	locked := gp.lockedm != 0      // 记录 gp 是否锁定过线程。
	gp.lockedm = 0                 // 清除 gp 的 lockedm 标志。
	mp.lockedg = 0                 // 清除 m 的 lockedg 标志。
	gp.preemptStop = false         // 清除 gp 的 preemptStop 标志。
	gp.paniconfault = false        // 清除 gp 的 paniconfault 标志。
	gp._defer = nil                // 清除 gp 的 _defer 字段。
	gp._panic = nil                // 清除 gp 的 _panic 字段。
	gp.writebuf = nil              // 清除 gp 的 writebuf 字段。
	gp.waitreason = waitReasonZero // 设置 gp 的 waitreason 字段为零值。
	gp.param = nil                 // 清除 gp 的 param 字段。
	gp.labels = nil                // 清除 gp 的 labels 字段。
	gp.timer = nil                 // 清除 gp 的 timer 字段。

	// 如果启用了 GC 黑化，并且 gp 的 gcAssistBytes 大于零，则将协助信用冲销到全局池。
	if gcBlackenEnabled != 0 && gp.gcAssistBytes > 0 {
		assistWorkPerByte := gcController.assistWorkPerByte.Load()
		scanCredit := int64(assistWorkPerByte * float64(gp.gcAssistBytes))
		gcController.bgScanCredit.Add(scanCredit)
		gp.gcAssistBytes = 0
	}

	// 调用 dropg 函数，从当前 m 的 goroutine 列表中删除 gp。
	dropg()

	// 如果架构是 wasm，则没有线程，直接将 gp 放入 p 的自由列表并调度。
	if GOARCH == "wasm" {
		gfput(pp, gp)
		schedule() // 调用goexit0退出, 继续调用调度器
	}

	// 检查 m 是否锁定内部资源。
	if mp.lockedInt != 0 {
		print("invalid m->lockedInt = ", mp.lockedInt, "\n")
		throw("internal lockOSThread error")
	}
	// 将 gp 放入 p 的自由列表。
	gfput(pp, gp)
	// 如果 gp 锁定了线程，则需要特殊处理。
	if locked {
		// 如果不是 Plan9 系统，返回到 mstart，释放 P 并退出线程。
		if GOOS != "plan9" {
			gogo(&mp.g0.sched)
		} else {
			// 对于 Plan9，清除 lockedExt 标志，可能重新使用此线程。
			mp.lockedExt = 0
		}
	}
	schedule() // 调用goexit0退出, 继续调用调度器
}
```

1. **状态更新**：首先更新 goroutine 的状态，将其标记为已死亡，并进行一些清理工作，如更新 GC 相关的信息和计数器。
2. **资源释放**：释放 gp 所持有的资源，包括但不限于 m、_defer、_panic 等字段的清理，以及 gcAssistBytes 的重置。
3. **从 m 的 goroutine 列表中移除 gp**：调用 `dropg` 函数，从当前 m 的 goroutine 列表中移除 gp。
4. **处理特殊架构**：如果架构是 WebAssembly，则直接将 gp 放入 p 的自由列表并运行调度器。
5. **处理锁定的线程**：如果 gp 在退出前锁定了线程，则进行特殊处理，这可能意味着需要释放资源并退出线程，而不是返回到线程池。
6. **调度器运行**：最后，调用 `schedule` 函数，这将选择下一个 goroutine 来执行，并将控制权交给调度器。`schedule` 函数不会返回，直到选择了下一个 goroutine 并开始执行。

