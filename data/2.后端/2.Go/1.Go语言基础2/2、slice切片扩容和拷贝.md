# 为什么会扩容

一般都是在向 slice 切片追加了元素之后，才会引起扩容。追加元素调用的是 `append` 函数。



# append原型

先来看看 `append` 函数的原型：

```golang
func append(slice []Type, elems ...Type) []Type
```

append 函数的参数长度可变，因此可以追加多个值到 slice 中，还可以用 `...` 传入 slice，直接追加一个切片。

```golang
slice = append(slice, elem1, elem2)
slice = append(slice, anotherSlice...)
```

`append`函数返回值是一个新的slice，Go编译器不允许调用了 append 函数后不使用返回值。





# 扩容原理

> 使用 append 可以向 slice 切片追加元素，实际上是往底层数组添加元素。

但是底层数组的长度是固定的，如果索引 `len-1`所指向的元素已经是底层数组的最后一个元素，就没法再添加了。

- 这时，slice 会**迁移**到新的内存位置，新底层数组的长度也会增加，这样就可以放置新增的元素。
- 同时，为了应对未来可能再次发生的 `append`操作，新的底层数组的长度，也就是新 `slice` 的容量是留了一定的 `buffer` 的。
- 否则，每次添加元素的时候，都会发生迁移，成本太高。



# 扩容源码解析

`src/runtime/slice.go`

```go
// 函数用于在 slice 需要扩容时分配新的底层数组。
// 它接受旧的数组指针、新的长度、旧的容量、要添加的元素数量和元素类型，
// 并返回新的数组指针、新的长度和新的容量。
func growslice(oldPtr unsafe.Pointer, newLen, oldCap, num int, et *_type) slice {
	// 计算原有的长度
	oldLen := newLen - num

	// 如果启用了竞态检测、内存安全检测或地址安全检测，记录读取范围
	if raceenabled {
		callerpc := getcallerpc()
		racereadrangepc(oldPtr, uintptr(oldLen*int(et.Size_)), callerpc, abi.FuncPCABIInternal(growslice))
	}
	if msanenabled {
		msanread(oldPtr, uintptr(oldLen*int(et.Size_)))
	}
	if asanenabled {
		asanread(oldPtr, uintptr(oldLen*int(et.Size_)))
	}

	// 检查新的长度是否合理
	if newLen < 0 {
		panic(errorString("切片扩容: len 超出范围"))
	}

	// 如果元素大小为 0，特殊处理
	if et.Size_ == 0 {
		// append 不应创建具有nil指针但非零len的切片。
		// 我们假设append在这种情况下不需要保留oldPtr。
		return slice{unsafe.Pointer(&zerobase), newLen, newLen}
	}

	// 计算新的容量
	newcap := oldCap
	doublecap := newcap + newcap
	if newLen > doublecap {
		newcap = newLen
	} else {
		// 容量如果小于256, 直接翻倍扩容
		const threshold = 256
		if oldCap < threshold {
			newcap = doublecap
		} else {
			// 对于大容量的 slice，采用 1.25 倍的增长策略
			for 0 < newcap && newcap < newLen {
				// 从小切片的2倍增长到大切片的1.25倍。
				// 这个公式给出了两者之间的平滑过渡。
				newcap += (newcap + 3*threshold) / 4
			}
			// 将newcap设置为请求的cap，当newcap计算溢出。
			if newcap <= 0 {
				newcap = newLen
			}
		}
	}

	// 检查容量计算是否溢出
	var overflow bool
	// 各个属性的内存大小
	var lenmem, newlenmem, capmem uintptr

	// 计算旧长度、新长度和容量各自所需的内存大小，并检查是否溢出
	// 最终确定哈希表的内存大小以及新的容量，并在需要时进行向上取整的优化计算。
	switch {
	case et.Size_ == 1:
		lenmem = uintptr(oldLen)    // 计算旧长度的内存大小（每个元素大小为1）
		newlenmem = uintptr(newLen) // 计算新长度的内存大小（每个元素大小为1）
		// 对容量进行向上取整的优化计算
		capmem = roundupsize(uintptr(newcap)) // 计算新容量的内存大小并向上取整
		overflow = uintptr(newcap) > maxAlloc // 检查新容量是否超出最大分配内存限制
		newcap = int(capmem)                  // 更新新容量为向上取整后的值

	// 如果系统是 64 位，那么 PtrSize 的值将是 8；如果是 32 位，那么 PtrSize 的值将是 4
	case et.Size_ == goarch.PtrSize:
		lenmem = uintptr(oldLen) * goarch.PtrSize    // 计算旧长度的内存大小（每个元素大小为指针大小）
		newlenmem = uintptr(newLen) * goarch.PtrSize // 计算新长度的内存大小（每个元素大小为指针大小）
		// 对容量进行向上取整的优化计算
		capmem = roundupsize(uintptr(newcap) * goarch.PtrSize) // 计算新容量的内存大小并向上取整
		overflow = uintptr(newcap) > maxAlloc/goarch.PtrSize   // 检查新容量是否超出最大分配内存限制
		newcap = int(capmem / goarch.PtrSize)                  // 更新新容量为向上取整后的值

	// 如果元素大小是2的幂次方
	case isPowerOfTwo(et.Size_):
		// 定义位移量变量
		var shift uintptr
		// 如果指针大小为8字节
		if goarch.PtrSize == 8 {
			// 用于更好的代码生成，对位移进行掩码操作
			// 计算位移量并进行掩码操作保留低6位
			shift = uintptr(sys.TrailingZeros64(uint64(et.Size_))) & 63
		} else {
			// 如果指针大小为4字节，计算位移量并进行掩码操作保留低5位
			shift = uintptr(sys.TrailingZeros32(uint32(et.Size_))) & 31
		}
		
		lenmem = uintptr(oldLen) << shift    // 计算旧长度的内存大小并左移位移量
		newlenmem = uintptr(newLen) << shift // 计算新长度的内存大小并左移位移量
		// 对容量进行向上取整的优化计算
		capmem = roundupsize(uintptr(newcap) << shift)   // 计算新容量的内存大小并左移位移量，然后向上取整
		overflow = uintptr(newcap) > (maxAlloc >> shift) // 检查新容量是否超出最大分配内存限制并考虑位移
		newcap = int(capmem >> shift)                    // 更新新容量为向上取整后的值右移位移量
		capmem = uintptr(newcap) << shift                // 更新容量为新容量左移位移量

	default:
		lenmem = uintptr(oldLen) * et.Size_    // 计算旧长度的内存大小（一般情况下）
		newlenmem = uintptr(newLen) * et.Size_ // 计算新长度的内存大小（一般情况下）
		// 计算容量并检查是否溢出
		capmem, overflow = math.MulUintptr(et.Size_, uintptr(newcap)) // 用新容量乘以元素大小计算总内存，同时检查是否溢出
		// 对容量进行向上取整的优化计算
		capmem = roundupsize(capmem)        // 计算新容量的内存大小并向上取整
		newcap = int(capmem / et.Size_)     // 更新新容量为向上取整后的值除以元素大小
		capmem = uintptr(newcap) * et.Size_ // 更新容量为新容量乘以元素大小
	}

	// 检查是否溢出或超出最大分配大小
	if overflow || capmem > maxAlloc {
		panic(errorString("growslice: len out of range"))
	}

	// 分配新的内存
	var p unsafe.Pointer
	if et.PtrBytes == 0 {
		p = mallocgc(capmem, nil, false)
		// 只有在新分配的内存中未被覆盖的部分进行清零
		memclrNoHeapPointers(add(p, newlenmem), capmem-newlenmem)
	} else {
		// 注意: 不能使用rawmem (避免内存清零)，因为GC可以扫描未初始化的内存。
		p = mallocgc(capmem, et, true)
		if lenmem > 0 && writeBarrier.enabled {
			// 只需遮蔽旧数组中的指针，因为新数组已被清零
			bulkBarrierPreWriteSrcOnly(uintptr(p), uintptr(oldPtr), lenmem-et.Size_+et.PtrBytes)
		}
	}

	// 复制原有数据到新数组
	memmove(p, oldPtr, lenmem)

	// 返回新的 slice 结构
	return slice{p, newLen, newcap}
}
```

1. **计算旧长度**：
   - 使用新的长度`newLen`减去要添加的元素数量`num`来得到原始的长度`oldLen`。
2. **竞态、内存和地址安全检测**：
   - 如果启用了竞态检测、内存安全检测或地址安全检测，记录旧数组的读取范围。
3. **验证新长度**：
   - 检查新的长度是否合法，如果小于0则抛出异常。
4. **处理零大小元素**：
   - 如果元素大小为0，则直接返回一个具有nil指针但正确长度的slice。
5. **计算新容量**：
   - 初始新容量`newcap`与旧容量相同。
   - 如果新的长度大于旧容量的两倍，则直接使用新长度作为新容量。
   - 否则，对于小容量(<256)，采用翻倍策略；对于大容量，采用1.25倍增长策略，直到满足新长度要求。
6. **溢出和最大分配检查**：
   - 根据元素大小的不同，计算新容量所需的内存大小。
   - 检查内存计算是否溢出或超过最大分配限制。
7. **内存分配**：
   - 使用`mallocgc`函数分配新的内存。
   - 根据元素类型决定是否需要清零内存或使用写屏障。
8. **数据迁移**：
   - 使用`memmove`将旧数组的数据复制到新数组中。
9. **返回新slice**：
   - 构造并返回一个新的`slice`结构，包含新数组的指针、新的长度和新的容量。



# 切片拷贝

```go
// 用于从字符串或不含指针的元素切片复制到另一个切片中。
func slicecopy(toPtr unsafe.Pointer, toLen int, fromPtr unsafe.Pointer, fromLen int, width uintptr) int {
	// 如果源切片长度为0或目标切片长度为0，则直接返回0，无需复制
	if fromLen == 0 || toLen == 0 {
		return 0
	}
	// 需要复制的元素数量初始化为源切片长度
	n := fromLen
	if toLen < n {
		// 如果目标切片长度 小于 源切片长度，则取目标切片长度作为需要复制的元素数量
		n = toLen
	}

	// 如果每个元素的宽度为0，则直接返回需要复制的元素数量n
	if width == 0 {
		return n
	}

	// 计算总共需要复制的字节大小
	size := uintptr(n) * width

	if raceenabled {
		callerpc := getcallerpc()                    // 获取调用者的PC值
		pc := abi.FuncPCABIInternal(slicecopy)       // 获取函数slicecopy的PC值
		racereadrangepc(fromPtr, size, callerpc, pc) // 对源地址范围进行读取访问的race检测
		racewriterangepc(toPtr, size, callerpc, pc)  // 对目标地址范围进行写入访问的race检测
	}
	if msanenabled {
		msanread(fromPtr, size) // 对源地址范围进行内存清洁读取访问的msan检测
		msanwrite(toPtr, size)  // 对目标地址范围进行内存清洁写入访问的msan检测
	}
	if asanenabled {
		asanread(fromPtr, size) // 对源地址范围进行地址清洁读取访问的asan检测
		asanwrite(toPtr, size)  // 对目标地址范围进行地址清洁写入访问的asan检测
	}

	// 如果复制的元素大小为1字节
	if size == 1 {
		// TODO: is this still worth it with new memmove impl?
		*(*byte)(toPtr) = *(*byte)(fromPtr) // 直接按字节进行复制，已知这里是字节指针
	} else {
		// 复制原有数据到新数组
		memmove(toPtr, fromPtr, size)
	}
	return n
}
```

1. 检查源切片和目标切片的长度，如果有一个为0，则直接返回0，无需进行复制操作。
2. 确定实际需要复制的元素数量，取源切片长度和目标切片长度中较小的一个作为需要复制的元素数量。
3. 判断每个元素的宽度，如果宽度为0，则直接返回需要复制的元素数量。
4. 计算总共需要复制的字节数，即元素数量乘以每个元素的宽度。
5. 如果启用了竞态检测、内存污染检测或地址污染检测，进行相应的内存访问检测。
6. 如果每个元素的大小为1字节，则直接按字节进行复制；否则，调用 `memmove` 函数将数据从源地址复制到目标地址。
7. 返回实际复制的元素数量。