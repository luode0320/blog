# 语法

Go 语言中读取 map 有两种语法：

- 带 comma (是否存在), 当要查询的 key 不在 map 里，带 comma 的用法会返回一个 bool 型变量提示
- 不带 comma (是否存在) , 而不带 comma 的语句则会返回一个 key 对应 value 类型的零值。

```golang
package main

import "fmt"

func main() {
    ageMap := make(map[string]int)
    ageMap["qcrao"] = 18

    // 不带 comma 用法
    age1 := ageMap["stefno"]
    fmt.Println(age1)

    // 带 comma 用法
    age2, ok := ageMap["stefno"]
    fmt.Println(age2, ok)
}
```

运行结果：

```shell
0
0 false
```



# 底层实现

以前一直觉得好神奇，怎么实现的？这其实是编译器在背后做的工作：分析代码后，将两种语法对应到底层两个不同的函数。

`src/runtime/hmap.go`

```golang
func mapaccess1(t *maptype, h *hmap, key unsafe.Pointer) unsafe.Pointer
func mapaccess2(t *maptype, h *hmap, key unsafe.Pointer) (unsafe.Pointer, bool)
```

其实就是多返回的一个存在不存在



# 源码解析

```go
// 返回指向h[key]的指针。永远不返回nil，而是如果key不在map中，则返回elem类型的零对象的引用。
// 注意：返回的指针可能会保持整个map活跃，所以不要长时间保留它。
func mapaccess1(t *maptype, h *hmap, key unsafe.Pointer) unsafe.Pointer {
	// 如果启用了race检查，并且h不为nil，则进行race检查
	if raceenabled && h != nil {
		callerpc := getcallerpc()
		pc := abi.FuncPCABIInternal(mapaccess1)
		racereadpc(unsafe.Pointer(h), callerpc, pc)
		raceReadObjectPC(t.Key, key, callerpc, pc)
	}
	// 如果启用了msan检查，并且h不为nil，则进行msan检查
	if msanenabled && h != nil {
		msanread(key, t.Key.Size_)
	}
	// 如果启用了asan检查，并且h不为nil，则进行asan检查
	if asanenabled && h != nil {
		asanread(key, t.Key.Size_)
	}
	// 如果h为nil或者计数为0，则返回elem类型的零对象的引用
	if h == nil || h.count == 0 {
		if t.HashMightPanic() {
			t.Hasher(key, 0) // see issue 23734
		}
		return unsafe.Pointer(&zeroVal[0])
	}
	// 如果标记为hashWriting，则表示发生了并发map读写，程序报错
	if h.flags&hashWriting != 0 {
		fatal("并发map读取和map写入")
	}

	// 计算hash值
	hash := t.Hasher(key, uintptr(h.hash0))
	// 返回 1 << b-1，针对代码生成进行了优化。
	m := bucketMask(h.B)
	// 将哈希表的buckets指针与哈希值hash进行运算，并根据掩码值m得到桶索引位置，最终计算出要查找的桶的指针位置
	b := (*bmap)(add(h.buckets, (hash&m)*uintptr(t.BucketSize)))
	// 处理旧buckets
	if c := h.oldbuckets; c != nil {
		if !h.sameSizeGrow() {
			// 之前有一半的桶；再掩码一次向下减少2的幂次
			m >>= 1
		}
		oldb := (*bmap)(add(c, (hash&m)*uintptr(t.BucketSize)))
		if !evacuated(oldb) {
			b = oldb
		}
	}
	// 计算高8位hash
	top := tophash(hash)

bucketloop: // 遍历bucket链表
	for ; b != nil; b = b.overflow(t) {
		// 遍历桶中条目
		for i := uintptr(0); i < bucketCnt; i++ {
			// 如果当前桶中的 tophash[i] 不等于 top
			if b.tophash[i] != top {
				// 如果当前桶中的 tophash[i] 等于 emptyRest(空)，则跳出 bucketloop
				if b.tophash[i] == emptyRest {
					break bucketloop
				}
				// 继续下一轮循环
				continue
			}
			// 计算当前 key 对应的指针地址
			k := add(unsafe.Pointer(b), dataOffset+i*uintptr(t.KeySize))
			// 如果需要间接引用key，则进行间接引用
			if t.IndirectKey() {
				k = *((*unsafe.Pointer)(k))
			}
			// 如果找到匹配的key，则返回对应的value指针
			if t.Key.Equal(key, k) {
				// 计算当前 value 对应的指针地址
				e := add(unsafe.Pointer(b), dataOffset+bucketCnt*uintptr(t.KeySize)+i*uintptr(t.ValueSize))
				// 如果需要间接引用elem，则进行间接引用
				if t.IndirectElem() {
					e = *((*unsafe.Pointer)(e))
				}
				// 返回找到的 value 指针
				return e
			}
		}
	}

	// 未找到匹配的key，返回elem类型的零对象的引用
	return unsafe.Pointer(&zeroVal[0])
}
```

1. 进行一系列的内存访问检查：
   - 如果启用了 race 检查，并且 h 不为 nil，则进行 race 检查。
   - 如果启用了 msan 检查，并且 h 不为 nil，则进行 msan 检查。
   - 如果启用了 asan 检查，并且 h 不为 nil，则进行 asan 检查。
2. 检查 map 是否为空或计数为 0，若满足条件，则返回 elem 类型的零对象的引用。
3. 检查并发写入标记，如果标记为 hashWriting，表示发生并发 map 读写，程序报错。
4. 计算 key 的哈希值 hash。
5. 根据 hash 计算出掩码值 m，用于确定桶的位置。
6. 根据 hash 和 m 计算出要查找的桶的指针位置 b。
7. 处理旧 buckets：
   - 如果存在旧 buckets，根据情况对 m 进行调整。
   - 获取旧 buckets 中对应哈希值位置的桶指针 oldb，如果未迁移完成，则使用 oldb。
8. 确定待查找的 tophash 高8位值 top。
9. 遍历当前桶及溢出桶中的条目，逐个比较 key：
   - 匹配到对应的 key 时，返回对应的 value 指针。
10. 如果未找到匹配的 key，则返回 elem 类型的零对象的引用。



当然, 返回是否存在的也很好看懂啦!

没错, 就是return的时候, 多加一个bool

```go
bucketloop: // 遍历bucket链表
	for ; b != nil; b = b.overflow(t) {
		// 遍历桶中条目
		for i := uintptr(0); i < bucketCnt; i++ {
			// 如果当前桶中的 tophash[i] 不等于 top
			if b.tophash[i] != top {
				// 如果当前桶中的 tophash[i] 等于 emptyRest(空)，则跳出 bucketloop
				if b.tophash[i] == emptyRest {
					break bucketloop
				}
				// 继续下一轮循环
				continue
			}
			// 计算当前 key 对应的指针地址
			k := add(unsafe.Pointer(b), dataOffset+i*uintptr(t.KeySize))
			// 如果需要间接引用key，则进行间接引用
			if t.IndirectKey() {
				k = *((*unsafe.Pointer)(k))
			}
			// 如果找到匹配的key，则返回对应的value指针
			if t.Key.Equal(key, k) {
				// 计算当前 value 对应的指针地址
				e := add(unsafe.Pointer(b), dataOffset+bucketCnt*uintptr(t.KeySize)+i*uintptr(t.ValueSize))
				// 如果需要间接引用elem，则进行间接引用
				if t.IndirectElem() {
					e = *((*unsafe.Pointer)(e))
				}
				// 返回找到的 value 指针
				return e,true
			}
		}
	}

	// 未找到匹配的key，返回elem类型的零对象的引用
	return unsafe.Pointer(&zeroVal[0]),false
```

