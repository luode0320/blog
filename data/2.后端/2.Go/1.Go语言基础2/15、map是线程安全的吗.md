# 简介

map 不是线程安全的。

在查找、赋值、遍历、删除的过程中都会检测写标志，一旦发现写标志置位（等于1），则直接 panic。

赋值和删除函数在检测完写标志是复位之后，先将写标志位置位，才会进行之后的操作。



# 读源码

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

# 写源码

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

# 删除源码

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

# 遍历源码

```go
// 更新 hiter 结构，使其指向映射中的下一个元素。
// 这个函数用于遍历映射，找到下一个有效的键值对。
func mapiternext(it *hiter) {
	...
	if h.flags&hashWriting != 0 {
		fatal("并发map迭代和map写入")
	}
    ...
}
```

