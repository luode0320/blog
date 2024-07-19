# 简介

在 Go 语言中，`unsafe` 包提供了访问底层数据结构的能力，这通常用于处理底层内存布局或与 C 语言互操作的情况。

然而，直接操作 `unsafe` 包来获取 `slice` 或 `map` 的长度是不鼓励的，因为这违反了 Go 的类型安全原则，而且通常没有必要。

Go 语言本身提供了更安全和更简洁的方式来获取这些容器的长度。

不过，出于学习目的，我们可以探讨如何使用 `unsafe` 包来获取 `slice` 或 `map` 的长度。



**但请记住，这仅限于理论上的讨论，实际开发中应避免使用这种方式，除非你有非常充分的理由，并且理解这样做的风险。**



# 获取 slice 长度

 slice 的结构体：

```golang
type slice struct {
    array unsafe.Pointer // 元素指针
    len   int // 长度 
    cap   int // 容量
}
```

调用 make 函数新建一个 slice，底层调用的是 makeslice 函数，返回的是 slice 结构体：

```golang
func makeslice(et *_type, len, cap int) slice
```

因此我们可以通过 unsafe.Pointer 和 uintptr 进行转换，得到 slice 的字段值。

```golang
package main

import (
	"fmt"
	"unsafe"
)

func main() {
	// 定义以恶个切片
	s := make([]int, 9, 20)

	// Len: &s => pointer => uintptr => pointer => *int => int
	var Len = *(*int)(unsafe.Pointer(uintptr(unsafe.Pointer(&s)) + uintptr(8)))
	fmt.Println(Len, len(s)) // 9 9

	// Cap: &s => pointer => uintptr => pointer => *int => int
	var Cap = *(*int)(unsafe.Pointer(uintptr(unsafe.Pointer(&s)) + uintptr(16)))
	fmt.Println(Cap, cap(s)) // 20 20
}

```



# 获取 map 长度

```golang
type hmap struct {
	count     int
	flags     uint8
	B         uint8
	noverflow uint16
	hash0     uint32

	buckets    unsafe.Pointer
	oldbuckets unsafe.Pointer
	nevacuate  uintptr

	extra *mapextra
}
```

和 slice 不同的是，makemap 函数返回的是 hmap 的指针，注意是指针：

```golang
func makemap(t *maptype, hint int64, h *hmap, bucket unsafe.Pointer) *hmap
```

我们依然能通过 unsafe.Pointer 和 uintptr 进行转换，得到 hamp 字段的值，只不过，现在 count 变成二级指针了：

```golang
package main

import (
	"fmt"
	"unsafe"
)

func main() {
	// 定义一个map
	mp := make(map[string]int)
	mp["qcrao"] = 100
	mp["stefno"] = 18

	// &mp => pointer => **int => int
	count := **(**int)(unsafe.Pointer(&mp))
	fmt.Println(count, len(mp)) // 2 2
}
```



