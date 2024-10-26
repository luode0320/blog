# 简介

工作线程 M 费尽心机也要找到一个可运行的 goroutine，这是它的工作和职责，不达目的，绝不罢体，这种锲而不舍的精神值得每个人学习。

共经历三个过程：先从本地队列找，定期会从全局队列找，最后实在没办法，就去别的 P 偷。如下图所示：

![image-20240615184417400](../../../picture/image-20240615184417400.png)

# 回顾调度方法

```go
	// 调用 findRunnable 函数寻找可运行的 goroutine，如果找不到则阻塞等待
	// 它尝试从其他 P（处理器）偷取 goroutine，从本地或全局队列中获取 goroutine，或者轮询网络。
	gp, inheritTime, tryWakeP := findRunnable()
	...
	// 执行找到的 goroutine。
	execute(gp, inheritTime)
```



# findRunnable寻找可运行的goroutine

这个查找的方法有点过于长了, 我先贴一个完整版, 后面再贴一个简化版

**完整版:**

```go
// 查找一个可运行的 goroutine 来执行。
// 它尝试从其他 P（处理器）偷取 goroutine，从本地或全局队列中获取 goroutine，或者轮询网络。
// tryWakeP 表示返回的 goroutine 不是普通的（例如 GC worker 或 trace reader），因此调用者应该尝试唤醒一个 P。
func findRunnable() (gp *g, inheritTime, tryWakeP bool) {
	// 从当前运行的 goroutine (getg()) 中获取其关联的 M（机器线程）
	mp := getg().m

	// 这里的条件和 handoffp 中的条件必须一致：如果 findRunnable 会返回一个 goroutine 来运行，
	// handoffp 必须启动一个 M。

top: // 标记位置，用于循环重试。
	pp := mp.p.ptr() // 获取当前 M 关联的 P。

	// 如果垃圾回收（GC）等待队列中有 goroutine，暂停当前 M。
	if sched.gcwaiting.Load() {
		gcstopm()
		goto top // 循环重试。
	}

	// 如果有安全点函数需要运行，执行它。
	if pp.runSafePointFn != 0 {
		runSafePointFn()
	}

	// 检查定时器，获取当前时间和下一个定时器到期时间。
	// 这些值用于稍后的任务窃取，确保数据的相关性。
	now, pollUntil, _ := checkTimers(pp, 0)

	// 尝试调度 trace reader 跟踪阅读器。
	if traceEnabled() || traceShuttingDown() {
		// 返回应唤醒的跟踪读取器 (如果有)
		gp := traceReader()
		if gp != nil {
			// 将 trace reader 状态改为可运行。
			casgstatus(gp, _Gwaiting, _Grunnable)
			traceGoUnpark(gp, 0)
			// 返回找到的 goroutine 和标志。
			return gp, false, true
		}
	}

	// 尝试调度 GC worker。
	if gcBlackenEnabled != 0 {
		gp, tnow := gcController.findRunnableGCWorker(pp, now)
		if gp != nil {
			// 返回找到的 GC worker。
			return gp, false, true
		}
		// 更新当前时间。
		now = tnow
	}

	// 检查全局可运行队列，确保公平性。当一个 Goroutine在某个 P 上执行时，如果因为某些原因需要放弃执行权或者被抢占
	// 那么这个 Goroutine会被放入全局可运行队列中等待被再次调度执行
	// 1.Goroutine 主动让出执行权，例如调用 runtime.Gosched() 方法；
	// 2.Goroutine 执行的时间片用完，会被放入全局队列以便重新调度；
	// 3.某些系统调用（比如阻塞的网络操作）会导致 Goroutine暂时进入全局队列。
	//
	// schedtick 刚好等于61的倍数 ,每次调度器调用时递增;
	// runqsize > 0 全局可运行队列的大小;
	if pp.schedtick%61 == 0 && sched.runqsize > 0 {
		lock(&sched.lock)
		// 尝试从全局可运行队列中获取一批G
		gp := globrunqget(pp, 1)
		unlock(&sched.lock)
		if gp != nil {
			// 返回从全局队列找到的 goroutine。
			return gp, false, false
		}
	}

	// 唤醒终结器 goroutine。
	if fingStatus.Load()&(fingWait|fingWake) == fingWait|fingWake {
		if gp := wakefing(); gp != nil {
			ready(gp, 0, true)
		}
	}

	// 如果定义了 cgo_yield 函数，调用它。
	if *cgo_yield != nil {
		asmcgocall(*cgo_yield, nil)
	}

	// 尝试从本地队列获取 goroutine。
	if gp, inheritTime := runqget(pp); gp != nil {
		// 返回从本地队列找到的 goroutine。
		return gp, inheritTime, false
	}

	// 如果全局队列不为空，尝试从中获取 goroutine。
	// 1.Goroutine 主动让出执行权，例如调用 runtime.Gosched() 方法；
	// 2.Goroutine 执行的时间片用完，会被放入全局队列以便重新调度；
	// 3.某些系统调用（比如阻塞的网络操作）会导致 Goroutine暂时进入全局队列。
	//
	// runqsize > 0 全局可运行队列的大小;
	if sched.runqsize != 0 {
		lock(&sched.lock)
		// 尝试从全局可运行队列中获取一批G
		gp := globrunqget(pp, 0)
		unlock(&sched.lock)
		if gp != nil {
			return gp, false, false
		}
	}

	// 检测网络轮询器是否已经初始化，并且当前有等待的网络轮询事件，并且上一次轮询时间不为零。
	// 这是一个优化操作，避免直接进行任务窃取。
	// 当某个 Goroutine 因为在网络操作中被阻塞而无法继续执行时，它会被放入等待网络事件的队列中，等待网络事件就绪后再次被调度执行。
	if netpollinited() && netpollWaiters.Load() > 0 && sched.lastpoll.Load() != 0 {
		// 进行非阻塞的网络轮询，获取就绪的网络事件列表。
		if list := netpoll(0); !list.empty() {
			// 从事件列表中取出一个 Goroutine 并标记为可运行状态。
			gp := list.pop()
			// 将剩余事件重新注入网络事件队列中。
			injectglist(&list)
			// 原子更新 Goroutine 的状态为可运行状态。
			casgstatus(gp, _Gwaiting, _Grunnable)
			// 如果追踪功能开启，则记录 Goroutine 的解除阻塞事件。
			if traceEnabled() {
				traceGoUnpark(gp, 0)
			}
			// 返回从网络轮询中找到的 Goroutine。
			return gp, false, false
		}
	}

	// 从其他 P 中窃取工作。
	// 限制自旋 M 的数量，以防止在高 GOMAXPROCS 下程序并行度低时过度消耗 CPU。
	// 如果当前 M 正在自旋或者当前可自旋 M 数量的两倍小于 GOMAXPROCS 减去空闲的 P 数量，
	// 则进入窃取工作的逻辑。
	if mp.spinning || 2*sched.nmspinning.Load() < gomaxprocs-sched.npidle.Load() {
		if !mp.spinning {
			// 如果当前 M 不处于自旋状态，则将其转换为自旋状态。
			mp.becomeSpinning()
		}

		// 从其他 P 中尝试窃取工作。
		// gp 为窃取到的 Goroutine，inheritTime 表示是否继承 Goroutine 的执行时间片，
		// tnow 为当前时间，w 表示新的待处理工作的绝对时间，newWork 表示是否有新的工作生成。
		gp, inheritTime, tnow, w, newWork := stealWork(now)
		if gp != nil {
			// 如果成功窃取到工作，返回 Goroutine gp、是否继承执行时间片 inheritTime 以及不需抢占标记 false。
			return gp, inheritTime, false
		}
		if newWork {
			// 如果可能存在新的定时器或 GC 工作，则重新开始窃取以查找新的工作。
			goto top
		}

		// 更新当前时间。
		now = tnow
		if w != 0 && (pollUntil == 0 || w < pollUntil) {
			// 如果发现更早的定时器到期时间，则更新 pollUntil。
			pollUntil = w
		}
	}

	// 我们当前没有任何工作可做。
	//
	// 如果 GC 标记阶段正在进行，并且有标记工作可用，尝试运行空闲时间标记，以利用当前的 P 而不是放弃它
	if gcBlackenEnabled != 0 && gcMarkWorkAvailable(pp) && gcController.addIdleMarkWorker() {
		// 从 GC 背景标记工作者池中获取一个节点。
		node := (*gcBgMarkWorkerNode)(gcBgMarkWorkerPool.pop())
		if node != nil {
			// 设置当前 P 的 GC 标记工作者模式为闲置模式。
			pp.gcMarkWorkerMode = gcMarkWorkerIdleMode

			// 从节点中获取 goroutine。
			gp := node.gp.ptr()

			// 将 goroutine 的状态从等待状态 (_Gwaiting) 改为可运行状态 (_Grunnable)。
			casgstatus(gp, _Gwaiting, _Grunnable)

			// 如果 trace 功能已启用，记录 goroutine 的唤醒。
			if traceEnabled() {
				traceGoUnpark(gp, 0)
			}
			// 返回找到的 goroutine 和相应的标志。
			return gp, false, false
		}
		// 如果没有找到节点，从 GC 控制器中移除闲置的标记工作者。
		gcController.removeIdleMarkWorker()
	}

	// WebAssembly 特殊处理：
	// 如果回调返回并且没有其他 goroutine 处于活跃状态，
	// 则唤醒事件处理器 goroutine，该 goroutine 会暂停执行直到触发回调。
	// 这个 beforeIdle 方法目前永远返回 nil,false
	gp, otherReady := beforeIdle(now, pollUntil)
	if gp != nil {
		// 将 goroutine 的状态从等待状态 (_Gwaiting) 改为可运行状态 (_Grunnable)。
		casgstatus(gp, _Gwaiting, _Grunnable)

		// 如果 trace 功能已启用，记录 goroutine 的唤醒。
		if traceEnabled() {
			traceGoUnpark(gp, 0)
		}

		// 返回找到的 goroutine 和相应的标志。
		return gp, false, false
	}

	// 如果有其他 goroutine 准备好，重新开始寻找工作。
	if otherReady {
		goto top
	}

	// 在我们放弃当前 P 之前，对 allp 切片做一个快照。
	// allp: 所有 p（逻辑处理器）的数组，长度等于 gomaxprocs
	//
	// allp 切片可能会在我们不再阻塞安全点（safe-point）时改变，
	// 因此我们需要快照来保持一致。我们不需要快照切片的内容，
	// 因为 allp 切片的前 cap(allp) 元素是不可变的。
	allpSnapshot := allp
	// 同样，对掩码（mask）也进行快照。值的变化是可以接受的，
	// 但是我们不能允许长度在我们使用过程中发生变化。
	idlepMaskSnapshot := idlepMask
	timerpMaskSnapshot := timerpMask

	// 返回 P 并进入阻塞状态。
	lock(&sched.lock)

	// 检查是否需要等待 GC 或执行安全点函数。
	if sched.gcwaiting.Load() || pp.runSafePointFn != 0 {
		// 如果有 GC 等待或有安全点函数要执行，则解锁并重新开始循环。
		unlock(&sched.lock)
		goto top
	}

	// 检查全局运行队列。
	if sched.runqsize != 0 {
		// 如果全局运行队列不为空，尝试从中获取一个 goroutine。
		gp := globrunqget(pp, 0)
		unlock(&sched.lock)
		// 返回找到的 goroutine。
		return gp, false, false
	}

	// 检查是否需要切换到自旋状态。
	if !mp.spinning && sched.needspinning.Load() == 1 {
		// See "Delicate dance" comment below.
		mp.becomeSpinning()
		unlock(&sched.lock)
		goto top
	}

	// 确认释放的 P 是否正确。
	if releasep() != pp {
		throw("findrunnable: wrong p")
	}

	// 将当前 P 设置为闲置状态。
	now = pidleput(pp, now)
	unlock(&sched.lock)

	// 线程从自旋状态转换到非自旋状态，
	// 这可能与新工作提交并发发生。我们必须首先减少自旋线程计数，
	// 然后重新检查所有工作来源（在 StoreLoad 内存屏障之间）。
	// 如果我们反向操作，另一个线程可能在我们检查完所有来源之后
	// 但还没减少 nmspinning 之前提交工作；结果将不会有任何线程被唤醒去执行工作。
	//
	// 这适用于以下工作来源：
	// * 添加到每个 P 运行队列的 goroutine。
	// * 每个 P 定时器堆上的新或早先修改的定时器。
	// * 闲置优先级的 GC 工作（除非有 golang.org/issue/19112）。
	//
	// 如果我们发现新工作，我们需要恢复 m.spinning 状态作为信号，
	// 以便 resetspinning 可以唤醒一个新的工作线程（因为可能有多个饥饿的 goroutine）。
	//
	// 但是，如果我们发现新工作后也观察到没有闲置的 P，
	// 我们就遇到了问题。我们可能正在与非自旋状态的 M 竞争，
	// 它已经找不到工作正准备释放它的 P 并停车。让那个 P 变成闲置状态会导致
	// 工作保护的损失（有可运行工作时闲置的 P）。这在不太可能发生的情况下
	// （即我们正与所有其他 P 停车竞争时恰好发现来自 netpoll 的新工作）
	// 可能导致完全死锁。
	//
	// 我们使用 sched.needspinning 来与即将闲置的非自旋状态 Ms 同步。
	// 如果它们即将放弃 P 时 needspinning 被设置，它们将取消放弃并代替
	// 成为我们服务的新自旋 M。如果我们没有竞争并且系统确实满负荷，
	// 那么不需要自旋线程，下一个自然变成自旋状态的线程将清除标志。
	//
	// 参见文件顶部的“工作线程停车/唤醒”注释。
	wasSpinning := mp.spinning

	// 记录当前 M 是否处于自旋状态。
	if mp.spinning {
		mp.spinning = false
		// 将当前 M 状态从自旋改为非自旋，并更新自旋 M 数量。
		if sched.nmspinning.Add(-1) < 0 {
			throw("findrunnable: negative nmspinning")
		}

		// 请注意：为了正确性，只有从自旋状态切换到非自旋状态的最后一个 M 必须执行以下重新检查，
		// 以确保没有遗漏的工作。然而，运行时在一些情况下会有瞬时增加 nmspinning 而不经过此路径减少，
		// 因此我们必须保守地在所有自旋的 M 上执行检查。
		//
		// 参考：https://go.dev/issue/43997。

		// 再次检查所有运行队列。
		// 在所有 P 上检查运行队列，获取工作。
		pp := checkRunqsNoP(allpSnapshot, idlepMaskSnapshot)
		if pp != nil {
			// 如果获取到了新的工作 P，则将 M 关联到该 P 上。
			acquirep(pp)
			mp.becomeSpinning()
			goto top
		}

		// 再次检查是否存在空闲的 GC 工作。
		// 在所有 P 上检查是否存在空闲的 GC 工作。
		pp, gp := checkIdleGCNoP()
		if pp != nil {
			// 如果存在空闲的 GC 工作，则将 M 关联到该 P 上，并执行 GC 相关操作。
			acquirep(pp)
			mp.becomeSpinning()

			// 运行闲置 worker。
			pp.gcMarkWorkerMode = gcMarkWorkerIdleMode
			casgstatus(gp, _Gwaiting, _Grunnable)
			if traceEnabled() {
				traceGoUnpark(gp, 0)
			}
			// 返回执行的 Goroutine 及相关信息。
			return gp, false, false
		}

		// 最后，检查定时器是否存在新的定时器或定时器到期事件。
		// 在所有 P 上检查定时器，更新 pollUntil 变量。
		pollUntil = checkTimersNoP(allpSnapshot, timerpMaskSnapshot, pollUntil)
	}

	// 轮询网络直到下一个定时器。
	// 如果网络轮询已初始化，并且存在网络轮询等待者或存在下一个定时器时间，且上次轮询成功标记不为0，则进行网络轮询。
	if netpollinited() && (netpollWaiters.Load() > 0 || pollUntil != 0) && sched.lastpoll.Swap(0) != 0 {
		// 更新调度器的轮询时间。
		sched.pollUntil.Store(pollUntil)

		// 如果当前 M 已绑定 P，则抛出错误。
		if mp.p != 0 {
			throw("findrunnable: netpoll with p")
		}

		// 如果当前 M 处于自旋状态，则抛出错误。
		if mp.spinning {
			throw("findrunnable: netpoll with spinning")
		}

		delay := int64(-1)
		if pollUntil != 0 {
			if now == 0 {
				now = nanotime()
			}
			// 计算需要延迟的时间。
			delay = pollUntil - now
			if delay < 0 {
				delay = 0
			}
		}

		// 如果使用假时间，则只进行轮询而不等待。
		if faketime != 0 {
			// 使用假时间时，只进行轮询。
			delay = 0
		}

		// 阻塞直到有新工作可用。
		// 进行网络轮询操作，延迟指定时间后返回就绪 Goroutine 列表。
		list := netpoll(delay)
		// 完成阻塞后刷新当前时间。
		now = nanotime()
		sched.pollUntil.Store(0)
		sched.lastpoll.Store(now)
		if faketime != 0 && list.empty() {
			// 如果使用假时间且没有准备好任何工作，则停止当前 M。
			// 当所有 M 停止时，checkdead 将调用 timejump 来调整时钟。
			stopm()
			goto top
		}
		lock(&sched.lock)
		pp, _ := pidleget(now)
		unlock(&sched.lock)

		// 如果没有空闲 P，则将就绪列表注入调度器中。
		if pp == nil {
			injectglist(&list)
		} else {
			// 如果有空闲 P，则将 M 绑定到该 P 上。
			acquirep(pp)
			if !list.empty() {
				// 如果就绪列表不为空，则将就绪 Goroutine 取出并运行。
				gp := list.pop()
				injectglist(&list)
				casgstatus(gp, _Gwaiting, _Grunnable)
				if traceEnabled() {
					traceGoUnpark(gp, 0)
				}
				// 返回执行的 Goroutine 及相关信息。
				return gp, false, false
			}

			// 如果之前该 M 处于自旋状态，则恢复自旋状态。
			if wasSpinning {
				mp.becomeSpinning()
			}
			goto top
		}
	} else if pollUntil != 0 && netpollinited() {
		// 如果存在下一个定时器且网络轮询已初始化，则继续判断是否需要调用 netpollBreak。
		pollerPollUntil := sched.pollUntil.Load()
		if pollerPollUntil == 0 || pollerPollUntil > pollUntil {
			// 如果当前定时器需要更新或者定时器时间变更，则调用 netpollBreak。
			netpollBreak()
		}
	}
	
	// 停止当前m的执行，直到新的工作可用
	stopm()
	goto top
}
```

# findRunnable简化版

```go
// 查找一个可运行的 goroutine 来执行。
// 它尝试从其他 P（处理器）偷取 goroutine，从本地或全局队列中获取 goroutine，或者轮询网络。
// tryWakeP 表示返回的 goroutine 不是普通的（例如 GC worker 或 trace reader），因此调用者应该尝试唤醒一个 P。
func findRunnable() (gp *g, inheritTime, tryWakeP bool) {
	// 从当前运行的 goroutine (getg()) 中获取其关联的 M（机器线程）
	mp := getg().m

	// 这里的条件和 handoffp 中的条件必须一致：如果 findRunnable 会返回一个 goroutine 来运行，
	// handoffp 必须启动一个 M。

top: // 标记位置，用于循环重试。
	pp := mp.p.ptr() // 获取当前 M 关联的 P。
	...
	// 尝试从本地队列获取 goroutine。
	if gp, inheritTime := runqget(pp); gp != nil {
		// 返回从本地队列找到的 goroutine。
		return gp, inheritTime, false
	}

	// 如果全局队列不为空，尝试从中获取 goroutine。
	// 1.Goroutine 主动让出执行权，例如调用 runtime.Gosched() 方法；
	// 2.Goroutine 执行的时间片用完，会被放入全局队列以便重新调度；
	// 3.某些系统调用（比如阻塞的网络操作）会导致 Goroutine暂时进入全局队列。
	//
	// runqsize > 0 全局可运行队列的大小;
	if sched.runqsize != 0 {
		lock(&sched.lock)
		// 尝试从全局可运行队列中获取一批G
		gp := globrunqget(pp, 0)
		unlock(&sched.lock)
		if gp != nil {
			return gp, false, false
		}
	}

	// 检测网络轮询器是否已经初始化，并且当前有等待的网络轮询事件，并且上一次轮询时间不为零。
	// 这是一个优化操作，避免直接进行任务窃取。
	// 当某个 Goroutine 因为在网络操作中被阻塞而无法继续执行时，它会被放入等待网络事件的队列中，等待网络事件就绪后再次被调度执行。
	if netpollinited() && netpollWaiters.Load() > 0 && sched.lastpoll.Load() != 0 {
		// 进行非阻塞的网络轮询，获取就绪的网络事件列表。
		if list := netpoll(0); !list.empty() {
			// 从事件列表中取出一个 Goroutine 并标记为可运行状态。
			gp := list.pop()
			// 将剩余事件重新注入网络事件队列中。
			injectglist(&list)
			// 原子更新 Goroutine 的状态为可运行状态。
			casgstatus(gp, _Gwaiting, _Grunnable)
			// 如果追踪功能开启，则记录 Goroutine 的解除阻塞事件。
			if traceEnabled() {
				traceGoUnpark(gp, 0)
			}
			// 返回从网络轮询中找到的 Goroutine。
			return gp, false, false
		}
	}

	// 尝试从任何 P 上窃取可运行的 goroutine。
	// 限制自旋 M 的数量，以防止在高 GOMAXPROCS 下程序并行度低时过度消耗 CPU。
	// 如果当前 M 正在自旋或者当前可自旋 M 数量的两倍小于 GOMAXPROCS 减去空闲的 P 数量，
	// 则进入窃取工作的逻辑。
	if mp.spinning || 2*sched.nmspinning.Load() < gomaxprocs-sched.npidle.Load() {
		if !mp.spinning {
			// 如果当前 M 不处于自旋状态，则将其转换为自旋状态。
			mp.becomeSpinning()
		}

		// 尝试从任何 P 上窃取可运行的 goroutine。
		// gp 为窃取到的 Goroutine，inheritTime 表示是否继承 Goroutine 的执行时间片，
		// tnow 为当前时间，w 表示新的待处理工作的绝对时间，newWork 表示是否有新的工作生成。
		gp, inheritTime, tnow, w, newWork := stealWork(now)
		if gp != nil {
			// 如果成功窃取到工作，返回 Goroutine gp、是否继承执行时间片 inheritTime 以及不需抢占标记 false。
			return gp, inheritTime, false
		}
		if newWork {
			// 如果可能存在新的定时器或 GC 工作，则重新开始窃取以查找新的工作。
			goto top
		}

		// 更新当前时间。
		now = tnow
		if w != 0 && (pollUntil == 0 || w < pollUntil) {
			// 如果发现更早的定时器到期时间，则更新 pollUntil。
			pollUntil = w
		}
	}

	// 我们当前没有任何工作可做。
	//
	// 如果 GC 标记阶段正在进行，并且有标记工作可用，尝试运行空闲时间标记，以利用当前的 P 而不是放弃它
	if gcBlackenEnabled != 0 && gcMarkWorkAvailable(pp) && gcController.addIdleMarkWorker() {
		// 从 GC 背景标记工作者池中获取一个节点。
		node := (*gcBgMarkWorkerNode)(gcBgMarkWorkerPool.pop())
		if node != nil {
			// 设置当前 P 的 GC 标记工作者模式为闲置模式。
			pp.gcMarkWorkerMode = gcMarkWorkerIdleMode

			// 从节点中获取 goroutine。
			gp := node.gp.ptr()

			// 将 goroutine 的状态从等待状态 (_Gwaiting) 改为可运行状态 (_Grunnable)。
			casgstatus(gp, _Gwaiting, _Grunnable)

			// 如果 trace 功能已启用，记录 goroutine 的唤醒。
			if traceEnabled() {
				traceGoUnpark(gp, 0)
			}
			// 返回找到的 goroutine 和相应的标志。
			return gp, false, false
		}
		// 如果没有找到节点，从 GC 控制器中移除闲置的标记工作者。
		gcController.removeIdleMarkWorker()
	}
}
```

简化版重要的步骤如下: 

1. **从本地队列获取**: 返回从调度器 p 本地队列找到的 goroutine
2. **从全局队列获取**:返回从全局对队列找到的  goroutine
3. **从等待网络事件的队列获取**: 返回从网络发送阻塞的队列找到的   goroutine
4. **从其他调度器 p 窃取**: 尝试从任何 P 上窃取可运行的 goroutine
5. **没有任何任务可做**: 支援 GC 垃圾回收



这里面除了**从其他调度器 p 窃取**都好理解, 都是从队列找goroutine

下面我们详细看看, go语言的协程是怎么在这个线程没有任务的时候去别的线程窃取任务执行的

## stealWork从其他调度器窃取任务

```go
// 尝试从任何 P 上窃取可运行的 goroutine 或定时器。
// 从所有 p 调度器中取出一个可执行的任务, 一共取4次, 最多有 4*len(p) 个任务
//
// 如果 newWork 为真，可能有新工作已被准备就绪。
//
// 如果 now 不为 0，则它是当前时间。stealWork 函数返回传递的时间或
// 如果 now 为 0 时的当前时间。
func stealWork(now int64) (gp *g, inheritTime bool, rnow, pollUntil int64, newWork bool) {
	// 获取当前协程关联的 P。
	pp := getg().m.p.ptr()

	// 标记是否已运行定时器。
	ranTimer := false

	const stealTries = 4
	// 从所有 p 调度器中取出一个可执行的任务, 一共取4次, 最多有 4*len(p) 个任务
	for i := 0; i < stealTries; i++ {
		stealTimersOrRunNextG := i == stealTries-1
	
		// 遍历所有 P 的顺序, 以一个随机数开始。
		for enum := stealOrder.start(fastrand()); !enum.done(); enum.next() {
			// GC 工作可能可用。
			if sched.gcwaiting.Load() {
				return nil, false, now, pollUntil, true
			}

			// allp 所有 p（逻辑处理器）切片获取索引位置的 p
			p2 := allp[enum.position()]
			if pp == p2 {
				// 如果是当前 P 则跳过。
				continue
			}

			// 从 p2 窃取定时器。
			// 在最后一轮之前唯一可能持有不同 P 的定时器锁的地方。
			if stealTimersOrRunNextG && timerpMask.read(enum.position()) {
				tnow, w, ran := checkTimers(p2, now)
				now = tnow
				if w != 0 && (pollUntil == 0 || w < pollUntil) {
					pollUntil = w
				}
				if ran {
					// 运行定时器可能已经使任意数量的 G 变为可运行状态。
					if gp, inheritTime := runqget(pp); gp != nil {
						// 尝试从当前 P 的本地运行队列获取 Goroutine，并返回。
						return gp, inheritTime, now, pollUntil, ranTimer
					}
					ranTimer = true
				}
			}

			// 如果 p2 是闲置的，则不要费力尝试窃取。
			if !idlepMask.read(enum.position()) {
				if gp := runqsteal(pp, p2, stealTimersOrRunNextG); gp != nil {
					// 尝试从其他 P 窃取可运行的 Goroutine 并返回。
					return gp, false, now, pollUntil, ranTimer
				}
			}
		}
	}

	// 没有找到可以窃取的 goroutine。不过，运行定时器可能已经
	// 使我们错过的某些 goroutine 变为可运行状态。指示等待的下一个定时器。
	return nil, false, now, pollUntil, ranTimer
}
```

1. **初始化变量**：获取当前线程的 P。
2. **循环尝试窃取**：进行固定次数的尝试，每次尝试从不同的 P 上窃取工作。
3. **检查 GC 状态**：如果 GC 等待标志被设置，可能有 GC 工作可用，结束窃取并指示新工作可能已经准备就绪。
4. **枚举所有 P**：使用 `stealOrder` 枚举所有 P，跳过当前线程的 P。
5. **窃取定时器**：在最后一次尝试中检查目标 P 的定时器，更新当前时间和下一个轮询时间。
6. **运行定时器的影响**：如果运行了定时器，检查当前 P 的本地运行队列是否已有可运行的 goroutine。
7. **从非闲置 P 窃取**：如果目标 P 不是闲置状态，尝试从其运行队列窃取 goroutine。
8. **返回结果**：如果没有找到可窃取的 goroutine，返回当前时间和可能的定时器更新信息，指示是否运行了定时器。

