# 简介

在 Go 语言中，使用 `unsafe` 包来访问或修改私有成员（即小写开头的字段）通常被视为不良实践，因为它破坏了封装性和类型安全性。

然而，从技术角度来看，这确实是可能的，但强烈建议避免这样做，除非你完全理解其后果，并且在某些特定的边界条件下确实需要这么做。



**有时候, 我们使用了一个第三方的包, 里面的数据就是私有的!**



# 示例1

对于一个结构体，通过 `unsafe.Offsetof` 函数可以获取结构体成员的偏移量，进而获取成员的地址，读写该地址的内存，就可以达到改变成员值的目的。

这里有一个内存分配相关的事实：

**结构体会被分配一块连续的内存，结构体的地址也代表了第一个成员的地址。**

```golang
package main

import (
	"fmt"
	"unsafe"
)

type Programmer struct {
	name     string
	language string
}

func main() {
	// 初始化结构体
	p := Programmer{"stefno", "go"}
	fmt.Println("初始化结构体: ", p)

	// 强制转化为 string 类型
	// 因为结构体的地址是连续的, 第一个 name 属性的值所在的地址就是 &p
	name := (*string)(unsafe.Pointer(&p))
	// 修改第一个 name 属性的值所在的地址值
	*name = "luodeluodeluode"

	// 1.unsafe.Pointer(&p)：将结构体指针 &p 转换为 unsafe.Pointer 类型，将结构体指针的地址转换为不受类型限制的指针。
	// 2.uintptr(unsafe.Pointer(&p))：将 unsafe.Pointer 类型指针再次转换为 uintptr 类型，得到结构体指针的地址的整数表示。
	// 3.unsafe.Offsetof(p.language)：返回结构体 p 中字段 language 相对于结构体起始地址的偏移量。
	// 4.uintptr(unsafe.Pointer(&p)) + unsafe.Offsetof(p.language)：将结构体地址与字段偏移量相加，得到字段 language 的地址的整数表示。
	// 5.(*string)(...)：最后将整数地址转换为 *string 类型指针，表示指向结构体字段 language 的指针。
	lang := (*string)(unsafe.Pointer(uintptr(unsafe.Pointer(&p)) + unsafe.Offsetof(p.language)))
	// 修改language 所在的地址值
	*lang = "Golang"

	fmt.Println("指针位置修改: ", p)
}
```

运行结果：

```shell
初始化结构体:  {stefno go}
指针位置修改:  {luodeluodeluode Golang}
```



**我把 Programmer 结构体升级，多加一个字段：**

```golang
type Programmer struct {
	name string
	age int
	language string
}
```

并且放在其他包，这样在 main 函数中，它的三个字段都是私有成员变量，不能直接修改。

但我通过 unsafe.Sizeof() 函数可以获取成员大小，进而计算出成员的地址，直接修改内存。

```golang
func main() {
	p := Programmer{"stefno", 18, "go"}
	fmt.Println(p)

    // 1.unsafe.Pointer(&p)：将结构体指针 &p 转换为 unsafe.Pointer 类型，表示指向结构体的指针。
    // 2.uintptr(unsafe.Pointer(&p))：将 unsafe.Pointer 类型指针再次转换为 uintptr 类型，得到结构体指针的地址的整数表示。
    // 3.unsafe.Sizeof(int(0))：返回 int 类型变量的大小，即 int 类型的字节大小。
    // 4.unsafe.Sizeof(string(""))：返回空字符串的大小，即 string 类型的字节大小。
    // 5.uintptr(unsafe.Pointer(&p)) + unsafe.Sizeof(int(0)) + unsafe.Sizeof(string(""))：计算得到另一个字段地址的整数表示，通过将结构体指针地址与两个字段大小相加得到目标字段地址。
    // 6.(*string)(...)：最后将整数地址转换为 *string 类型指针，表示指向目标字段的指针。
	lang := (*string)(unsafe.Pointer(uintptr(unsafe.Pointer(&p)) + unsafe.Sizeof(int(0)) + unsafe.Sizeof(string(""))))
	*lang = "Golang"

	fmt.Println(p)
}
```

输出：

```shell
{stefno 18 go}
{stefno 18 Golang}
```

