# del源码解析

写操作底层的执行函数是 `mapdelete`：

`src/runtime/map.go`

```go
// 从给定的映射中删除指定的键。
func mapdelete(t *maptype, h *hmap, key unsafe.Pointer) {
	// 如果竞态检测开启并且映射不为空，记录对映射的写操作和键的读操作。
	if raceenabled && h != nil {
		callerpc := getcallerpc()
		pc := abi.FuncPCABIInternal(mapdelete)
		racewritepc(unsafe.Pointer(h), callerpc, pc)
		raceReadObjectPC(t.Key, key, callerpc, pc)
	}
	// 如果 MSAN 开启并且映射不为空，记录对键的读操作。
	if msanenabled && h != nil {
		msanread(key, t.Key.Size_)
	}
	// 如果 ASAN 开启并且映射不为空，记录对键的读操作。
	if asanenabled && h != nil {
		asanread(key, t.Key.Size_)
	}
	// 如果映射为空或没有元素，检查是否哈希函数可能引发恐慌，如果可能，调用它。
	if h == nil || h.count == 0 {
		if t.HashMightPanic() {
			t.Hasher(key, 0) // see issue 23734
		}
		return
	}
	// 如果映射有并发写入的标志，引发致命错误。
	if h.flags&hashWriting != 0 {
		fatal("concurrent map writes")
	}

	// 计算键的哈希值。
	hash := t.Hasher(key, uintptr(h.hash0))

	// 设置 hashWriting 写标志。必须在调用 t.hasher 之后设置，以防 t.hasher 引发恐慌。
	h.flags ^= hashWriting

	// 根据哈希值确定桶的索引。
	bucket := hash & bucketMask(h.B)
	// 如果映射正在扩容，执行扩容工作。
	if h.growing() {
		growWork(t, h, bucket)
	}
	// 获取桶的指针。
	b := (*bmap)(add(h.buckets, bucket*uintptr(t.BucketSize)))
	// 记录原始桶指针
	bOrig := b
	// 高8位
	top := tophash(hash)

search:
	// 开始搜索键。
	for ; b != nil; b = b.overflow(t) {
		// 遍历桶中的元素。
		for i := uintptr(0); i < bucketCnt; i++ {
			// 如果桶顶哈希不匹配，检查是否达到桶尾。
			if b.tophash[i] != top {
				if b.tophash[i] == emptyRest {
					break search // 找到桶尾，退出搜索。
				}
				continue // 继续下一个元素。
			}

			// 获取键的地址。
			k := add(unsafe.Pointer(b), dataOffset+i*uintptr(t.KeySize))
			k2 := k
			if t.IndirectKey() {
				k2 = *((*unsafe.Pointer)(k2)) // 如果键是间接的，解引用。
			}
			// 比较键是否相等。
			if !t.Key.Equal(key, k2) {
				continue // 键不相等，继续下一个元素。
			}
			// 清除键，如果键中包含指针。
			if t.IndirectKey() {
				*(*unsafe.Pointer)(k) = nil
			} else if t.Key.PtrBytes != 0 {
				memclrHasPointers(k, t.Key.Size_)
			}

			// 清除值，如果值中包含指针。
			e := add(unsafe.Pointer(b), dataOffset+bucketCnt*uintptr(t.KeySize)+i*uintptr(t.ValueSize))
			if t.IndirectElem() {
				*(*unsafe.Pointer)(e) = nil
			} else if t.Elem.PtrBytes != 0 {
				memclrHasPointers(e, t.Elem.Size_)
			} else {
				memclrNoHeapPointers(e, t.Elem.Size_)
			}

			// 标记桶中的位置为空。
			b.tophash[i] = emptyOne
			// 如果桶以多个空状态结束，将其转换为 emptyRest 状态。
			if i == bucketCnt-1 {
				if b.overflow(t) != nil && b.overflow(t).tophash[0] != emptyRest {
					goto notLast
				}
			} else {
				if b.tophash[i+1] != emptyRest {
					goto notLast
				}
			}
			for {
				b.tophash[i] = emptyRest
				// 如果到达初始桶的开头，完成。
				if i == 0 {
					if b == bOrig {
						break // 初始桶的开始，我们完成了。
					}
					// 查找上一个存储桶，继续其最后一个条目。
					c := b
					for b = bOrig; b.overflow(t) != c; b = b.overflow(t) {
					}
					i = bucketCnt - 1
				} else {
					i--
				}

				// 如果桶中的位置不是空状态，停止转换。
				if b.tophash[i] != emptyOne {
					break
				}
			}
		notLast:
			// 减少映射的元素计数。
			h.count--
			// 重置哈希种子，使攻击者更难触发连续的哈希碰撞。见 issue 25237。
			if h.count == 0 {
				h.hash0 = fastrand()
			}
			// 退出搜索。
			break search
		}
	}

	// 如果 hashWriting 标志未设置，引发致命错误。
	if h.flags&hashWriting == 0 {
		fatal("concurrent map writes")
	}
	// 清除 hashWriting 标志。
	h.flags &^= hashWriting
}
```

1. **检查映射状态**：首先检查映射是否为空或无元素，如果是，则直接返回。如果映射正在进行并发写入，会引发致命错误。
2. **计算哈希值**：使用映射类型的哈希函数计算键的哈希值。
3. **设置并发写入标志**：在修改映射之前，设置并发写入标志，防止并发写入。
4. **定位桶**：根据哈希值确定桶的位置。
5. **搜索键**：遍历桶中的元素，查找匹配的键。如果找到匹配项，清除键和值，并将桶中的位置标记为空。
6. **更新状态**：减少映射的元素计数，如果映射变为空，重置哈希种子。