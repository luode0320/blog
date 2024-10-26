# 简介

`sync.Map` 是 Go 语言标准库中的一个线程安全的键值对映射类型。

它提供了一个简单的方式存储和检索键值对，同时保证了并发访问的安全性。

下面我们将详细探讨 `sync.Map` 的内部实现原理。

# 源码

`src/sync/map.go`

## 数据结构

### Map

```go
// Map 并发安全的map结构体
//
// Map 类型是专门设计的。大多数代码应该使用普通的 Go 映射，结合单独的锁或协调机制，以获得更好的类型安全性和
// 更容易维护与映射内容相关的其他不变性。
//
// Map 类型针对两种常见的使用场景进行了优化：
// (1) 对于给定的键，其条目只被写入一次但被多次读取，如只增长的缓存，
// (2) 多个 goroutine 对互斥的键集进行读取、写入和覆盖。
// 在这些情况下，使用 sync.Map 可以显著减少与 Go 映射配对使用的单独 Mutex 或 RWMutex 的锁竞争。
//
// Map 的零值是空的并且准备使用。第一次使用后，不得复制 Map。
type Map struct {
	mu Mutex

	// read 存仅读数据，原子操作，并发读安全，实际存储readOnly类型的数据
	//
	// 在进行非读操作时，需要锁mu进行保护
	read atomic.Pointer[readOnly]

	// dirty 存最新写入的数据
	//
	// 写入的数据，都是直接写到dirty，后面根据read misses次数达到阈值，会进行read和dirty数据的同步
	dirty map[any]*entry

	// misses 计数器，每次在read字段中没找所需数据时，+1
	//
	// 当此值到达一定阈值时，将dirty字段赋值给read
	misses int
}
```

### readOnly

```go
// readOnly 存储mao中仅读数据的结构体
type readOnly struct {
	m       map[any]*entry // 其底层依然是个最简单的map
	amended bool           // 专门有一个标志位，用来标注read和dirty中是否有不同，以便进行read和dirty数据同步
}
```

### entry

```go
// 键值对中的值结构体
type entry struct {
	// 指针，指向实际存储value值的地方
	p atomic.Pointer[any]
}
```

## 关键方法

1. **`Load(key interface{}) (value interface{}, ok bool)`**:
    - 用于加载给定键对应的值。
    - 如果键存在，则返回对应的值和 `true`；如果键不存在，则返回零值和 `false`。
2. **`Store(key, value interface{})`**:
    - 用于将给定的键值对存储在映射中。
    - 如果键已经存在，则替换旧值。
3. **`Delete(key interface{})`**:
    - 用于删除给定键对应的值。
    - 如果键不存在，则没有效果。
4. **`Range(f func(key, value interface{}) bool)`**:
    - 用于遍历映射中的所有键值对。
    - 对于每个键值对，它都会调用函数 `f`。
    - 如果 `f` 返回 `false`，则迭代会停止。

## Load() 加载查询key

```go
// Load 返回映射中存储的键对应的值，如果没有值，则返回 nil。
// ok 结果表明值是否在映射中找到。
func (m *Map) Load(key any) (value any, ok bool) {
	// 加载当前的 read-only 映射。
	read := m.loadReadOnly()
	// 尝试从 read-only 映射中获取键对应的条目。
	e, ok := read.m[key]

	// 如果没有找到键对应的条目，并且 read-only 映射已被修改，amended标识dirty中存储的数据是否和read中的不一样
	if !ok && read.amended {
		// 则锁定 mu 以确保数据一致性。
		m.mu.Lock()

		// 再次尝试加载 read-only 映射，以防在等待锁的过程中 dirty 映射已被提升。
		read = m.loadReadOnly()
		// 尝试从 read-only 映射中获取键对应的条目。
		e, ok = read.m[key]

		// 如果仍然没有找到键对应的条目，并且 read-only 映射已被修改，
		// 则从 dirty 映射中查找键对应的条目。
		if !ok && read.amended {
			e, ok = m.dirty[key]
			// 无论是否找到了条目，都记录一次 miss，因为这个键将会走慢路径
			// 直到 dirty 映射被提升为 read 映射。
			m.missLocked()
		}
		m.mu.Unlock()
	}

	// 如果没有找到条目，则返回 nil 和 false。
	if !ok {
		return nil, false
	}

	// 加载条目中的值。
	return e.load()
}
```

1. **加载当前的 read-only 映射**:

    - 调用 `loadReadOnly` 方法获取当前的 read-only 映射。

2. **尝试从 read-only 映射中获取键对应的条目**:

    - 使用键 `key` 从 read-only 映射中获取对应的条目 `e`。
    - 如果没有找到条目，则检查 `read.amended` 是否为真。

3. **锁定 mu**:

    - 如果没有找到条目，并且 read-only 映射已被修改，则锁定 `mu` 以确保数据一致性。

4. **再次尝试加载 read-only 映射**:

    - 再次尝试加载 read-only 映射，以防在等待锁的过程中 dirty 映射已被提升。

5. **从 dirty 映射中查找键对应的条目**:

    - 如果仍然没有找到键对应的条目，并且 read-only 映射已被修改，则从 dirty 映射中查找键对应的条目。
    - 如果找到了条目，则返回条目中的值。
    - 如果没有找到条目，则记录一次 miss。

6. **解锁 mu**:

    - 解锁 `mu`。

7. **返回值**:

    - 如果找到了条目，则返回条目中的值和 `true`。
    - 如果没有找到条目，则返回 `nil` 和 `false`。

### loadReadOnly() 加载当前的 read-only 映射

```go
// 加载当前的 read-only 映射。
func (m *Map) loadReadOnly() readOnly {
	// 如果 read 指针不为空，则返回其指向的 read-only 映射的内容。
	if p := m.read.Load(); p != nil {
		return *p
	}
	// 如果 read 指针为空，则返回一个空的 read-only 映射。
	return readOnly{}
}
```

### missLocked() 达到阈值，dirty 提升为 read

```go
// 在持有锁的情况下处理 miss。
// 当读取操作未能直接从 read 映射中找到键对应的值时调用此方法。
// 如果 miss 的数量达到一定阈值，则将 dirty 映射提升为 read 映射。
func (m *Map) missLocked() {
	// 增加 miss 计数器。
	m.misses++
	// 如果 miss 的数量小于 dirty 映射中的条目数量，则直接返回。
	if m.misses < len(m.dirty) {
		return
	}

	// 将 dirty 映射提升为 read 映射。
	m.read.Store(&readOnly{m: m.dirty})
	// 清空 dirty 映射。
	m.dirty = nil
	// 重置 miss 计数器。
	m.misses = 0
}
```

### load() 加载 entry 条目中的值

```go
// load 从 entry 条目中加载值。
// 如果条目未被删除且包含有效值，则返回值和 true。
// 如果条目被删除或为空，则返回 nil 和 false。
func (e *entry) load() (value any, ok bool) {
	// 从 e.p 中加载指针。
	p := e.p.Load()

	// 如果指针为空或者等于 expunged 常量，则表示条目被删除或未分配。
	if p == nil || p == expunged {
		return nil, false
	}

	// 解引用指针以获取条目中的值。
	return *p, true
}
```

## Store() 设置键对应的值

```go
// Store 设置键对应的值。
// 这个方法通过调用 Swap 方法来实现。
func (m *Map) Store(key, value any) {
	// 调用 Swap 方法并将返回的旧值和是否交换成功的结果丢弃。
	_, _ = m.Swap(key, value)
}
```

### Swap() 比较和交换值存储

```go
// Swap 交换键对应的值，并返回之前的值（如果有）。
// loaded 结果报告键是否存在于映射中。
func (m *Map) Swap(key, value any) (previous any, loaded bool) {
	// 加载当前的 read-only 映射。
	read := m.loadReadOnly()
	// 尝试从 read-only 映射中获取键对应的条目。
	if e, ok := read.m[key]; ok {
		// 如果条目存在，则尝试交换值。
		if v, ok := e.trySwap(&value); ok {
			if v == nil {
				return nil, false
			}
			// 如果交换成功，则返回之前的值。
			return *v, true
		}
	}

	// 如果条目不存在或者交换失败，则锁定 mu 以确保数据一致性。
	m.mu.Lock()

	// 再次加载当前的 read-only 映射。
	read = m.loadReadOnly()
	// 再次尝试从 read-only 映射中获取键对应的条目。
	if e, ok := read.m[key]; ok {
		// 如果条目存在，则取消删除状态。
		if e.unexpungeLocked() {
			// 如果条目之前被删除，则确保 dirty 映射存在，并将条目添加到 dirty 映射中。
			m.dirty[key] = e
		}
		// 交换值。
		if v := e.swapLocked(&value); v != nil {
			// 如果交换成功，则返回之前的值。
			loaded = true
			previous = *v
		}
	} else if e, ok := m.dirty[key]; ok {
		// 如果条目在 dirty 映射中存在，则交换值。
		if v := e.swapLocked(&value); v != nil {
			// 如果交换成功，则返回之前的值。
			loaded = true
			previous = *v
		}
	} else {
		// 如果 read-only 映射没有被修改，则表示这是第一次向 dirty 映射中添加新的键。
		if !read.amended {
			// 确保 dirty 映射被分配，并标记 read-only 映射为不完整。
			m.dirtyLocked()
			m.read.Store(&readOnly{m: read.m, amended: true})
		}
		// 向 dirty 映射中添加新的条目。
		m.dirty[key] = newEntry(value)
	}

	// 解锁 mu。
	m.mu.Unlock()

	// 返回之前的值和是否找到键的标志。
	return previous, loaded
}
```

1. **加载 read-only 映射**:
    - 调用 `loadReadOnly` 方法加载当前的 read-only 映射。
2. **尝试交换值**:
    - 尝试从 read-only 映射中获取键对应的条目。
    - 如果条目存在，则尝试交换值。
    - 如果交换成功，则返回之前的值。
3. **锁定 mu**:
    - 如果条目不存在或者交换失败，则锁定 `mu` 以确保数据一致性。
4. **再次加载 read-only 映射**:
    - 再次加载当前的 read-only 映射，以防在等待锁的过程中 dirty 映射已被提升。
5. **再次尝试交换值**:
    - 再次尝试从 read-only 映射中获取键对应的条目。
    - 如果条目存在，则取消删除状态，并在 dirty 映射中添加条目。
    - 交换值。
    - 如果交换成功，则返回之前的值。
6. **添加新的键**:
    - 如果条目不存在，并且 read-only 映射没有被修改，则表示这是第一次向 dirty 映射中添加新的键。
    - 确保 dirty 映射被分配，并标记 read-only 映射为不完整。
    - 向 dirty 映射中添加新的条目。
7. **解锁 mu**:
    - 解锁 `mu`。
8. **返回值**:
    - 返回之前的值和是否找到键的标志。

### trySwap() 尝试交换

```go
// 尝试交换条目中的值，前提是该条目未被删除。
//
// 如果条目已被删除，则 `trySwap` 返回 false 并且不改变条目。
func (e *entry) trySwap(i *any) (*any, bool) {
	// 循环尝试交换值，直到成功或发现条目已被删除。
	for {
		// 加载当前条目中的值指针。
		p := e.p.Load()

		// 如果条目已被删除，则返回 nil 和 false。
		if p == expunged {
			return nil, false
		}

		// 尝试原子地交换值。
		if e.p.CompareAndSwap(p, i) {
			return p, true
		}
	}
}
```

### dirtyLocked() 初始化 dirty 映射

```go
// 在持有锁的情况下初始化 dirty 映射。
// 如果 dirty 映射尚未初始化，则根据 read-only 映射的内容创建一个新的 dirty 映射。
func (m *Map) dirtyLocked() {
	// 如果 dirty 映射已经存在，则直接返回。
	if m.dirty != nil {
		return
	}

	// 加载当前的 read-only 映射。
	read := m.loadReadOnly()
	// 创建一个新的 dirty 映射，并初始化其容量为 read-only 映射的大小。
	m.dirty = make(map[any]*entry, len(read.m))

	// 遍历 read-only 映射中的所有条目。
	for k, e := range read.m {
		// 如果条目未被删除，则将其添加到 dirty 映射中。
		if !e.tryExpungeLocked() {
			m.dirty[k] = e
		}
	}
}
```

### newEntry() 创建一个新的 entry，并初始化其值

```go
// 创建一个新的 entry，并初始化其值。
// 参数 i 是要存储在 entry 中的值。
func newEntry(i any) *entry {
	// 分配一个新的 entry 结构体。
	e := &entry{}

	// 使用原子操作将值 i 的地址存储到 entry 的 p 原子指针中。
	e.p.Store(&i)

	// 返回初始化后的 entry 指针。
	return e
}
```

## Delete()

```go
// Delete 删除键对应的值。
// 这个方法通过调用 LoadAndDelete 方法来实现。
func (m *Map) Delete(key any) {
	m.LoadAndDelete(key) // 调用 LoadAndDelete 方法，但忽略其返回结果。
}
```

### LoadAndDelete() 删除键对应的值

```go
// LoadAndDelete 删除键对应的值，并返回之前的值（如果有）。
// loaded 结果报告键是否存在于映射中。
func (m *Map) LoadAndDelete(key any) (value any, loaded bool) {
	// 加载当前的 read-only 映射。
	read := m.loadReadOnly()
	// 尝试从 read-only 映射中获取键对应的条目。
	e, ok := read.m[key]

	// 如果没有找到键对应的条目，并且 read-only 映射已被修改，则锁定 mu 以确保数据一致性。
	if !ok && read.amended {
		m.mu.Lock()
		// 再次尝试加载 read-only 映射，以防在等待锁的过程中 dirty 映射已被提升。
		read = m.loadReadOnly()
		e, ok = read.m[key]

		// 如果仍然没有找到键对应的条目，并且 read-only 映射已被修改，则从 dirty 映射中查找键对应的条目。
		if !ok && read.amended {
			e, ok = m.dirty[key]
			// 从 dirty 映射中删除键。
			delete(m.dirty, key)
			// 无论是否找到了条目，都记录一次 miss，因为这个键将会走慢路径
			// 直到 dirty 映射被提升为 read 映射。
			m.missLocked()
		}
		// 解锁 mu。
		m.mu.Unlock()
	}

	// 如果找到了条目，则删除条目并返回之前的值。
	if ok {
		return e.delete()  // 将值所在的指针, 修改为nil
	}
	// 如果没有找到条目，则返回 nil 和 false。
	return nil, false
}
```

## Range() 遍历

```go
// Range 依次为映射中存在的每个键和值调用函数 f。
// 如果 f 返回 false，则停止遍历。
//
// Range 不一定会对应映射的任何一致快照：
//
//	每个键不会被访问超过一次，但如果任一键的值被并发地存储或删除（包括由 f 执行）
//	Range 可能反映该键在 Range 调用期间的任意时刻的映射。
//	Range 不会阻止对接收者的其他方法的调用；甚至 f 本身也可以调用 m 上的任何方法。
//
// 即使 f 在常数次数的调用后返回 false，Range 也可能是 O(N) 的，其中 N 是映射中的元素数量。
func (m *Map) Range(f func(key, value any) bool) {
	read := m.loadReadOnly()

	// 如果读的map和写的map不一致, 需要特殊处理
	if read.amended {
		m.mu.Lock()

		// 再次确认, 如果读的map和写的map不一致, 需要特殊处理
		read = m.loadReadOnly()
		if read.amended {
			// 将 dirty 映射提升为 read 映射。
			// 同步写的map到读的map
			read = readOnly{m: m.dirty}
			m.read.Store(&read)
			m.dirty = nil
			m.misses = 0
		}
		m.mu.Unlock()
	}

	// 遍历 read 映射中的所有条目。
	for k, e := range read.m {
		// 加载条目中的值。
		v, ok := e.load()
		if !ok {
			// 如果条目已被删除，则跳过本次迭代。
			continue
		}

		// 调用函数 f，传递键和值。
		if !f(k, v) {
			// 如果 f 返回 false，则停止遍历。
			break
		}
	}
}
```

