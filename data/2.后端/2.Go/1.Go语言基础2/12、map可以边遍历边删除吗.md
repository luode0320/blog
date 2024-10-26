# 简介

map 并不是一个线程安全的数据结构。同时读写一个 map 是未定义的行为，如果被检测到，会直接 panic。



# 总结

map的读写, 只要不是多线程, 并不会出现并发问题!



# 并发读写

map肯定是不允许并发读写的, 因为map是用标志位做判断的, 而不是用同步锁。

下面我们简单看看源码: 

**读:**

```go
// 返回指向h[key]的指针。永远不返回nil，而是如果key不在map中，则返回elem类型的零对象的引用。
// 注意：返回的指针可能会保持整个map活跃，所以不要长时间保留它。
func mapaccess1(t *maptype, h *hmap, key unsafe.Pointer) unsafe.Pointer {
	...
	// 如果标记为hashWriting，则表示发生了并发map读写，程序报错
	if h.flags&hashWriting != 0 {
		fatal("并发map读取和map写入")
	}
}
```

**写:**

```go
// 函数的作用是在 map 中分配或更新一个键值对。
// 如果键已经存在于 map 中，函数会更新其对应的值；
// 如果键不存在，则函数会为该键分配一个新的位置并插入键值对。
func mapassign(t *maptype, h *hmap, key unsafe.Pointer) unsafe.Pointer {
	...
	// 检查 map 是否处于写入状态，防止并发写入
	if h.flags&hashWriting != 0 {
		fatal("并发 map 写入")
	}
}
```

**删除:**

```go
// 从给定的映射中删除指定的键。
func mapdelete(t *maptype, h *hmap, key unsafe.Pointer) {
	...
	// 如果映射有并发写入的标志，引发致命错误。
	if h.flags&hashWriting != 0 {
		fatal("concurrent map writes")
    }
}
```

所以并发绝对是不行的, 一旦出现一个线程 写或者删除 的过程中, 其他任何线程都不允许操作这个map

否则均会出现panic



# 非并发读写

先看看遍历部分的源码:

```go
// 更新 hiter 结构，使其指向映射中的下一个元素。
// 这个函数用于遍历映射，找到下一个有效的键值对。
func mapiternext(it *hiter) {
	...
	if h.flags&hashWriting != 0 {
		fatal("并发map迭代和map写入")
	}
    ...
next:
	if b == nil {
		// 如果当前桶为空
		if bucket == it.startBucket && it.wrapped {
			// 当前桶回到起始桶并且已经遍历了一轮，迭代结束
			it.key = nil
			it.elem = nil
			return
		}
		...
		// 处理完当前桶后，准备处理下一个桶
		bucket++
		if bucket == bucketShift(it.B) {
			// 如果已经处理完整个哈希表，回到第一个桶，同时标记为已经遍历过一轮
			bucket = 0
			it.wrapped = true
		}
		// 重置桶中元素的索引
		i = 0
	}
    ...
    // 遍历 bucket 的 key 返回, 并且持续遍历溢出链表, 如果溢出链表为nil, 则将 b = nil, 重新开始 next
    for ; i < bucketCnt; i++ {
        // 计算当前桶中元素的索引
		offi := (i + it.offset) & (bucketCnt - 1)
		// 如果当前位置是空的或者被迁移为空标记，继续遍历下一个位置
		if isEmpty(b.tophash[offi]) || b.tophash[offi] == evacuatedEmpty {
			continue
		}

		// 计算键和值的指针位置
		k := add(unsafe.Pointer(b), dataOffset+uintptr(offi)*uintptr(t.KeySize))
		if t.IndirectKey() {
			k = *((*unsafe.Pointer)(k))
		}
		e := add(unsafe.Pointer(b), dataOffset+bucketCnt*uintptr(t.KeySize)+uintptr(offi)*uintptr(t.ValueSize))
    	...
    }
	goto next
}
```

配上一个示例:

```go
package main

import (
	"fmt"
)

func main() {
	m := map[string]int{"a": 1, "b": 2, "c": 3, "d": 4}

	// 遍历 map，删除值为偶数的键（除了当前迭代的键）
	for k := range m {
		if k != "b" && m[k]%2 == 0 {
			delete(m, k)
		}
	}

	// 输出剩余的键值对
	fmt.Println("Remaining items:", m)
}
```

- 判断是否写入的 if 在获取迭代器的开始部分, 所以如果我们将 delete 写在遍历中, 是不会触发并发写入的
- 遍历过程中此时我们再 delete 删除某个 key , 会标识为 正在写入, 但是此时遍历并不需要判断写入的 if
- 当 delete 执行完成之后, 写入的标识被释放, 继续遍历, 遍历也触发并发写入
- 所以理论上时可以边遍历边删除的

但是, 如果遍历的下一个刚刚好是要删除的键呢?

- 此时, 我们已经遍历到 bucket1 的第一个key, 但是我们在逻辑中, 将这个 bucket1 的下一个key删除
- 我们可以从源码中看到, 如果是空的会跳过的, 所以并没有什么影响

```go
		// 如果当前位置是空的或者被迁移为空标记，继续遍历下一个位置
		if isEmpty(b.tophash[offi]) || b.tophash[offi] == evacuatedEmpty {
			continue
		}
```

