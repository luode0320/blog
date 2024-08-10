# 简介

在 Go 语言运行时中，`sysmon` 是一个后台监控线程，它的主要职责是监控和维护运行时环境的健康状态。

`sysmon` 线程在运行时初始化阶段被创建，并在整个程序执行期间持续运行。

# 职责

1. **垃圾回收（Garbage Collection）监控**：
    - `sysmon` 线程会定期检查是否需要触发垃圾回收。默认是如果**超过2分钟**没有执行`GC`便强制执行一次
    - 它会根据设定的策略判断是否垃圾回收应该被启动，比如检查上次垃圾回收以来已经过去了多少时间或堆的使用情况。
2. **系统资源监控**：
    - `sysmon` 会监控系统资源的使用情况，如内存、CPU 等，以确保运行时系统能够及时响应资源的变化，做出适当的调整。
3. **线程和 goroutine 管理**：
    - 当 goroutine 被阻塞时，`sysmon` 线程能够检测到这种情况，并采取相应的行动，比如重新分配被阻塞的 goroutine
      所绑定的处理器（P）到另一个机器线程（M）。
4. **抢占式调度**：
    - `sysmon` 可以监测 goroutine 的运行时间，如果发现某个 goroutine 的执行时间过长，它可以设置该 goroutine 的抢占标志，促使
      goroutine 交出 CPU 时间片，从而允许其他 goroutine 得到执行的机会。
5. **辅助垃圾收集**：
    - `sysmon` 还可以帮助垃圾收集器进行黑化（blackening）操作，这是指标记对象的过程，以确定哪些对象仍然存活，哪些可以被回收。
6. **唤醒等待的 goroutine**：
    - 如果有 goroutine 因为等待某些条件（如通道操作）而处于睡眠状态，`sysmon` 可以帮助唤醒这些 goroutine，使其恢复执行。
7. **维护运行时状态**：
    - `sysmon` 还会维护和更新运行时系统的各种状态信息，确保调度器和其它系统组件有足够的信息来进行决策。

# 源码

`runtime/proc.go`

## systemstack启动监控线程

在 `runtime.main()` 函数中，会启动一个 sysmon 的监控线程，执行后台监控任务：

```go
// The main goroutine.
func main() { // 这是主goroutine
    ...
    // wasm上还没有线程，所以没有sysmon
    if GOARCH != "wasm" { 
       systemstack(func() {
          // 创建监控线程，该线程独立于调度器，不需要跟 p 关联即可运行
          newm(sysmon, nil, -1)
       })
    }
    ...
}
```

**newn**主要用于创建一个线程, 而监控线程主要的工作来自**sysmon**方法回调

### newm创建监控线程

`sysmon` 函数不依赖调度器 P 直接执行，通过 newm 函数创建一个工作线程：

```go
// 创建一个新的 M。它将从调用 fn 函数或调度器开始。
// fn 必须是静态的，不能是堆上分配的闭包。
// id 是可选的预先分配的 M ID。如果不指定则传递 -1。
//
// 可能在 m.p 为 nil 的情况下运行，所以不允许写屏障。
//
//go:nowritebarrierrec
func newm(fn func(), pp *p, id int64) {
    // allocm 函数会向 allm 添加一个新的 M，但它们直到由 OS 在 newm1 或模板线程中创建才开始运行。
    // doAllThreadsSyscall 要求 allm 中的每个 M 最终都会开始并且可以被信号中断，即使在全局停止世界（STW）期间也是如此。
    //
    // 在这里禁用抢占，直到我们启动线程以确保 newm 不会在 allocm 和启动新线程之间被抢占，
    // 确保任何添加到 allm 的东西都保证最终会开始。
    acquirem()

    mp := allocm(pp, fn, id) // 为 M 分配内存并初始化，将其赋值给 mp
    mp.nextp.set(pp)         // 配置下一个 P
    mp.sigmask = initSigmask // 设置初始信号掩码

    if gp := getg(); gp != nil && gp.m != nil && (gp.m.lockedExt != 0 || gp.m.incgo) && GOOS != "plan9" {
       // 我们正在一个锁定的 M 上或一个可能由 C 启动的线程上。
       // 内核线程的状态可能很奇怪（用户可能为了这个目的锁定它）。
       // 我们不想把这个状态克隆到另一个线程中。
       // 相反，让一个已知良好的线程为我们创建线程。
       //
       // 在 Plan 9 上禁用这个特性。参见 golang.org/issue/22227。
       //
       // TODO: 这个特性在 Windows 上可能是不必要的，Windows 的线程创建并不基于 fork。
       lock(&newmHandoff.lock)
       if newmHandoff.haveTemplateThread == 0 {
          throw("在一个被锁的线程上，但没有模板线程")
       }
       mp.schedlink = newmHandoff.newm
       newmHandoff.newm.set(mp)
       if newmHandoff.waiting {
          newmHandoff.waiting = false
          // 唤醒模板线程
          notewakeup(&newmHandoff.wake)
       }
       unlock(&newmHandoff.lock)
       // M 尚未开始，但模板线程不参与 STW，所以它总是处理排队的 Ms，
       // 所以释放 m 是安全的。
       releasem(getg().m)
       return
    }
    newm1(mp) // 实际启动 M
    releasem(getg().m)
}
```

#### newm1实际启动M

```go
// 实际上启动一个新创建的 m 结构体，使其成为一个运行中的线程。
func newm1(mp *m) {
    // 检查是否启用了 Cgo 支持。
    if iscgo {
       // 初始化 cgothreadstart 类型的变量 ts。
       var ts cgothreadstart
       // 检查是否定义了 Cgo 的线程启动函数。
       if _cgo_thread_start == nil {
          throw("_cgo_thread_start missing")
       }
       // 设置 cgo 线程启动函数的参数 g 为 mp.g0
       ts.g.set(mp.g0)
       // 设置线程本地存储的指针为 &mp.tls[0]
       ts.tls = (*uint64)(unsafe.Pointer(&mp.tls[0]))
       // 设置线程启动函数为 mstart 的函数指针
       ts.fn = unsafe.Pointer(abi.FuncPCABI0(mstart))

       // 写入 msan 监测
       if msanenabled {
          msanwrite(unsafe.Pointer(&ts), unsafe.Sizeof(ts))
       }

       // 写入 asan 监测
       if asanenabled {
          asanwrite(unsafe.Pointer(&ts), unsafe.Sizeof(ts))
       }

       // 防止进程克隆
       execLock.rlock()
       asmcgocall(_cgo_thread_start, unsafe.Pointer(&ts)) // 调用 _cgo_thread_start 函数启动 cgo 线程
       execLock.runlock()
       return
    }

    // 如果没有启用 Cgo，直接启动一个新的操作系统线程。

    // 防止进程克隆
    execLock.rlock()
    newosproc(mp) // 调用 newosproc 来启动一个新的操作系统线程。
    execLock.runlock()
}
```

1. **Cgo 模式检查**：如果启用了 Cgo 支持，将执行 Cgo 相关的线程启动逻辑；否则，将执行默认的操作系统线程启动逻辑。

2. **Cgo 线程启动**：

    - 初始化 `cgothreadstart` 类型的结构体 `ts`。
    - 设置 `ts` 的 `g` 字段为 `mp` 的 `g0` goroutine，以便新线程可以从 `g0` 开始运行。
    - 设置 `ts` 的 `tls` 字段为 `mp` 的线程局部存储（TLS）的地址。
    - 设置 `ts` 的 `fn` 字段为 `mstart` 函数的地址，这是新线程将要执行的第一个函数。
    - 如果启用了 msan 或 asan，使用 `msanwrite` 或 `asanwrite` 标记 `ts` 结构体的内存，避免误报。
    - 使用 `execLock` 的读锁来防止在创建新线程时发生进程克隆。
    - 使用 `asmcgocall` 调用 C 函数 `_cgo_thread_start`，传递 `ts` 的地址作为参数。
    - 释放 `execLock` 的读锁。

3. **非 Cgo 线程启动**：

    - 使用 `execLock` 的读锁来防止在创建新线程时发生进程克隆。
    - 调用 `newosproc` 来启动一个新的操作系统线程。
    - 释放 `execLock` 的读锁。

#### newosproc启动一个工作线程

```go
// 在可能 m.p==nil 的情况下运行，因此不允许写屏障。
// 此函数由 newosproc0 调用，因此也需要在没有栈保护的情况下运行。
//
//go:nowritebarrierrec
//go:nosplit
func newosproc(mp *m) {
    // 我们传递 0 作为栈大小来使用此二进制文件的默认值。
    // 使用 stdcall6 调用 CreateThread 函数，参数如下：
    // 第一个参数是线程优先级，我们传入 0 使用默认值；
    // 第二个参数是栈大小，我们传入 0 使用默认值；
    // 第三个参数是线程的入口函数地址，我们传入 tstart_stdcall；
    // 第四个参数是线程参数，我们传入 mp 的地址；
    // 第五个和第六个参数保留，通常设为 0。
    thandle := stdcall6(_CreateThread, 0, 0,
       abi.FuncPCABI0(tstart_stdcall), uintptr(unsafe.Pointer(mp)),
       0, 0)

    if thandle == 0 {
       if atomic.Load(&exiting) != 0 {
          // 如果与 ExitProcess 并发调用，可能导致 CreateThread 失败。如果发生这种情况，只需冻结此线程，让进程退出。
          // 见问题 #18253。
          lock(&deadlock)
          lock(&deadlock)
       }
       print("runtime: 创建新的 OS 线程失败（已有 ", mcount(), " 个线程; errno=", getlasterror(), "）\n")
       throw("runtime.newosproc")
    }

    // 如果该线程退出, 关闭 thandle 以避免线程对象泄漏。
    stdcall1(_CloseHandle, thandle)
}
```

#### stdcall1调用约定的 C 函数

这里就是直接创建一个线程的方法了

```go
// 用于调用 stdcall 调用约定的 C 函数，但仅支持一个参数。
// fn 参数是一个指向 C 函数的指针，a0 是传递给该函数的唯一参数。
//
//go:nosplit
//go:cgo_unsafe_args
func stdcall1(fn stdFunction, a0 uintptr) uintptr {
    mp := getg().m                                           // 获取当前 goroutine 关联的执行上下文 m
    mp.libcall.n = 1                                         // 设置 libcall 的参数数量为 1
    mp.libcall.args = uintptr(noescape(unsafe.Pointer(&a0))) // 将参数 a0 的地址设置为 libcall 的参数
    return stdcall(fn)                                       // 调用 stdcall 函数并返回结果
}
```

## sysmon 函数到底做了什么？

## sysmon源码

```go
// 负责监控和维护整个运行时系统的健康状态;
// 在无需 P 的情况下运行，因此不允许写屏障。
//
//go:nowritebarrierrec
func sysmon() {
    lock(&sched.lock)   // 锁定调度器锁。
    sched.nmsys++       // 增加系统监控线程计数。
    checkdead()         // 检查是否有死掉的 goroutine。
    unlock(&sched.lock) // 解锁调度器锁。

    lasttrace := int64(0) // 上一次记录调度跟踪的时间戳。
    idle := 0             // 记录连续没有唤醒任何 goroutine 的循环次数。
    delay := uint32(0)    // 睡眠延迟，初始为 0。

    // 死循环, 并设置一定的休眠, 避免 cpu 过高
    for {
       // 根据 idle 的值调整延迟。
       if idle == 0 {
          delay = 20 // 初始延迟为 20 微秒。
       } else if idle > 50 {
          delay *= 2 // 如果 idle 大于 50 微秒，延迟翻倍。
       }
       if delay > 10*1000 {
          delay = 10 * 1000 // 如果 idle 大于 10 毫秒，最大延迟为 10 毫秒。
       }
        
       // 以微秒为单位的睡眠函数，实现功能为线程在指定的微秒时间内进入睡眠状态
       usleep(delay)
       
        // 根据条件判断，决定是否进入深度睡眠：(忽略代码)

       // 锁定 sysmon 专用锁。
       lock(&sched.sysmonlock)
        
       // 更新 now，以防在 sysmonnote 或 schedlock/sysmonlock 上阻塞了很长时间。
       now = nanotime()

       // 如果需要，触发 libc 拦截器(忽略代码)

       // 如果超过 10 毫秒没有进行网络轮询，则进行网络轮询
       lastpoll := sched.lastpoll.Load() // lastpoll 上一次网络轮询的时间戳，如果当前正在进行轮询，则为 0。
       // 确保网络轮询已初始化、lastpoll 不为0且距离上次网络轮询已经超过 10 毫秒。
       if netpollinited() && lastpoll != 0 && lastpoll+10*1000*1000 < now {
          // 使用原子比较和交换操作更新 lastpoll 的值为当前时间 now, 表示此次网络轮询的时间戳
          sched.lastpoll.CompareAndSwap(lastpoll, now)
          // 以非阻塞模式进行网络轮询，返回一个列表 list。
          // 函数用于检查就绪的网络连接。运行时网络 I/O 的关键部分，
          // 它利用平台的 IO 完成端口机制来高效地检测就绪的网络连接，并准备好相应的 goroutine 进行后续的网络操作
          // 返回一个 goroutine 列表，表示这些 goroutine 的网络阻塞已经停止, 可以开始调度运行。
          list := netpoll(0)
          // 如果不为空
          if !list.empty() {
             incidlelocked(-1)  // 减少锁定的空闲 M 的计数，表示有 M 被占用
             injectglist(&list) // 将需要运行的 goroutine 列表注入到全局队列中，准备执行。
             incidlelocked(1)   // 增加锁定的空闲 M 的计数，表示空闲 M 的数量增加。
          }
       }

       // 特殊处理 NetBSD 上的定时器问题。(忽略代码)

       // 如果 scavenger 请求唤醒，则唤醒 scavenger。(忽略代码)

       // 函数尝试重新获取因系统调用而阻塞的处理器（P），
       // 这样可以确保运行时能够有效地管理资源和调度 Goroutine。
       if retake(now) != 0 {
          idle = 0 // 如果成功重新获取 P 或抢占 G，则重置 idle。
       } else {
          idle++ // 否则增加 idle 计数。
       }

		// 根据不同的触发条件来决定是否需要启动一个新的 GC 周期。
		// 创建临时 gcTrigger 实例: 创建一个临时的 gcTrigger 实例，其 kind 为 gcTriggerTime 强制gc标识，now 字段为当前时间。
		// 调用 test 方法: 调用 gcTrigger 实例的 test 方法来检查是否需要触发超时2分钟的强制 GC。
		// 检查是否处于空闲状态: 检查 forcegc.idle 是否为 true，即 GC 是否处于空闲状态, 才允许强制gc
		if t := (gcTrigger{kind: gcTriggerTime, now: now}); t.test() && forcegc.idle.Load() { // test(): 根据不同的触发条件来决定是否需要启动一个新的 GC 周期。
			lock(&forcegc.lock) // 加锁以确保对 forcegc 结构体的操作是原子的。

			forcegc.idle.Store(false) // 将 forcegc.idle 设置为 false，表示 GC 不再处于空闲状态。
			var list gList            // 创建一个 gList 结构体，用于存放需要注入的 goroutine。
			list.push(forcegc.g)      // 将 forcegc.g 添加到 gList 中。
			injectglist(&list)        // 将 forcegc.g 注入到运行队列中，使其可以被调度执行。

			// 解锁以释放对 forcegc 结构体的独占访问。
			unlock(&forcegc.lock)
		}
        
       // 记录调度跟踪信息。(忽略代码)

       // 解锁 sysmon 专用锁。
       unlock(&sched.sysmonlock)
    }
}
```

1. 获取当前时间并进入循环。
2. 根据 `idle` 的值调整睡眠延迟，并在每次循环中调用 `usleep` 进行线程休眠。
3. 根据条件判断，决定是否进入深度睡眠：(忽略代码)
    - 检查是否允许进入深度睡眠，并计算下一次唤醒时间。
    - 若允许，进行非抢占式睡眠，过程中可能调整系统负载。
    - 根据睡眠是否由系统调用唤醒来调整 `idle` 和延迟时间。
4. 锁定 `sysmonlock` 执行以下操作：
    - 触发 libc 拦截器，进行网络轮询。(忽略代码)
    - **如果超过 10 毫秒没有进行网络轮询，则进行网络轮询**
    - 处理特定于 NetBSD 的定时器问题。(忽略代码)
    - 处理对清扫程序的唤醒请求。(忽略代码)
    - **重新获取被系统调用阻塞的 P，并抢占长时间运行的 G**
    - 检查是否需要强制执行 GC。
    - 记录调度跟踪信息。(忽略代码)
5. 解锁 `sysmonlock` 并继续循环执行以上步骤。

源码重点:

1. **如果超过 10 毫秒没有进行网络轮询，则进行网络轮询**
2. **重新获取被系统调用阻塞的 P，并抢占长时间运行的 G**

下面我们将着重关心这2点。

## netpoll轮询被网络io阻塞的 g

如果有 goroutine 因为网络 io 被阻塞了, 这个方法会查询出已经完成调用, 接触阻塞的 goroutine, 加入可运行队列。

```go
       // 如果超过 10 毫秒没有进行网络轮询，则进行网络轮询
       lastpoll := sched.lastpoll.Load() // lastpoll 上一次网络轮询的时间戳，如果当前正在进行轮询，则为 0。
       // 确保网络轮询已初始化、lastpoll 不为0且距离上次网络轮询已经超过 10 毫秒。
       if netpollinited() && lastpoll != 0 && lastpoll+10*1000*1000 < now {
          // 使用原子比较和交换操作更新 lastpoll 的值为当前时间 now, 表示此次网络轮询的时间戳
          sched.lastpoll.CompareAndSwap(lastpoll, now)
          // 以非阻塞模式进行网络轮询，返回一个列表 list。
          // 函数用于检查就绪的网络连接。运行时网络 I/O 的关键部分，
          // 它利用平台的 IO 完成端口机制来高效地检测就绪的网络连接，并准备好相应的 goroutine 进行后续的网络操作
          // 返回一个 goroutine 列表，表示这些 goroutine 的网络阻塞已经停止, 可以开始调度运行。
          list := netpoll(0)
          // 如果不为空
          if !list.empty() {
             incidlelocked(-1)  // 减少锁定的空闲 M 的计数，表示有 M 被占用
             injectglist(&list) // 将需要运行的 goroutine 列表注入到全局队列中，准备执行。
             incidlelocked(1)   // 增加锁定的空闲 M 的计数，表示空闲 M 的数量增加。
          }
       }
```

说明重点:

- `netpoll`系统调用函数, 查询之前网络 io 阻塞的 goroutine 有哪些此时已经不在阻塞, 并返回

- 调用`injectglist`函数, 将这些已经不阻塞的 goroutine 加入全局队列中, 准备被循环调度 `scheduler` 调度执行

    - 注: 这里并不是都加入全局队列, 如果全局队列满了, 也会加入到当前 m 线程的 p 调度器的本地队列

因为`netpoll`是调用系统函数, `injectglist`仅仅是加入全局队列

都很简单的逻辑, 所以没有贴源码了

## retake抢占被阻塞的 p 调度器

```go
       // 函数尝试重新获取因系统调用而阻塞的处理器（P），
       // 这样可以确保运行时能够有效地管理资源和调度 Goroutine。
       if retake(now) != 0 {
          idle = 0 // 如果成功重新获取 P 或抢占 G，则重置 idle。
       } else {
          idle++ // 否则增加 idle 计数。
       }
```

### retake源码

```go
// 函数尝试重新获取因系统调用而阻塞的处理器（P），
// 这样可以确保运行时能够有效地管理资源和调度 Goroutine。
// 1.如果 Goroutine 运行时间过长，尝试抢占。
// 2.如果 P 正在系统调用中, 尝试将 P 的控制权交给另一个 M。
func retake(now int64) uint32 {
    // 初始化 n 为 0，用于计数重新获取的 P。
    n := 0

    // 防止 allp 切片在遍历过程中被修改。这个锁通常不会竞争，
    // 除非我们已经在停止世界（stop-the-world）操作中。
    lock(&allpLock)

    // 不能使用 for-range 循环遍历 allp，因为可能会暂时释放 allpLock。
    // 因此，每次循环都需要重新获取 allp。
    for i := 0; i < len(allp); i++ {
       pp := allp[i]

       // 这种情况发生在 procresize 增大了 allp 的大小，
       // 但是还没有创建新的 P。
       if pp == nil {
          continue
       }

       pd := &pp.sysmontick
       s := pp.status

       // 标志表示是否需要重新获取 P（仅在系统调用场景下）。
       sysretake := false

       // 如果 P 正在运行或在系统调用中，检查是否需要抢占当前运行的 Goroutine。
       if s == _Prunning || s == _Psyscall {
          t := int64(pp.schedtick)

          // 更新 P 的调度计数和时间戳。
          if int64(pd.schedtick) != t {
             pd.schedtick = uint32(t)
             pd.schedwhen = now
          } else if pd.schedwhen+forcePreemptNS <= now {
             // 如果 Goroutine 运行时间过长，尝试抢占。
             preemptone(pp)
             // 对于系统调用，preemptone 可能无效，因为此时没有 M 与 P 相关联。
             sysretake = true
          }
       }

       // 如果 P 正在系统调用中，检查是否需要重新获取 P。
       if s == _Psyscall {
          // 如果超过1个sysmon滴答 (至少20us)，则从syscall重新获取P。
          t := int64(pp.syscalltick)

          // 更新 P 的系统调用计数和时间戳。
          if !sysretake && int64(pd.syscalltick) != t {
             pd.syscalltick = uint32(t)
             pd.syscallwhen = now
             continue
          }

          // 只要满足下面三个条件之一，则抢占该 p，否则不抢占
          // 1. p 的运行队列里面有等待运行的 goroutine
          // 2. 所在的 M 线程正在执行
          // 3. 从上一次监控线程观察到 p 对应的 m 处于系统调用之中到现在已经超过 10 毫秒
          if runqempty(pp) && sched.nmspinning.Load()+sched.npidle.Load() > 0 && pd.syscallwhen+10*1000*1000 > now {
             continue
          }

          // 释放 allpLock，以便可以获取 sched.lock。
          unlock(&allpLock)

          // 减少空闲锁定 M 的数量（假装又有一个 M 正在运行），
          // 这样在 CAS 操作之前可以避免死锁报告。
          incidlelocked(-1)

          // 尝试原子更新 P 的状态，将其从系统调用状态变为空闲状态。
          if atomic.Cas(&pp.status, s, _Pidle) {
             // 记录系统调用阻塞和进程停止的跟踪事件。
             if traceEnabled() {
                traceGoSysBlock(pp)
                traceProcStop(pp)
             }
             n++
             pp.syscalltick++
             // 将 P 的控制权交给另一个 M。
             handoffp(pp)
          }

          // 恢复空闲锁定 M 的数量。
          incidlelocked(1)
          // 重新获取 allpLock。
          lock(&allpLock)
       }
    }
    // 释放 allpLock。
    unlock(&allpLock)

    // 返回重新获取的 P 的数量。
    return uint32(n)
}
```

1. **初始化和锁获取**：
    - 初始化 `n` 为 0，用于计数重新获取的 P。
    - 获取 `allpLock` 锁，防止遍历时 `allp` 被修改。
2. **遍历所有 P**：
    - 遍历 `allp` 切片，检查每个 P 的状态和计数器。
    - 如果 P 为空，跳过本次循环。
3. **检查和更新调度计数器**：
    - 如果 P 正在运行或在系统调用中，检查是否需要抢占当前运行的 Goroutine。
    - 如果 Goroutine 运行时间过长，尝试抢占。
4. **检查和更新系统调用计数器**：
    - 如果 P 正在系统调用中，检查是否需要重新获取 P。
    - 如果运行队列为空且有其他 M 正在空转或空闲，且系统调用时间未超过阈值，则跳过重新获取。
5. **重新分配 P**：
    - 释放 `allpLock` 锁。
    - 减少空闲锁定 M 的数量。
    - 尝试原子更新 P 的状态，将其从系统调用状态变为空闲状态。
    - 如果成功，增加重新获取的 P 的计数，更新系统调用计数，将 P 的控制权交给另一个 M。
    - 恢复空闲锁定 M 的数量。
    - 重新获取 `allpLock` 锁。
6. **解锁**：
    - 释放 `allpLock` 锁。
7. **返回结果**：
    - 返回重新获取的 P 的数量。

源码重点:

1. **如果 Goroutine 运行时间过长，尝试抢占**
2. **调度器 p 可能阻塞, 重新分配 p 到其他 M**

### Goroutine 运行时间过长，尝试抢占

```go
       // 如果 P 正在运行或在系统调用中，检查是否需要抢占当前运行的 Goroutine。
       if s == _Prunning || s == _Psyscall {
          t := int64(pp.schedtick)

          // 更新 P 的调度计数和时间戳。
          if int64(pd.schedtick) != t {
             pd.schedtick = uint32(t)
             pd.schedwhen = now
          } else if pd.schedwhen+forcePreemptNS <= now {
             // 如果 Goroutine 运行时间过长，尝试抢占。
             preemptone(pp)
             // 对于系统调用，preemptone 可能无效，因为此时没有 M 与 P 相关联。
             sysretake = true
          }
       }
```

我们知道，Go scheduler 采用的是一种称为协作式的抢占式调度，就是说并不强制调度，大家保持协作关系，互相信任。

- 对于长时间运行的 P，或者说绑定在 P 上的长时间运行的 goroutine，sysmon 会检测到这种情况，然后设置一些标志

- 表示 goroutine 自己让出 CPU 的执行权，给其他 goroutine 一些机会。

如果发现运行时间超过了 10 ms，则要调用 `preemptone(_p_)` 发起抢占的请求：

```go
// 函数尝试请求在处理器 P 上运行的 Goroutine 停止。
// 此函数仅尽力而为。它可能无法正确通知 Goroutine，也可能通知错误的 Goroutine。
// 即使通知了正确的 Goroutine，如果 Goroutine 正在同时执行 newstack，它也可能会忽略请求。
// 不需要持有任何锁。
// 如果成功发出抢占请求则返回 true。
// 实际的抢占将在未来某个时刻发生，并通过 gp->status 不再是 Grunning 来指示。
func preemptone(pp *p) bool {
    // 获取 P 当前绑定的 M（机器线程）。
    mp := pp.m.ptr()
    // 如果 M 不存在或 M 与当前调用者的 M 相同，则无法抢占。
    if mp == nil || mp == getg().m {
       return false
    }

    // 获取 M 当前正在运行的 Goroutine。
    // 被抢占的 goroutine
    gp := mp.curg
    // 如果当前没有运行 Goroutine 或运行的是 M 的初始 Goroutine，则无法抢占。
    if gp == nil || gp == mp.g0 {
       return false
    }

    // 设置 Goroutine 的 preempt 标志为 true。
    // 这种标志可以被看作是 Goroutine 的一种外部状态标识，指示着 Goroutine 被强制中断执行
    // 这意味着当前正在执行的 Goroutine 会被暂停，让出 CPU，切换到其他 Goroutine 执行
    // 被标识为外部状态的 Goroutine 在调度器重新选择它作为下一个要执行的 Goroutine时，会被恢复执行
    gp.preempt = true

    // 将 Goroutine 的 stackguard0 设置为 stackPreempt。
    // 在 goroutine 内部的每次调用都会比较栈顶指针和 g.stackguard0，
    // 来判断是否发生了栈溢出。stackPreempt 非常大的一个数，比任何栈都大
    // stackPreempt = 0xfffffade
    gp.stackguard0 = stackPreempt

    // 请求异步抢占此 P。
    // 如果支持抢占并且异步抢占未被禁用，则设置 P 的 preempt 标志为 true 并调用 preemptM。
    if preemptMSupported && debug.asyncpreemptoff == 0 {
       pp.preempt = true
       // 请求外部操作系统来暂停并抢占一个特定的 M（机器线程），以便实现 Goroutine 的抢占式调度
       preemptM(mp) // 抢占 G
    }

    // 返回 true 表示抢占请求已发出。
    return true
}
```

1. **获取 M 和 gp**：
    - 获取处理器 P 当前绑定的 M。
    - 检查 M 是否存在且不是调用者的 M，如果不是，则无法抢占。
    - 获取 M 当前正在运行的 Goroutine。
    - 检查 gp 是否存在且不是 M 的初始 Goroutine，如果不是，则无法抢占。
2. **设置抢占标志**：
    - 设置 gp 的 preempt 标志为 true，表示请求抢占。
3. **设置 stackguard0**：
    - 设置 gp 的 stackguard0 为 stackPreempt，利用栈溢出检查机制实现抢占。
4. **请求异步抢占**：
    - 如果系统支持抢占并且异步抢占未被禁用，则设置 P 的 preempt 标志为 true，并调用 `preemptM` 来请求异步抢占。
5. **返回结果**：
    - 返回 true 表示抢占请求已发出。

#### preemptM抢占一个M,阻塞运行时间长的G

```go
// 函数请求操作系统暂停并抢占指定的 M，以便实现 Goroutine 的抢占式调度。
func preemptM(mp *m) {
    // 防止自我抢占。
    if mp == getg().m {
       throw("self-preempt")
    }

    // 同步外部代码，可能尝试 ExitProcess。
    if !atomic.Cas(&mp.preemptExtLock, 0, 1) {
       // 外部代码正在运行。抢占尝试失败。
       mp.preemptGen.Add(1)
       return
    }

    lock(&mp.threadLock)

    // 获取对 mp 的线程的引用。
    if mp.thread == 0 {
       // M 尚未初始化或刚刚被反初始化。
       unlock(&mp.threadLock)
       atomic.Store(&mp.preemptExtLock, 0)
       mp.preemptGen.Add(1)
       return
    }

    // 创建线程的句柄以及进行线程上下文的准备
    // （这一部分包括挂起线程、获取线程上下文、注入异步抢占点）
    // 详细的实现细节涉及到不同的 CPU 架构处理，如 x86、amd64、arm 和 arm64。

    var thread uintptr
    if stdcall7(_DuplicateHandle, currentProcess, mp.thread, currentProcess, uintptr(unsafe.Pointer(&thread)), 0, 0, _DUPLICATE_SAME_ACCESS) == 0 {
       print("runtime.preemptM: duplicatehandle failed; errno=", getlasterror(), "\n")
       throw("runtime.preemptM: duplicatehandle failed")
    }

    unlock(&mp.threadLock)

    // 准备线程上下文缓冲区。必须对齐至 16 字节。
    var c *context
    var cbuf [unsafe.Sizeof(*c) + 15]byte
    c = (*context)(unsafe.Pointer((uintptr(unsafe.Pointer(&cbuf[15]))) &^ 15))
    c.contextflags = _CONTEXT_CONTROL

    lock(&suspendLock)

    // 序列化线程挂起。SuspendThread 是异步的，可能两个线程相互挂起并死锁。
    // 必须持有此锁直到 GetThreadContext 后，因为该函数会阻塞直到线程实际挂起。

    // 异步挂起线程。
    if int32(stdcall1(_SuspendThread, thread)) == -1 {
       unlock(&suspendLock)
       stdcall1(_CloseHandle, thread)
       atomic.Store(&mp.preemptExtLock, 0)
       // 线程不再存在。虽然不应该发生，但确认请求。
       mp.preemptGen.Add(1)
       return
    }

    // 我们必须非常小心，在这一点和显示 mp 处于异步安全点之间。
    // 类似信号处理器，mp 可以在我们停止它时做任何事情，包括持有任意锁。

    // 必须在检查 M 之前获取线程上下文，因为 SuspendThread 只请求挂起。
    // GetThreadContext 实际上会阻塞直到线程被挂起。
    // 1. 获取线程的寄存器值：可以获得线程在被挂起时各寄存器的当前值，如栈指针、指令指针等。
    // 2. 获取线程的运行状态：可以获知线程被挂起时处于的具体状态，有助于后续对线程的调度和操作。
    // 3. 为后续操作提供正确的上下文信息：获取线程上下文后，可以根据实际情况进行后续的处理，如根据上下文信息进行异步抢占点的注入等操作。
    stdcall2(_GetThreadContext, thread, uintptr(unsafe.Pointer(c)))

    unlock(&suspendLock)

    // 它是否想要抢占并且安全抢占？
    gp := gFromSP(mp, c.sp())
    if gp != nil && wantAsyncPreempt(gp) {
       if ok, newpc := isAsyncSafePoint(gp, c.ip(), c.sp(), c.lr()); ok {
          // 进行异步抢占点的注入
          // 注入调用 asyncPreempt
          targetPC := abi.FuncPCABI0(asyncPreempt)
          switch GOARCH {
          default:
             throw("unsupported architecture")
          case "386", "amd64":
             // 获取当前栈指针的位置，然后向栈指针减去 goarch.PtrSize，以便为注入的数据腾出空间
             sp := c.sp()
             sp -= goarch.PtrSize

             // 将新的目标 PC 程序计数器地址 newpc 写入到栈指针指向的位置，这样在执行返回指令时会跳转到异步抢占函数，实现抢占点的触发
             *(*uintptr)(unsafe.Pointer(sp)) = newpc

             // 更新上下文中的栈指针和指令指针为注入异步抢占点后的新值，以便后续的上下文设置能够正确执行。
             c.set_sp(sp)
             c.set_ip(targetPC)

          case "arm":
             // 获取当前栈指针的位置，然后向栈指针减去 goarch.PtrSize，以便为注入的数据腾出空间
             sp := c.sp()
             sp -= goarch.PtrSize

             // 更新线程上下文的栈指针为调整后的新值，确保后续操作在正确的栈位置进行
             c.set_sp(sp)
             // 将当前的 Link Register（LR）的值写入到栈指针指向的位置，保存当前的返回地址
             *(*uint32)(unsafe.Pointer(sp)) = uint32(c.lr())

             // LR 指向了异步抢占函数的地址，IP 指向了异步抢占点的目标地址，确保在恢复线程执行时能够正确跳转到异步抢占函数
             c.set_lr(newpc - 1)
             c.set_ip(targetPC)

          case "arm64":
             // 获取当前栈指针的位置，然后向栈指针减去 goarch.PtrSize，以便为注入的数据腾出空间
             sp := c.sp() - 16 // SP 需要 16 字节对齐

             // 更新线程上下文的栈指针为调整后的新值，确保后续操作在正确的栈位置进行
             c.set_sp(sp)
             // 将当前的 Link Register（LR）的值写入到栈指针指向的位置，保存当前的返回地址
             *(*uint64)(unsafe.Pointer(sp)) = uint64(c.lr())

             // LR 指向了异步抢占函数的地址，IP 指向了异步抢占点的目标地址，确保在恢复线程执行时能够正确跳转到异步抢占函数
             c.set_lr(newpc)
             c.set_ip(targetPC)
          }

          // 将修改后的上下文设置回线程，以实现 Goroutine 的暂停并转移
          stdcall2(_SetThreadContext, thread, uintptr(unsafe.Pointer(c)))
       }
    }

    // 清除 mp.preemptExtLock，表明抢占已完成。
    atomic.Store(&mp.preemptExtLock, 0)

    // 确认抢占。
    mp.preemptGen.Add(1)

    // 恢复线程并关闭句柄
    stdcall1(_ResumeThread, thread)
    stdcall1(_CloseHandle, thread)
}
```

1. **防止自我抢占**：
    - 如果 `mp` 与当前 Goroutine 的 M 相同，则抛出错误。
2. **同步外部代码**：
    - 尝试原子地设置 `mp.preemptExtLock`，以防止外部代码尝试退出进程。
3. **获取线程句柄**：
    - 获取对 `mp` 的线程的引用，如果线程不存在，则返回。
4. **准备线程上下文**：
    - 创建一个对齐至 16 字节的上下文缓冲区。
5. **序列化线程挂起**：
    - 挂起线程，防止两个线程相互挂起导致死锁。
6. **挂起线程**：
    - 如果挂起失败，释放资源并返回。
7. **获取线程上下文**：
    - 阻塞直到线程实际被挂起，并获取其上下文。
8. **检查是否可以抢占**：
    - 检查 Goroutine 是否希望抢占并且是否处于安全点。
9. **注入抢占调用**：
    - 如果可以抢占，修改上下文以注入对 `asyncPreempt` 的调用。
10. **设置线程上下文**：
    - 将修改后的上下文设置回线程。
11. **释放抢占锁**：
    - 清除 `mp.preemptExtLock`，表明抢占已完成。
12. **确认抢占**：
    - 增加 `mp.preemptGen`，确认抢占请求。
13. **恢复线程**：
    - 恢复线程并关闭句柄。

抢占的逻辑就分析到这里的, M将一个正在执行的G进行阻断停止执行, 并标识为抢占。

- 此 M 任务立即被执行完成, 将这个goroutine移出执行栈, 让出 CPU，切换到其他 Goroutine 执行

```go
    // 设置 Goroutine 的 preempt 标志为 true。
    // 这种标志可以被看作是 Goroutine 的一种外部状态标识，指示着 Goroutine 被强制中断执行
    // 这意味着当前正在执行的 Goroutine 会被暂停，让出 CPU，切换到其他 Goroutine 执行
    // 被标识为外部状态的 Goroutine 在调度器重新选择它作为下一个要执行的 Goroutine时，会被恢复执行
    gp.preempt = true
```

### 调度器 p 可能阻塞, 重新分配 P 到其他 M

```go
// 只要满足下面三个条件之一，则抢占该 p，否则不抢占
// 1. p 的运行队列里面有等待运行的 goroutine
// 2. 所在的 M 线程正在执行
// 3. 从上一次监控线程观察到 p 对应的 m 处于系统调用之中到现在已经超过 10 毫秒
if runqempty(pp) && sched.nmspinning.Load()+sched.npidle.Load() > 0 && pd.syscallwhen+10*1000*1000 > now {
    continue
}

// 尝试原子更新 P 的状态，将其从系统调用状态变为空闲状态。
if atomic.Cas(&pp.status, s, _Pidle) {
    n++
    pp.syscalltick++
    // 将 P 的控制权交给另一个 M。
    handoffp(pp)
}
```

只要满足下面三个条件之一，则抢占该 p，否则不抢占

1. **p 的运行队列里面有等待运行的 goroutine**
2. **所在的 M 线程正在执行**
3. **从上一次监控线程观察到 p 对应的 m 处于系统调用之中到现在已经超过 10 毫秒**

确定要抢占当前 p 后，调用 `handoffp` 进行抢占。

### handoffp抢占阻塞的 P 重新分配

```go
// 函数用于从系统调用或锁定状态中释放 P。将 P 的控制权交给另一个 M。
// 此函数总是在无 P 的上下文中运行，因此不允许写屏障。
//
//go:nowritebarrierrec
func handoffp(pp *p) {
    // handoffp 必须在任何 findrunnable 查找 G 可能返回要在 pp 上运行的 G 的情况下启动 M。

    // 如果有本地任务或者全局队列有任务，直接启动 M。
    if !runqempty(pp) || sched.runqsize != 0 {
       startm(pp, false, false) // 调度一个 M 来运行 P（如果有必要，创建一个新的 M）
       return
    }

    // 如果有跟踪工作要做，直接启动 M。
    if (traceEnabled() || traceShuttingDown()) && traceReaderAvailable() != nil {
       // 调度一个 M（机器线程）来运行 P（处理器），如果必要的话，会创建一个新的 M
       startm(pp, false, false)
       return
    }

    // 如果有 GC 工作，直接启动 M。
    if gcBlackenEnabled != 0 && gcMarkWorkAvailable(pp) {
       // 调度一个 M（机器线程）来运行 P（处理器），如果必要的话，会创建一个新的 M
       startm(pp, false, false)
       return
    }

    // 如果没有旋转或空闲的 M，直接启动 M 来处理可能的工作
    if sched.nmspinning.Load()+sched.npidle.Load() == 0 && sched.nmspinning.CompareAndSwap(0, 1) { // TODO: fast atomic
       sched.needspinning.Store(0)
       // 调度一个 M（机器线程）来运行 P（处理器），如果必要的话，会创建一个新的 M
       startm(pp, true, false)
       return
    }

    // 获取调度器锁。
    lock(&sched.lock)

    // 如果 GC 等待中，设置 P 状态为 _Pgcstop，减少 stopwait 计数。
    if sched.gcwaiting.Load() {
       pp.status = _Pgcstop
       sched.stopwait--
       if sched.stopwait == 0 {
          notewakeup(&sched.stopnote)
       }
       unlock(&sched.lock)
       return
    }

    // 如果有安全点函数需要运行，执行它。
    if pp.runSafePointFn != 0 && atomic.Cas(&pp.runSafePointFn, 1, 0) {
       sched.safePointFn(pp)
       sched.safePointWait--
       if sched.safePointWait == 0 {
          notewakeup(&sched.safePointNote)
       }
    }

    // 如果全局运行队列中有工作，解锁调度器锁并启动 M。
    if sched.runqsize != 0 {
       unlock(&sched.lock)
       // 调度一个 M（机器线程）来运行 P（处理器），如果必要的话，会创建一个新的 M
       startm(pp, false, false)
       return
    }

    // 如果这是最后一个运行的 P，且没有人正在轮询网络，直接启动 M。
    if sched.npidle.Load() == gomaxprocs-1 && sched.lastpoll.Load() != 0 {
       unlock(&sched.lock)
       // 调度一个 M（机器线程）来运行 P（处理器），如果必要的话，会创建一个新的 M
       startm(pp, false, false)
       return
    }

    // 调度器锁不能在下面调用 wakeNetPoller 时持有，
    // 因为 wakeNetPoller 可能调用 wakep，进而可能调用 startm。
    when := nobarrierWakeTime(pp)
    pidleput(pp, 0) // 没有工作要处理，把 p 放入全局空闲队列
    unlock(&sched.lock)

    // 如果有唤醒时间，唤醒网络轮询器。
    if when != 0 {
       wakeNetPoller(when)
    }
}
```

1. **检查本地工作**：

    - 如果 P 有本地工作或全局运行队列不为空，直接启动 M 来处理。

2. **检查跟踪工作**：

    - 如果有跟踪工作，直接启动 M 来处理。

3. **检查 GC 工作**：

    - 如果有 GC 工作，直接启动 M 来处理。

4. **检查旋转/空闲的 M**：

    - 如果没有旋转或空闲的 M，启动 M 来处理可能的工作。

5. **处理 GC 等待**：

    - 如果 GC 等待中，设置 P 状态为 _Pgcstop 并减少 stopwait 计数。

6. **处理安全点函数**：

    - 如果有安全点函数需要运行，执行它并减少 safePointWait 计数。

7. **检查全局运行队列**：

    - 如果全局运行队列中有工作，启动 M 来处理。

8. **检查最后一个运行的 P**：

    - 如果这是最后一个运行的 P，且没有人正在轮询网络，唤醒另一个 M 来轮询网络。

9. **没有工作要处理**:

    - 把 p 放入全局空闲队列

10. **释放调度器锁**：

    - 在释放锁之前，获取 P 的唤醒时间。

11. **唤醒网络轮询器**：

    - 如果有唤醒时间，唤醒网络轮询器。

这里用的最多的就是:

```go
// 调度一个 M（机器线程）来运行 P（处理器），如果必要的话，会创建一个新的 M
startm(pp, false, false)
```

### startm调度一个M线程运行P

我们接着来看 `startm` 函数都做了些什么：

```go
// 函数调度一个 M 来运行 P（如果有必要，创建一个新的 M）。
// 如果 p 为 nil，则尝试获取一个空闲的 P，如果没有空闲的 P，则什么也不做。
// 可能在没有 m.p 的情况下运行，所以不允许写屏障。
// 如果 spinning 设置为真，调用者已经增加了 nmspinning 并且必须提供一个 P。startm 将会在新启动的 M 中设置 m.spinning。
//
// 传递非 nil P 的调用者必须从不可抢占的上下文中调用。参见 acquirem 注释。
//
// lockheld 参数指示调用者是否已经获取了调度器锁。持有锁的调用者在调用时必须传入 true。锁可能会暂时被释放，但在返回前会重新获取。
//
// 必须没有写屏障，因为这可能在没有 P 的情况下被调用。
//
//go:nowritebarrierrec
func startm(pp *p, spinning, lockheld bool) {
    // 禁止抢占。
    //
    // 每个拥有的 P 必须有一个最终会停止它的所有者，以防 GC 停止请求。
    // startm 临时拥有 P（来自参数或 pidleget），并将所有权转移给启动的 M，后者将负责执行停止。
    //
    // 在这个临时所有权期间，必须禁用抢占，否则当前运行的 P 可能在仍持有临时 P 的情况下进入 GC 停止，导致 P 悬挂和 STW 死锁。
    //
    // 传递非 nil P 的调用者必须已经在不可抢占的上下文中，否则这样的抢占可能在 startm 函数入口处发生。
    // 传递 nil P 的调用者可能是可抢占的，所以我们必须在下面从 pidleget 获取 P 之前禁用抢占。

    // 获取当前线程 m
    mp := acquirem()
    if !lockheld {
       lock(&sched.lock)
    }

    // 尝试从空闲 P 队列中获取一个 P
    if pp == nil {
       if spinning {
          // TODO(prattmic): 对该函数的所有剩余调用
          // 用 _p_ = = nil可以清理找到一个p
          // 在调用startm之前。
          throw("startm: P required for spinning=true")
       }

       // 没有指定 p 则需要从全局空闲队列中获取一个 p
       pp, _ = pidleget(0)
       // 没有找到空闲 P，释放锁并返回
       if pp == nil {
          if !lockheld {
             unlock(&sched.lock)
          }
          releasem(mp)
          return
       }
    }

    // 尝试从空闲 M 队列中获取一个 M
    nmp := mget()

    // 如果没有可用的 M，预分配一个新的 M 的 ID，释放锁，然后调用 newm 创建一个新的 M
    if nmp == nil {
       id := mReserveID() // 配一个新的 M 的 ID
       // 释放锁
       unlock(&sched.lock)

       var fn func()
       if spinning {
          // 调用者递增nmspinning，因此在新的m中设置M.spinning。
          fn = mspinning
       }

       newm(fn, pp, id) // 创建一个新的 M

       if lockheld {
          lock(&sched.lock)
       }
       // 所有权转移在 newm 的 start 中完成。现在抢占是安全的。
       releasem(mp)
       return
    }

    if !lockheld {
       unlock(&sched.lock)
    }

    // 如果获取的 M 已经在自旋，抛出错误
    if nmp.spinning {
       throw("startm: m is spinning")
    }
    // 如果 M 已经拥有一个 P，抛出错误
    if nmp.nextp != 0 {
       throw("startm: m has p")
    }
    // 如果 spinning 为真且 P 的运行队列不为空，抛出错误
    if spinning && !runqempty(pp) {
       throw("startm: p has runnable gs")
    }

    nmp.spinning = spinning // 新 M 中设置 m.spinning。
    nmp.nextp.set(pp)       // 设置 m 马上要分配的 p
    notewakeup(&nmp.park)   // 函数唤醒等待在 note 上的一个线程。
    // 所有权转移在 wakeup 中完成。现在抢占是安全的。
    releasem(mp)
}
```

1. **禁止抢占**：

    - 禁止抢占以防止当前运行的 P 在持有临时 P 的情况下进入 GC 停止，这会导致死锁。

2. **获取 M**：

    - 调用 `acquirem` 来获取一个 M。

3. **检查锁持有状态**：

    - 如果没有持有锁，获取 `sched.lock`。

4. **获取 P**：

    - 如果 `pp` 为 `nil`，尝试从空闲 P 队列中获取一个 P。
    - 如果没有找到空闲 P，释放锁并返回。

5. **获取或创建 M**：

    - 尝试从空闲 M 队列中获取一个 M。
    - 如果没有可用的 M，预分配一个新的 M 的 ID，释放锁，然后调用 `newm` 创建一个新的 M。

6. **设置 M 属性**：

    - 如果获取的 M 已经在自旋，抛出错误。
    - 如果 M 已经拥有一个 P，抛出错误。
    - 如果 `spinning` 为真且 P 的运行队列不为空，抛出错误。
    - 设置 M 的 `spinning` 属性。
    - 将 P 分配给 M。

7. **唤醒 M**：

    - 调用 `notewakeup` 来唤醒 M，使其开始运行。

8. **释放锁和 M**：

    - 释放 `sched.lock`（如果之前获取过）。
    - 释放获取的 M（`mp`）。

## 检查是否需要触发超时2分钟的强制 GC

```go
		// 根据不同的触发条件来决定是否需要启动一个新的 GC 周期。
		// 创建临时 gcTrigger 实例: 创建一个临时的 gcTrigger 实例，其 kind 为 gcTriggerTime 强制gc标识，now 字段为当前时间。
		// 调用 test 方法: 调用 gcTrigger 实例的 test 方法来检查是否需要触发超时2分钟的强制 GC。
		// 检查是否处于空闲状态: 检查 forcegc.idle 是否为 true，即 GC 是否处于空闲状态, 才允许强制gc
		if t := (gcTrigger{kind: gcTriggerTime, now: now}); t.test() && forcegc.idle.Load() { // test(): 根据不同的触发条件来决定是否需要启动一个新的 GC 周期。
			lock(&forcegc.lock) // 加锁以确保对 forcegc 结构体的操作是原子的。

			forcegc.idle.Store(false) // 将 forcegc.idle 设置为 false，表示 GC 不再处于空闲状态。
			var list gList            // 创建一个 gList 结构体，用于存放需要注入的 goroutine。
			list.push(forcegc.g)      // 将 forcegc.g 添加到 gList 中。
			injectglist(&list)        // 将 forcegc.g 注入到运行队列中，使其可以被调度执行。

			// 解锁以释放对 forcegc 结构体的独占访问。
			unlock(&forcegc.lock)
		}
```

# 总结

1. **如果超过 10 毫秒没有进行网络轮询，则进行网络轮询**
    - 检测之前因为网络 io 阻塞的 goroutine, 有哪些已经非阻塞了
    - 找到并加入到可运行队列
2. **重新获取被系统调用阻塞的 P，并抢占长时间运行的 G**
    - 检测长时间运行的goroutine, 暂停他们的执行, 移除cpu执行权, 等待下次调度
    - 如果一个 p 调度器有任务, 但是长时间没有调度任务, 那么将重新分配一个线程来调度这个P

3. **最后还有一个触发超时2分钟的强制 GC**
    - 这个是垃圾回收的一个逻辑
    - 如果`GC`超过2分钟都没有执行, 需要强制执行一次

