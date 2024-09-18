# 简介

在Go语言的垃圾回收过程中，“停止世界”（Stop-The-World, STW）是指暂停所有用户级别的goroutine执行，以便垃圾回收器可以安全地执行某些操作，如最终标记阶段或清扫阶段。

STW操作主要用于确保所有用户级别的 goroutine 暂停，以便垃圾回收器可以安全地执行标记终止阶段。

这通常发生在确认所有可达对象已经被标记，并且没有剩余的灰色对象之后。



# 源码

概括步骤:

1. 所有的协程和线程都由调度器 p 控制, 只要控制住调度器 p, 那么所有任务都会停止
2. 当前调度器 p停止, 所有空闲的调度器停止, 等待正在执行的线程, 等待执行完成之后停止调度器
3. 所有任务暂停,达到STW的状态

`src/runtime/mgc.go`

## gcMarkDone将垃圾回收从标记阶段转换到标记终止阶段

```go
// gcMarkDone 函数用于将垃圾回收从标记阶段转换到标记终止阶段，如果所有可达的对象已经被标记。
// 如果还有未标记的对象存在或未来可能有新对象产生，则将所有本地工作刷新到全局队列中，
// 使其可以被其他工作者发现并处理。
//
// 此函数应该在所有本地标记工作完成并且没有剩余工作者时被调用。具体来说，当满足以下条件时：
//
//	work.nwait == work.nproc && !gcMarkWorkAvailable(p)
//
// 调用上下文必须是可以抢占的。
//
// 刷新本地工作非常重要，因为空闲的 P 可能有本地队列中的工作。这是使这些工作可见并驱动垃圾回收完成的唯一途径。
//
// 在此函数中显式允许使用写屏障。如果它确实转换到标记终止阶段，那么所有可达的对象都已被标记，
// 因此写屏障不会再遮蔽任何对象。
func gcMarkDone() {
	...

	// 没有全局工作，没有本地工作，并且没有任何 P 通信了工作，自从获取了 markDoneSema。
	// 因此没有灰色对象，也不会有更多对象被遮蔽。转换到标记终止阶段。

	now := nanotime()                                           // 获取当前时间
	work.tMarkTerm = now                                        // 设置标记终止时间
	work.pauseStart = now                                       // 设置暂停开始时间
	getg().m.preemptoff = "gcing"                               // 设置不可抢占标志
	systemstack(func() { stopTheWorldWithSema(stwGCMarkTerm) }) // stw 停止世界

	...

	// 执行标记终止。这将重新启动世界。
	gcMarkTermination()
}
```

`gcMarkDone` 函数负责从标记阶段过渡到标记终止阶段，如果所有可达的对象都已经标记完成。

- 这里的关键点是 `stopTheWorldWithSema(stwGCMarkTerm)` 函数调用，它会暂停所有用户级别的goroutine执行。

- 这个函数调用发生在确认所有可达对象都被标记，并且没有剩余的灰色对象之后。

- 这是通过检查 `gcMarkDoneFlushed` 是否为零来实现的，如果为零，则表示没有新的灰色对象被发现，可以安全地进入标记终止阶段。

在标记终止阶段，STW是为了确保所有写屏障操作已经完成，所有的对象都已经正确地标记，并且可以安全地进入下一个阶段，如清扫阶段。

在这个阶段，垃圾回收器会停止所有用户级别的goroutine，确保没有新的写屏障操作发生，同时更新各种统计数据，并为下一轮垃圾回收做准备。



## stopTheWorldWithSemastw 停止世界

`src/runtime/proc.go`

```go
// stopTheWorldWithSema 是 Stop-The-World 停止世界机制的核心实现。
// 调用者负责先获取 worldsema 互斥锁并禁用抢占，然后调用 stopTheWorldWithSema：
//
//	semacquire(&worldsema, 0)
//	m.preemptoff = "原因"
//	systemstack(stopTheWorldWithSema)
//
// 完成后，调用者必须要么调用 startTheWorld 或者分别撤销这三个操作：
//
//	m.preemptoff = ""
//	systemstack(startTheWorldWithSema)
//	semrelease(&worldsema)
//
// 允许获取 worldsema 一次，然后执行多个 startTheWorldWithSema/stopTheWorldWithSema 对。
// 其他 P 可以在连续的 startTheWorldWithSema 和 stopTheWorldWithSema 调用之间执行。
// 持有 worldsema 会导致任何其他试图执行 stopTheWorld 的 goroutine 阻塞
func stopTheWorldWithSema(reason stwReason) {
	// 开始 STW 追踪。
	if traceEnabled() {
		traceSTWStart(reason)
	}
	gp := getg()

	// 如果持有锁，则无法阻止另一个被阻塞在获取锁上的 M。
	if gp.m.locks > 0 {
		// 抛出错误，因为持有锁时不应该调用 stopTheWorld。
		throw("stopTheWorld: holding locks")
	}

	lock(&sched.lock)              // 获取调度器锁，以确保在 STW 期间调度器状态的一致性。
	sched.stopwait = gomaxprocs    // 设置 stopwait 计数器为 gomaxprocs，表示需要停止的 P 的数量
	sched.gcwaiting.Store(true)    // 设置 gcwaiting 标志，表示正在进行垃圾回收
	preemptall()                   // 强制所有 P 预抢占，确保它们都停止
	gp.m.p.ptr().status = _Pgcstop // 将当前 P 的状态设为 _Pgcstop，表示它已停止
	sched.stopwait--

	// 尝试停止所有处于 Psyscall 状态的 P。
	for _, pp := range allp {
		s := pp.status
		// 遍历所有 P，如果一个 P 的状态为 _Psyscall（表示在系统调用中），则将其状态改为 _Pgcstop 已停止
		if s == _Psyscall && atomic.Cas(&pp.status, s, _Pgcstop) {
			if traceEnabled() {
				// 追踪系统调用阻塞。
				traceGoSysBlock(pp)
				// 追踪进程停止。
				traceProcStop(pp)
			}

			// 更新 stopwait 计数器
			pp.syscalltick++
			sched.stopwait--
		}
	}

	// 停止空闲的 P。
	now := nanotime()
	for {
		// 获取空闲的 P，并将其状态设为 _Pgcstop 已停止
		pp, _ := pidleget(now)
		if pp == nil {
			break
		}
		pp.status = _Pgcstop
		sched.stopwait--
	}

	// 如果 stopwait 大于 0，则表示还有 P 需要停止
	wait := sched.stopwait > 0
	unlock(&sched.lock)

	// 如果还需要等待，则循环等待，直到所有 P 都停止
	if wait {
		for {
			// 等待 100 微秒，然后尝试重新抢占以防止竞态条件。
			if notetsleep(&sched.stopnote, 100*1000) {
				noteclear(&sched.stopnote)
				break
			}
			preemptall() // 强制所有 P 预抢占，确保它们都停止
		}
	}

	// 如果 stopwait 不等于 0 或者有任何 P 的状态不是 _Pgcstop，则抛出错误
	bad := ""
	if sched.stopwait != 0 {
		bad = "stopTheWorld: not stopped (stopwait != 0)"
	} else {
		for _, pp := range allp {
			if pp.status != _Pgcstop {
				bad = "stopTheWorld: not stopped (status != _Pgcstop)"
			}
		}
	}

	// 如果 freezing 标志为真，则表示有线程正在 panic，此时锁定 deadlock 来阻止当前线程
	if freezing.Load() {
		lock(&deadlock)
		lock(&deadlock)
	}
	if bad != "" {
		// 如果检查失败，抛出错误。
		throw(bad)
	}

	// 调用 worldStopped，这通常是垃圾回收或其他需要 STW 的操作。
	worldStopped()
}
```

4. **抢占所有 P**:
   - 调用 `preemptall` 强制所有 P 预抢占，确保它们都停止。
5. **停止当前 P**:
   - 将当前 P 的状态设为 `_Pgcstop`，表示它已停止。
7. **停止空闲的 P**:
   - 获取空闲的 P，并将其状态设为 `_Pgcstop`。
9. **等待剩余的 P**:
   - 如果还需要等待，则循环等待，直到所有 P 都停止。
12. **调用 worldStopped**:
    - 调用 `worldStopped` 函数，通常在这个函数中会执行垃圾回收或其他需要 STW 的操作。

