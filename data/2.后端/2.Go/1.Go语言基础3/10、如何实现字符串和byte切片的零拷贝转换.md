# 简介

在 Go 语言中，实现字符串和字节切片之间的零拷贝转换是可能的，主要是通过利用底层的字节表示和类型转换。

Go 的 `string` 类型实际上是一个结构体，包含指向字节的指针和长度信息。

因此，通过适当的方法，你可以在字符串和字节切片之间进行转换，而不需要复制数据。





# 原理

实现字符串和 bytes 切片之间的转换，要求是 `zero-copy`。

想一下，一般的做法，都需要遍历字符串或 bytes切片，再挨个赋值。

完成这个任务，我们需要了解 slice 和 string 的底层数据结构：

`src/reflect/value.go`

```golang
type StringHeader struct {
	Data uintptr // 指向字符串数据的指针
	Len  int     // 字符串的长度
}

type SliceHeader struct {
	Data unsafe.Pointer // 指向切片数据的指针
	Len  int            // 切片的长度
	Cap  int            // 切片的容量
}
```



只需要共享底层 Data 和 Len 就可以实现 `zero-copy`。

```golang
// 将字符串转换为字节数组
func string2bytes(s string) []byte {
    // 使用unsafe.Pointer将字符串s转换为指向字节数组的指针，然后再转换为[]byte类型
    return *(*[]byte)(unsafe.Pointer(&s))
}

// 将字节数组转换为字符串
func bytes2string(b []byte) string {
    // 使用unsafe.Pointer将字节数组b转换为指向字符串的指针，然后再转换为string类型
    return *(*string)(unsafe.Pointer(&b))
}
```



# 字节切片转字符串

要将字节切片转换为字符串，你可以使用内置的 `string()` 函数，它接受一个字节切片并返回一个字符串。

如果字节切片是有效的 UTF-8 编码，那么转换过程就是零拷贝的，因为字符串将直接引用字节切片的底层数据。

```go
package main

import (
	"fmt"
)

func main() {
	b := []byte("hello, world")
    // 这种转换是零拷贝的，只要 b 是有效的 UTF-8 编码。
	s := string(b)

	fmt.Println(s) // 输出: hello, world
}
```

# 字符串转字节切片

要将字符串转换为字节切片，你可以直接使用类型断言，因为字符串的底层是一个只读的字节切片。

但是，为了确保零拷贝，你需要使用 `unsafe` 包来获取字符串的内部指针和长度，然后创建一个新的字节切片，指向相同的内存区域。

```go
package main

import (
	"fmt"
	"unsafe"
)

func main() {
	s := "hello, world"
    // 使用unsafe.Pointer将字符串s转换为指向字节数组的指针，然后再转换为[]byte类型
	b := *(*[]byte)(unsafe.Pointer(&s))
	fmt.Println(b) // 输出: [104 101 108 108 111 44 32 119 111 114 108 100]
}
```

