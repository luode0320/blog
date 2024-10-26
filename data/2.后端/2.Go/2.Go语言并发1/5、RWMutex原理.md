# 简介

Go语言的RWMutex是一个读写锁，用于控制对共享资源的并发访问。

- 它不限制资源的并发读，但是读写、写写操作无法并行执行。

- 它提供了两种类型的锁定：读锁定和写锁定。
  - 读锁定允许同时有多个读者访问共享资源
  - 而写锁定只允许一个写者访问
  - 并且写锁定具有优先级高于读锁定。



# 原理解析

RWMutex包含两个互斥锁，一个是为读操作准备的，另一个是为写操作准备的。

- 当进行读锁定时，读锁计数器加1，然后检查是否有正在执行的写锁定。
  - 如果有，则阻塞直到写锁定释放。
- 当进行写锁定时，首先获取写锁，然后等待所有正在进行的读操作完成，然后再开始执行写操作。



**注意: 写锁的优先级是高于读锁的**

- 如果读锁1先加锁未释放, 然后写锁尝试加锁被阻塞
  - 此时再来一个读锁2想继续加读锁是不允许的, 会被阻塞
- 写锁只需要等待读锁1解锁即可加写锁完成
  - 这时候如果想唤醒被阻塞的读锁2, 只有等写锁释放才行



# 源码解析

`src/runtime/rwmutex.go`

## 数据结构

```go
// RWMutex 是一个读写互斥锁。它可以被任意数量的读者或单个写者持有。
// 锁定的状态可以通过读取或写入操作来改变。零值表示一个解锁状态的 RWMutex。
//
// RWMutex 在首次使用后不应复制。
type RWMutex struct {
	w         Mutex  // 写锁
	writerSem uint32 // 写者信号量, 用于等待完成的读者的信号
	readerSem uint32 // 读者信号量, 用于等待完成的写者的信号

	// 当前读者的数量
	// 当读者加锁时， readerCount  +1
	// 当读者解锁时， readerCount  -1
	// 1.当 readerCount 大于 0 时，表示有读者持有读锁。
	// 2.如果 readerCount 等于 0，则表示当前没有读者持有读锁,其他写者可以尝试获取写锁
	// 3.当 readerCount < 0 , 说明有写者在等待， 读者需要等待写者释放写锁
	readerCount atomic.Int32

	// 写者等待读锁的数量
	// 当写者尝试获取写锁，但当前有读者持有读锁时，写者会被阻塞，并且 readerWait 会增加。
	// 当读者释放读锁时，如果有写者在等待读锁，readerWait 会减少，并且可能唤醒等待的写者
	// 1.readerCount > 0：表示有读者持有读锁。
	// 2.readerCount == 0 且 readerWait > 0：表示没有读锁, 但是写者还在阻塞中, 可能正处理唤醒阶段。
	// 3.readerCount == 0 且 readerWait == 0：表示当前没有读者持有读锁，且没有写者在等待读锁。此时其他写者可以尝试获取写锁。
	readerWait atomic.Int32
}
```

为了更进一步理解 `Mutex` 的工作原理，通常需要查看其配套的方法实现

```go
// 加读锁
func (rw *RWMutex) RLock()
// 解读锁
func (rw *RWMutex) RUnlock()
// 加写锁
func (rw *RWMutex) Lock()
// 解写锁
func (rw *RWMutex) Unlock()
```



## RLock()加读锁

```go
// RLock 将 rw 加锁为读模式。
//
// 它不应该用于递归读锁定；一个阻塞的 Lock 调用将阻止新的读者获取锁。请参阅 RWMutex 类型的文档。
func (rw *RWMutex) RLock() {
	// 如果启用了竞态检测
	if race.Enabled {
		// 读取rw的状态以进行竞态检测, 避免垃圾回收
		_ = rw.w.state
		// 禁用竞争事件处理
		race.Disable()
	}

	// 递增读取者计数, 原子操作
	if rw.readerCount.Add(1) < 0 {
		// 当 readerCount < 0 , 说明有写者在等待， 读者需要等待写者释放写锁
		// readerSem: 读者信号量, 用于等待完成的写者的信号
		runtime_SemacquireRWMutexR(&rw.readerSem, false, 0) // Goroutine 阻塞加入等待队列，等待锁的释放
	}

	// 如果启用了竞态检测
	if race.Enabled {
		// 启用竞争事件处理
		race.Enable()
		// 记录读取操作的发生
		race.Acquire(unsafe.Pointer(&rw.readerSem))
	}
}
```

1. 如果竞态检测器启用，则禁用处理竞态同步事件（以提供更精确的模型给竞态检测器）；
2. 使用原子操作增加 `readerCount` 的值；
3. 如果 `readerCount` 增加后的值小于 0，则说明有一个写者正在等待，需要等待它释放, goroutine 在这里阻塞；
4. 如果竞态检测器启用，则恢复处理竞态同步事件并执行竞态检测器的获取操作。



读锁就是单纯用 CAS 控制的。



## RUnlock()解读锁

```go
// RUnlock 解锁单个 RLock 调用；
// 它不会影响其他同时存在的读取器。
// 如果进入 RUnlock 时 rw 没有被读取锁定, 则会发生运行时错误。
func (rw *RWMutex) RUnlock() {
	// 如果启用了竞态报告
	if race.Enabled {
		// 读取rw的状态以进行竞态检测, 避免垃圾回收
		_ = rw.w.state
		// 释放与当前 goroutine 关联的竞态报告事件，
		// 该事件将当前 goroutine 与其他 goroutines 同步。
		race.ReleaseMerge(unsafe.Pointer(&rw.writerSem))
		// 禁用竞态报告。
		race.Disable()
	}

	// 减少读取计数器 r，原子操作
	if r := rw.readerCount.Add(-1); r < 0 {
		// 如果 r 小于 0，说明有写者在等待, 读者需要等待写者释放写锁
		// 然后我们需要继续判断, 是否在这之前有写锁被读锁阻塞了, 去唤醒写锁
		rw.rUnlockSlow(r)
	}

	// 如果启用了竞态报告，则重新启用竞态报告。
	if race.Enabled {
		race.Enable()
	}
}
```

1. 如果竞态检测器启用，则执行竞态检测器的释放合并操作并禁用处理竞态同步事件；
2. 使用原子操作减少 `readerCount` 的值；
3. 如果 `readerCount` 减少后的值小于 0，如果 r 小于 0，理论上所有读锁都释放完成
4. **然后我们需要继续判断, 是否在这之前有写锁被读锁阻塞了, 去唤醒写锁**
5. 如果竞态检测器启用，则恢复处理竞态同步事件。



### rUnlockSlow()有写锁被读锁阻塞, 唤醒写锁

```go
// 唤醒一个写锁阻塞的 goroutine
func (rw *RWMutex) rUnlockSlow(r int32) {
	// 如果( r+1 等于 0 )或者(r+1 等于 -rwmutexMaxReaders)，
	// 表示发生了运行时错误，因为解锁了未加锁的 RWMutex。
	if r+1 == 0 || r+1 == -rwmutexMaxReaders {
		// 启用竞态报告功能。
		race.Enable()
		fatal("sync: RUnlock of unlocked RWMutex")
	}

	// (写者等待读锁的数量 -1 == 0), 说明最后一个读者已经离开了，进入唤醒写者阶段。
	if rw.readerWait.Add(-1) == 0 {
		runtime_Semrelease(&rw.writerSem, false, 1) // 唤醒一个写锁阻塞的 goroutine
	}
}
```



## Lock()加写锁

```go
// Lock 锁定 rw 以进行写入操作。
// 如果锁已被其他读取或写入操作锁定，Lock 方法会阻塞直到锁可用。
func (rw *RWMutex) Lock() {
	// 如果开启了竞争条件检测功能，则禁用竞争条件检测。
	if race.Enabled {
		_ = rw.w.state
		race.Disable()
	}

	// 首先，解决与其他写入者的竞争。
	rw.w.Lock()

	// 这个代码虽然最终的结果 r = 原来的 readerCount
	// 但是 rw.readerCount.Add(-rwmutexMaxReaders[默认值为 1073741824]), 已经将 readerCount 设置为负数了
	// 当 readerCount < 0 , 说明有写者在等待, 读者需要等待写者释放写锁
	r := rw.readerCount.Add(-rwmutexMaxReaders) + rwmutexMaxReaders

	// 执行完成上面的将 readerCount 设置为负数, 就表明已经将写锁排进去了
	// 从此刻开始, 只要之前加的读锁都解锁, 写锁就可以正常加上
	// 并且这个写锁之后新加读锁都加入等待队列, 必须在这个写锁释放后才可以唤醒
	// 这也说明了上面的代码有另一个含义: 写锁的优先级高于读锁

	// 检测是否有任意一个读锁, 如果有, 先阻塞此 goroutine, 等待释放完读锁后唤醒它
	if r != 0 && rw.readerWait.Add(r) != 0 {
		runtime_SemacquireRWMutex(&rw.writerSem, false, 0) // goroutine 加入等待队列, 等待唤醒
	}

	// 如果开启了竞争条件检测功能，则重新启用竞争条件检测。
	if race.Enabled {
		race.Enable()
		race.Acquire(unsafe.Pointer(&rw.readerSem))
		race.Acquire(unsafe.Pointer(&rw.writerSem))
	}
}
```

1. 如果开启了竞争条件检测功能，则禁用竞争条件检测。
2. 解决与其他写入者的竞争。
3. 将 `readerCount` 设置为负数，表示已经有写者在等待，读者需要等待写者释放写锁。
4. 检查是否有任意一个读锁，如果有，则阻塞此 Goroutine，等待释放完读锁后唤醒它。
5. 如果开启了竞争条件检测功能，则重新启用竞争条件检测。



这里有个很有意思的点: **将 readerCount 设置为负数**

- 因为在 `RLock()`加读锁的逻辑中, 如果readerCount 递增小于0, 这个加读锁的 goroutine 是要被阻塞的

```go
	// 递增读取者计数, 原子操作
	if rw.readerCount.Add(1) < 0 {
		// 如果首次加读锁, 已经存在一个写锁，等待写锁释放
		// readerSem: 读者信号量, 用于等待完成的写者的信号
		runtime_SemacquireRWMutexR(&rw.readerSem, false, 0) // Goroutine 阻塞加入等待队列，等待锁的释放
	}
```

- 也就是说, 一旦执行了加写锁,  **将 readerCount 设置为负数**, 后续的任何读锁都不能加了, 都会被阻塞



## Unlock()解写锁

```go
// Unlock 方法用于解锁写入锁 rw。如果在调用 Unlock 时 rw 并未被写入锁定，则会触发运行时错误。
//
// 类似于互斥锁（Mutex），已经加锁的 RWMutex 并不与特定的 goroutine 关联。一个 goroutine 可以对 RWMutex 进行
// RLock（Lock）操作，然后安排另一个 goroutine 来执行 RUnlock（Unlock）操作。
func (rw *RWMutex) Unlock() {
	// 如果启用了竞争检测
	if race.Enabled {
		_ = rw.w.state
		race.Release(unsafe.Pointer(&rw.readerSem))
		race.Disable()
	}

	// 在加写锁时, 将 readerCount 反转为了负数, 这里将它反转回来, 表示写锁已经准备释放
	// 标识从此刻开始, 如果出现加读锁, 是可以正常加了, 但是之前被阻塞的读锁, 会在下面逐步唤醒
	r := rw.readerCount.Add(rwmutexMaxReaders)

	// 从此时开始, 写锁准释放, 读锁可以正常加了, 但是还没有真正释放 Mutex 同步锁
	// 所以此刻的如果有并发的写锁也是不行的, 但是并发的读锁已经可以了

	// 如果 reader 数目大于等于 rwmutexMaxReaders, 表示你解锁了一个没有加锁的锁
	// 则触发运行时错误
	if r >= rwmutexMaxReaders {
		race.Enable()
		fatal("sync: Unlock of unlocked RWMutex")
	}

	// 唤醒阻塞的读取者: 因为写锁的优先级高, 所以在成功加写锁的过程中, 读锁都会被阻塞
	for i := 0; i < int(r); i++ {
		runtime_Semrelease(&rw.readerSem, false, 0)
	}

	// 允许其他写入者继续操作
	rw.w.Unlock()

	// 如果启用了竞争检测，则启用
	if race.Enabled {
		race.Enable()
	}
}
```

1. 如果启用了竞争检测，则禁用竞争检测。
2. 将 `readerCount` 反转回正数，表示写锁已经准备好释放。
3. 如果解锁了一个没有加锁的锁，则触发运行时错误。
4. 唤醒阻塞的读取者。
5. 允许其他写入者继续操作。
6. 如果启用了竞争检测，则启用。



这里的重点是: 

- 会优先放开读锁的获取, 再唤醒之前被阻塞的读锁, 再允许其他写入者加写锁



> 下面有两个不常用的方法



## TryRLock()尝试加读锁

```go
// TryRLock 尝试对 rw 进行读取锁定，并报告是否成功。
//
// 需要注意的是，虽然 TryRLock 的正确使用确实存在，但这种情况很少见，
// 而使用 TryRLock 往往表明在互斥锁的特定用法中存在更深层的问题。
func (rw *RWMutex) TryRLock() bool {
	// 如果开启了竞争条件检测功能，则禁用竞争条件检测。
	if race.Enabled {
		_ = rw.w.state
		race.Disable()
	}
	for {
		// 读取当前读取器计数。
		c := rw.readerCount.Load()

		// 如果读取器计数小于 0，表示出现错误（已经有写入者或其他情况）。
		if c < 0 {
			// 如果开启了竞争条件检测功能，则重新启用竞争条件检测。
			if race.Enabled {
				race.Enable()
			}
			return false
		}

		// 利用原子操作尝试增加读取器计数。
		if rw.readerCount.CompareAndSwap(c, c+1) {
			// 如果开启了竞争条件检测功能，则重新启用竞争条件检测。
			if race.Enabled {
				race.Enable()
				race.Acquire(unsafe.Pointer(&rw.readerSem))
			}
			return true
		}
	}
}
```

尝试加读锁只是简单使用了 CAS 进行状态控制。



## TryLock()尝试加写锁

```go
// TryLock 方法尝试对写入锁 rw 进行加锁，并报告是否成功加锁。
//
// 注意，尽管 TryLock 的正确使用确实存在，但很少见，使用 TryLock 经常是特定互斥锁使用中更深层次问题的迹象。
func (rw *RWMutex) TryLock() bool {
	// 如果启用了竞争检测
	if race.Enabled {
		_ = rw.w.state
		race.Disable()
	}

	// 尝试对读写锁进行加锁, CAS 快速失败返回
	if !rw.w.TryLock() {
		if race.Enabled {
			race.Enable()
		}
		return false
	}

	// 尝试将 readerCount 从 0 替换为 -rwmutexMaxReaders
	// 这个表示只要有任意一个读锁存在, 就不会成功
	if !rw.readerCount.CompareAndSwap(0, -rwmutexMaxReaders) {
		// 替换失败时，释放写入锁并返回加锁失败
		rw.w.Unlock()
		if race.Enabled {
			race.Enable()
		}
		return false
	}

	// 如果启用了竞争检测
	if race.Enabled {
		race.Enable()
		race.Acquire(unsafe.Pointer(&rw.readerSem))
		race.Acquire(unsafe.Pointer(&rw.writerSem))
	}
	return true
}
```

尝试加写锁只是简单使用了 CAS 进行状态控制。