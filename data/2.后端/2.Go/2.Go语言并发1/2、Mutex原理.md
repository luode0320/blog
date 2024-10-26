# 简介

在Go语言中，`Mutex` 类型是用于同步的互斥锁。

互斥锁是一种控制多个并发线程对共享资源访问的机制，确保同一时刻只有一个线程能够访问这个资源。

# 源码解析

`src/sync/mutex.go`

## 数据结构

```go
// Mutex 是一个互斥锁。
// Mutex 的零值是一个未上锁的互斥锁实例。
//
// 在首次使用后，Mutex 实例不应被复制。
//
// 根据 Go 语言的内存模型，
// 第 n 次调用 Unlock "发生在" 第 m 次调用 Lock "之前"
// 对于任何 n < m 的情况(加锁的次数永远大于解锁的次数)。
// 成功的 TryLock 调用等同于 Lock 调用。
// 失败的 TryLock 调用不建立任何 "发生在" 的关系。
type Mutex struct {
	// state 是一个 32 位整数，用来存储锁的状态信息。
	// 1.通过状态位来区分锁是否被持有,是否处于饥饿状态, 是否处于等待状态, 是否处于竞争状态
	// 2.持有者的等待队列长度
	state int32

	// sema 是一个 32 位无符号整数，作为信号量使用。
	// 当 Mutex 被解锁时，会将 sema 唤醒，允许等待的 goroutine 获取锁。
	sema uint32
}
```

几个重要的状态

```go
const (
	// 将 iota 左移 0 位，相当于 1，表示互斥锁被锁定
	mutexLocked = 1 << iota
	// 这个状态表示一个 Goroutine 已经被唤醒，可以继续执行
	mutexWoken
	//这个状态表示一个 Goroutine 处于饥饿状态，即在只读模式下被锁阻塞等待锁
	mutexStarving
	// 表示一个用来保存等待 Goroutine 数量的位数
	mutexWaiterShift = iota
)
```

为了更进一步理解 `Mutex` 的工作原理，通常需要查看其配套的方法实现

```go
// 加锁
func (m *Mutex) Lock()
// 尝试加锁
func (m *Mutex) TryLock() bool
// 释放锁
func (m *Mutex) Unlock()
```

## Lock()加锁

**整体图:**

![img](../../../picture/1460000039855705)

```go
// Lock 锁定互斥锁 m。
// 如果锁已经被使用，调用该方法的 goroutine 将会阻塞，直到互斥锁变得可用。
func (m *Mutex) Lock() {
	// 快速路径：尝试获取未锁定的互斥锁。
	// 使用原子操作 CompareAndSwapInt32 来检查并设置 m.state 的值。
	// 如果 m.state 当前为 0（表示未锁定），则将其设置为 mutexLocked=1 常量, 表示互斥锁被锁定
	if atomic.CompareAndSwapInt32(&m.state, 0, mutexLocked) {
		// 如果启用了竞态检测（race detection），那么记录这个互斥锁的获取。
		// 这对于竞态检测工具来说非常重要，因为它可以跟踪锁的获取和释放事件。
		if race.Enabled {
			race.Acquire(unsafe.Pointer(m))
		}
		return
	}

	// 慢速路径：当互斥锁已经被其他 goroutine 占用时触发。
	// 此处将调用 lockSlow 方法，它包含了更复杂的逻辑来处理锁的竞争情况。
	m.lockSlow()
}
```

1. 先用 CAS 更新一次
2. CAS 更新失败调用 lockSlow 升级锁

### lockSlow()升级锁

```go
// lockSlow 函数是 Mutex.Lock 方法的慢速路径。
// 它在快速路径（CompareAndSwapInt32）无法立即获取锁时被调用，
// 即互斥锁已经被其他 goroutine 占用。
// 此函数处理锁的获取，包括自旋、加入等待队列和处理饥饿模式。
func (m *Mutex) lockSlow() {
	var waitStartTime int64 // 记录等待开始的时间戳，用于检测饥饿模式。
	var starving bool       // 标记当前 goroutine 是否处于饥饿模式。
	var awoke bool          // 标记当前 goroutine 是否从阻塞状态被唤醒。
	var iter int            // 自旋尝试次数，用于控制自旋频率。
	var old int32           // 保存互斥锁的旧状态，用于比较和交换操作。

	for {
		// 1.至少被锁了, 才可以自旋
		// 2.饥饿模式是一定不可以自旋的
		// 3.runtime_canSpin自旋的次数不可以超过active_spin=4次
		// 检查锁是否被占用或者处于非饥饿模式
		if old&(mutexLocked|mutexStarving) == mutexLocked && runtime_canSpin(iter) {
			// 当自旋有意义时，尝试设置 mutexWoken 标志位。
			// 这个标志告诉 Unlock 方法，当前 goroutine 已经被唤醒，不需要再唤醒其他 goroutines。
			if !awoke && old&mutexWoken == 0 && old>>mutexWaiterShift != 0 &&
				atomic.CompareAndSwapInt32(&m.state, old, old|mutexWoken) {
				awoke = true // 标记从睡眠中被唤醒
			}

			runtime_doSpin() // 执行一次自旋操作，等待锁的释放。
			iter++           // 增加自旋次数。
			old = m.state    // 更新旧状态，准备下一次 CAS。
			continue         // 继续循环，尝试获取锁。
		}

		// 准备更新的新状态，初始化为旧状态。
		new := old

		// 如果不是饥饿模式，尝试获取锁。
		// mutexLocked 标志位表示锁被占用。
		if old&mutexStarving == 0 {
			new |= mutexLocked
		}

		// 如果锁被占用或处于饥饿模式，增加等待队列计数, 等待队列数量 + 1。
		// mutexWaiterShift 是一个右移位数，用于计算等待队列的长度。
		if old&(mutexLocked|mutexStarving) != 0 {
			new += 1 << mutexWaiterShift
		}

		// 当前 goroutine 切换互斥锁至饥饿模式，前提是锁当前被占用。
		// 饥饿模式下，锁的所有权直接传递给等待队列中的下一个 goroutine。
		if starving && old&mutexLocked != 0 {
			new |= mutexStarving
		}

		// 如果当前 goroutine 已经被标记为唤醒状态，需要重置 mutexWoken 标志位。
		// mutexWoken 标志位表示一个 goroutine 已经被唤醒。
		if awoke {
			if new&mutexWoken == 0 {
				throw("sync: inconsistent mutex state")
			}
			new &^= mutexWoken
		}

		// 尝试使用 CAS 更新 state 状态，修改成功则表示获取到锁资源
		// 注意: 这个 cas 并不是真正加锁, 它只是为了防止这个if被并发执行
		// 理论上所有想要加锁的 goroutine 最终都会进入这个if, 只不过是谁快谁慢而已
		if atomic.CompareAndSwapInt32(&m.state, old, new) {
			// 如果 old 旧状态是非饥饿模式，并且未获取过锁, 说明旧状态是属于一个无锁的状态
			// 此时执行 cas 成功更新为加锁的状态，可以直接 return
			if old&(mutexLocked|mutexStarving) == 0 {
				break // 成功锁定互斥锁，退出循环。
			}

			// 如果旧状态已经是一个加锁的状态了, 就算更新成功了也没有意义
			// 因为你更新的不过是再阻塞队列里多加了一个 goroutine 而已, 锁依然是被占用的
			// 表示未能上锁成功

			// 如果之前已经在等待过至少一次，保持队列中 LIFO（后进先出）顺序。
			queueLifo := waitStartTime != 0
			if waitStartTime == 0 {
				// 如果还没开始等待，记录开始等待的时间
				waitStartTime = runtime_nanotime()
			}

			// 到这里，表示即将开始上锁, 如果上锁失败, 则阻塞

			// 函数的作用是尝试获取锁，如果锁已经被其他 Goroutine 持有，则当前 Goroutine 会被阻塞，加入等待队列，等待锁的释放
			// 当其他 Goroutine 释放了锁时，队头被阻塞的 Goroutine 会被唤醒
			// queueLife = true, 将会把 goroutine 放到等待队列队头
			// queueLife = false, 将会把 goroutine 放到等待队列队尾
			runtime_SemacquireMutex(&m.sema, queueLifo, 1)

			// 到这里，表示队头的 Goroutine 被唤醒, 继续执行下面代码

			// 检查是否切换到了饥饿模式。
			// 计算是否符合饥饿模式，即等待时间是否超过一定的时间
			starving = starving || runtime_nanotime()-waitStartTime > starvationThresholdNs

			// 更新旧状态，准备下一次 CAS。
			old = m.state

			// 如果上一次是饥饿模式, 此次唤醒队头的 goroutine 一定会获得锁, 加入该 if,调整锁状态 state 为加锁
			if old&mutexStarving != 0 {
				if old&(mutexLocked|mutexWoken) != 0 || old>>mutexWaiterShift == 0 {
					throw("sync: inconsistent mutex state")
				}

				// 调整状态，设置 mutexLocked 加锁状态并减少等待计数。
				// mutexLocked 标志位表示锁被占用，mutexWaiterShift 用于计算等待队列的长度。
				delta := int32(mutexLocked - 1<<mutexWaiterShift)

				// 此次不是饥饿模式又或者下次没有要唤起等待队列的 goroutine 了
				if !starving || old>>mutexWaiterShift == 1 {
					// 退出饥饿模式。
					// 这里很关键，因为饥饿模式效率低下，两个 goroutines 可能无限地步调一致地切换互斥锁到饥饿模式。
					// 一旦 goroutine 成功获取锁，就退出饥饿模式，以防止不必要的性能损耗。
					delta -= mutexStarving
				}

				atomic.AddInt32(&m.state, delta)
				break // 成功获取锁，退出循环。
			}

			// 如果上一次不是饥饿状态, 那么正常重置状态, 准备重新竞争锁
			// 这就会导致, 队列出来的锁会慢与已经正在获取锁的 goroutine
			// 因为, 从队列唤醒出来, 到这一行代码, 再继续回到 for 遍历 cas 判断肯定是慢于新 goroutine 的
			// 所以这个被唤醒的 goroutine 再竞争下, 很可能又会加入到等待队列的前面再次被阻塞
			awoke = true // 标记从睡眠中被唤醒
			iter = 0     // 重置自旋次数
		} else {
			// 如果 CAS 失败，更新旧状态并重试。
			// CAS 失败可能是因为另一个 goroutine 修改了状态，因此需要重新读取状态。
			old = m.state
		}
	}

	// 如果启用了竞态检测，记录互斥锁的获取。
	if race.Enabled {
		race.Acquire(unsafe.Pointer(m))
	}
}
```

2. 进入循环：
   a. 检查锁是否被占用且适合自旋，调用 `runtime_canSpin` 函数；
   b. 如果可以自旋，并且当前 Goroutine还未被唤醒且满足条件，则尝试设置 `mutexWoken` 标志位，并执行自旋操作；
   c. 更新自旋次数 `iter`、旧状态 `old`，继续下一轮循环。

5. 在未能成功上锁的情况下，执行以下步骤：
   a. 更新等待开始的时间戳等变量；
   b. 调用 `runtime_SemacquireMutex` 函数尝试获取锁，加入等待队列；

   ![image-20240814021639934](../../../picture/1460000039855708)
   
   c. 处理是否切换到饥饿模式，并更新旧状态 `old`；
   d. 根据是否饥饿模式和下一次是否需要唤醒队列中的 Goroutine，调整状态；
   e. 标记当前 Goroutine被唤醒，重置自旋次数。

6. 最终成功获取到锁后，退出循环，如果启用了竞态检测，记录互斥锁的获取。

## Unlock()解锁

![Unlock](../../../picture/1460000039855703)

```go
// Unlock 用于解锁。
// 如果在调用 Unlock 时 m 没有被锁住，这会引发运行时错误。
//
// 一个被锁住的 Mutex 并不与特定的 Goroutine 相关联。
// 允许一个 Goroutine 锁定一个 Mutex，然后安排另一个 Goroutine 解锁它。
func (m *Mutex) Unlock() {
	// 如果启用了竞态检测，记录互斥锁的状态，并释放锁的持有。
	// 这有助于在多 goroutine 环境中调试竞态条件。
	if race.Enabled {
		_ = m.state                     // 这一行用于确保编译器不会优化掉对 m.state 的引用。
		race.Release(unsafe.Pointer(m)) // 标记互斥锁被释放。
	}

	// 快速路径：清除锁标志。
	// 使用原子操作 AddInt32 来减少 m.state 的值，实际上相当于清除 mutexLocked 标志位。
	// 注意，这里使用负数（-mutexLocked）是因为 AddInt32 是加法操作，我们需要做的是减法。
	new := atomic.AddInt32(&m.state, -mutexLocked)

	// 如果 new 不为零，说明还有其他的标志位被设置，例如有等待的 goroutines 或者处于饥饿模式。
	// 这种情况下，需要调用慢速路径 unlockSlow 来处理剩余的逻辑。因为需要唤醒等待队列的协程
	if new != 0 {
		// 慢速路径被独立出来，以便快速路径能够被内联，提高性能。
		// 在追踪时，我们跳过额外的一帧来隐藏 unlockSlow 的调用，使追踪信息更加简洁。
		m.unlockSlow(new)
	}
}
```

1. 先用原子操作 CAS 对状态减一

    - 但是实际上只有被一个 goroutine 加锁解锁, 这个步骤才有效

    - 如果有被阻塞等待的 goroutine, 就必须执行系统级别的解锁步骤

2. CAS 更新失败调用 unlockSlow 解锁

### unlockSlow()解锁

```go
// 是 Mutex.Unlock 方法的慢速路径。
//
// 当快速路径（atomic.AddInt32）返回非零值时，即互斥锁还保留有其他标志位时，
// 此方法被调用来处理剩余的解锁逻辑。
func (m *Mutex) unlockSlow(new int32) {
	// 首先检查互斥锁是否实际上已经被解锁。
	// 如果在解锁操作之后，互斥锁的状态不包含 mutexLocked 标志位，这表明锁已被非法解锁。
	if (new+mutexLocked)&mutexLocked == 0 {
		fatal("sync: unlock of unlocked mutex")
	}

	// 处理正常解锁逻辑。
	if new&mutexStarving == 0 {
		// 保存互斥锁的旧状态
		old := new

		for {
			// 检查等待队列是否为空: 不需要唤醒其他goroutine, 直接返回
			// 有其他 goroutine 已经被唤醒或获取了锁, 直接返回
			if old>>mutexWaiterShift == 0 || old&(mutexLocked|mutexWoken|mutexStarving) != 0 {
				return
			}

			// 减少等待队列计数，
			new = (old - 1<<mutexWaiterShift) | mutexWoken

			// 尝试原子性地更新状态为新状态
			if atomic.CompareAndSwapInt32(&m.state, old, new) {
				// 释放信号量，唤醒等待队列的一个的 Goroutine
				// 信号量将按照先进先出（FIFO, First In First Out）的原则释放。
				// 这意味着，如果多个 goroutines 正在等待信号量，那么最早进入等待队列的 goroutine 将被唤醒
				runtime_Semrelease(&m.sema, false, 1)
				return
			}

			// 如果 CAS 失败，更新旧状态并重试。
			old = m.state
		}
	} else {
		// 饥饿模式：将互斥锁所有权交给下一个等待者，并且让出时间片，以便下一个等待者可以立即开始运行
		// 注意：未设置互斥锁标志位，等待者会在唤醒后设置它；但如果饥饿标志位已经设置，则新到来的 Goroutine 不会获取锁

		// 直接将锁的所有权传递给等待队列中的下一个 goroutine
		// 信号量将按照后进先出（LIFO, Last In First Out）的原则释放。
		// 这意味着最近进入等待队列的 goroutine 将被唤醒。
		// 因为饥饿模式下, 同一个 goroutine 一直获取锁, 一直失败
		// 失败后会将这个 goroutine , 加入到最前面, 而不是排在队列最后面
		runtime_Semrelease(&m.sema, true, 1)
	}
}
```

1. **检查非法解锁**：确保互斥锁在解锁之前确实是被锁定的，如果不是，则抛出致命错误。
2. **处理正常解锁**：在非饥饿模式下，检查等待队列，如果存在等待者，则尝试唤醒一个等待者。
3. **处理饥饿模式解锁**：在饥饿模式下，直接将锁的所有权传递给等待队列中的下一个 goroutine，并让出时间片以允许等待者立即开始运行。
4. **信号量释放**：使用 `runtime_Semrelease` 函数来释放信号量，允许等待队列中的 goroutine 被唤醒。

## TryLock()尝试加锁

```go
// TryLock 尝试锁定互斥锁 m，并报告是否成功。
//
// 注意：虽然使用 TryLock 的正确场景确实存在，但它们很少见，
// 使用 TryLock 往往是特定互斥锁使用场景中潜在问题的一个迹象
func (m *Mutex) TryLock() bool {
	old := m.state

	// 如果互斥锁当前被锁定或者处于饥饿模式，TryLock 快速失败。
	if old&(mutexLocked|mutexStarving) != 0 {
		return false
	}

	// 尽管可能有其他 goroutine 正在等待互斥锁，但我们当前正在运行，
	// 我们可以在那个 goroutine 被唤醒之前尝试获取互斥锁。
	if !atomic.CompareAndSwapInt32(&m.state, old, old|mutexLocked) {
		return false
	}

	// 如果启用了竞态检测，记录互斥锁的获取。
	if race.Enabled {
		race.Acquire(unsafe.Pointer(m))
	}
	
	return true
}
```

`TryLock` 方法的使用应当谨慎，因为它的正确使用场景相对较少。以下是一些关键点：

1. **状态检查**：在尝试获取锁之前，`TryLock` 检查锁的状态是否为 `mutexLocked` 或 `mutexStarving`
   。如果任一状态被设置，`TryLock` 将立即返回 `false`，表示获取锁失败。
2. **原子操作**：`TryLock` 使用 `atomic.CompareAndSwapInt32` 来尝试获取锁，这是一个原子操作，确保了即使在多核处理器上也能正确地获取锁。
3. **竞态检测**：如果竞态检测被启用，`TryLock` 将调用 `race.Acquire` 来记录互斥锁的获取，这对于调试和避免竞态条件非常有用。
4. **立即返回**：与 `Lock` 方法不同，`TryLock` 不会阻塞等待锁的可用性。如果锁不可用，`TryLock` 将立即返回 `false`
   ，调用者必须准备好处理这种情况。

`TryLock` 方法是使用 CAS 快速失败的加锁的方式, 它不涉及锁升级。

# 示例

## 加锁解锁示例

![加锁加锁](../../../picture/1460000039855700)

```go
package main

import (
	"sync"
	"fmt"
)

var m sync.Mutex

func main() {
	G1()
}

func G1() {
	// 尝试加锁
	m.Lock()

	// 执行一些任务...
	fmt.Println("G1 holds the lock")

	// 解锁
	m.Unlock()
}
```

## 没有加锁，直接解锁示例

![没有加锁直接解锁](../../../picture/1460000039855707)

```go
package main

import (
	"sync"
)

var m sync.Mutex

func main() {
	G1()
}

func G1() {
	// 尝试解锁
	m.Unlock()
}
```

运行结果:

```go
fatal error: sync: unlock of unlocked mutex                        
                                                                   
goroutine 1 [running]:                                             
sync.fatal({0x60ecd9?, 0x60?})                                     
        E:/go-1.21.0/src/runtime/panic.go:1061 +0x18               
sync.(*Mutex).unlockSlow(0x6c35c0, 0xffffffff)                     
        E:/go-1.21.0/src/sync/mutex.go:307 +0x35                   
sync.(*Mutex).Unlock(...)                                          
        E:/go-1.21.0/src/sync/mutex.go:295                         
main.G1(...)                                                       
        C:/Users/rod/GolandProjects/awesomeProject/mian.go:15      
main.main()                                                        
        C:/Users/rod/GolandProjects/awesomeProject/mian.go:10 +0x32
```

## 两个 Goroutine 互相加锁解锁示例

![互相加锁解锁](../../../picture/1460000039855706)

```go
package main

import (
	"fmt"
	"sync"
	"time"
)

var m sync.Mutex

func main() {
	go G1()
	go G2()
	time.Sleep(4 * time.Second) // 让 G1 和 G2 有机会执行
}

func G1() {
	// 尝试加锁
	m.Lock()

	// 执行一些任务...
	fmt.Println("G1 执行一些任务")

	time.Sleep(2 * time.Second)

	// 解锁
	m.Unlock()
}

func G2() {
	// 尝试加锁
	m.Lock()
}
```

## 三个 Goroutine 等待加锁示例

![三个 goroutine 等待加锁](../../../picture/1460000039855704)

```go
package main

import (
	"sync"
	"time"
	"fmt"
)

var m sync.Mutex

func main() {
	go G1()
	go G2()
	go G3()
	time.Sleep(20 * time.Second) // 让 G1、G2 和 G3 有机会执行
}

func G1() {
	// 尝试加锁
	m.Lock()

	// 执行一些任务...
	fmt.Println("G1 执行一些任务")

	// 让 G2 和 G3 等待
	time.Sleep(10 * time.Second)

	// 解锁
	m.Unlock()
}

func G2() {
	// 尝试加锁
	m.Lock()
}

func G3() {
	// 尝试加锁
	m.Lock()
}
```

## 什么是 Goroutine 排队

![排队](../../../picture/1460000039855708)



