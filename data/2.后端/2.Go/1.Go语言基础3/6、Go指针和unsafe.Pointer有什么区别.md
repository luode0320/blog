# 简介

在 Go 语言中，`*T` 类型的指针和 `unsafe.Pointer` 有着本质的区别，主要体现在类型安全性、用途和操作限制上。



# *T 类型的指针

`*T` 类型的指针是 Go 语言中用于表示指向特定类型 `T` 的内存地址的标准指针类型。

它是类型安全的，意味着你不能将 `*int` 转换为 `*string` 或任何其他不兼容的指针类型，除非使用类型断言或反射。

这有助于防止运行时错误和提高代码的安全性。

**示例:**

```go
package main

import "fmt"

func main() {
    var x int = 42
    var px *int = &x // px 是指向 int 类型的指针

    fmt.Println(*px) // 输出 42
}
```



# unsafe.Pointer指针

`unsafe.Pointer` 是一个特殊的指针类型，定义在 `unsafe` 包中。

与标准的 `*T` 指针不同，`unsafe.Pointer` 是不安全的，这意味着它可以指向任何类型的值。

尽管它提供了更大的灵活性，但也带来了更高的风险，因为错误的使用可能会导致程序崩溃或数据损坏。

`unsafe.Pointer` 主要用于以下情况：

1. **跨类型指针转换**：当你需要将一个 `*T` 指针转换为另一个不兼容的 `*U` 指针类型时，可以先将其转换为 `unsafe.Pointer`，然后再转换为目标类型。
2. **C 语言互操作**：在与 C 语言交互时，`unsafe.Pointer` 可以用于处理 C 的 `void *` 类型。
3. **低级内存操作**：尽管不推荐，但在某些情况下，你可能需要直接操作内存，这时 `unsafe.Pointer` 可以提供这种能力。

**示例:**

```go
package main

import (
    "fmt"
    "unsafe"
)

func main() {
    var x int = 42
    var px *int = &x

    // 将 *int 转换为 unsafe.Pointer
    upx := unsafe.Pointer(px)

    // 将 unsafe.Pointer 转换为 *int
    px2 := (*int)(upx)

    fmt.Println(*px2) // 输出 42
}
```

# 注意事项

使用 `unsafe.Pointer` 需要格外小心，因为任何错误的类型转换或内存操作都可能导致程序崩溃或产生未定义的行为。

Go 语言的设计理念是尽量避免使用 `unsafe` 包，除非确实有特殊的需求。在大多数情况下，使用标准的 `*T` 指针和类型安全的 Go 功能就足够了。



## 限制一：Go 的指针不能进行数学运算

来看一个简单的例子：

```golang
package main

func main() {
	a := 5
	p := &a

	p++        // 无效运算: p++(非数值类型 *int)
	p = &a + 3 // 无效运算: &a + 3(类型 *int 和 untyped int 不匹配)
}
```

上面的代码将不能通过编译，也就是说不能对指针做数学运算。



## 限制二：不同类型的指针不能相互转换

例如下面这个简短的例子：

```golang
package main

func main() {
	a := int(100)

	var f *float64
	f = &a // 无法将 '&a' (类型 *int) 用作类型 *float64
}
```



## 限制三：不同类型的指针不能使用 == 或 != 比较

只有在两个指针类型相同或者可以相互转换的情况下，才可以对两者进行比较。

另外，指针可以通过 `==` 和 `!=` 直接和 `nil` 作比较。

