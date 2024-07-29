# 简介

在 Go 语言中，`unsafe.Pointer` 是一个特殊的指针类型，定义在 `unsafe` 包中。

它是一个通用的指针类型，可以指向任何类型的值，但它是不安全的，因为它缺乏类型检查。

`unsafe.Pointer` 的主要用途是进行低级别的内存操作，通常用于实现底层数据结构、与 C 语言互操作以及在特殊情况下需要直接操作内存的情况。



# 什么是unsafe包

unsafe是Go语言标准库中的一个包，提供了一些不安全的编程操作，如直接操作指针、修改内存等。

由于这些操作可能会引发内存错误和安全漏洞，因此需要非常小心使用。



# unsafe.Pointer是什么

unsafe.Pointer是一个通用的指针类型，可以指向任何类型的变量。

它可以通过uintptr类型的指针运算来进行指针操作，但是需要注意指针类型的对齐和内存边界问题。



# unsafe.Pointer 的原理

`src/unsafe/unsafe.go`

## 数据结构

```go
// ArbitraryType 仅用于文档目的，实际上并不是 unsafe 包的一部分。它表示任意 Go 表达式的类型。
type ArbitraryType int

// IntegerType 仅用于文档目的，实际上并不是 unsafe 包的一部分。它表示任意整数类型。
type IntegerType int

// Pointer 表示指向任意类型的指针。类型 Pointer 有四个特殊操作，其他类型没有：
//   - 任意类型的指针值可以转换为 Pointer。
//   - Pointer 可以转换为任意类型的指针值。
//   - uintptr 可以转换为 Pointer。
//   - Pointer 可以转换为 uintptr。
//
// 因此，Pointer 允许程序破坏类型系统，读取和写入任意内存。应该非常小心地使用它。
//
// 以下模式涉及 Pointer 是有效的。
// 不使用这些模式的代码在今天很可能是无效的，或者将来会无效。
// 即使下面的有效模式也带有重要的警告。
//
// 运行 "go vet" 可以帮助找到不符合这些模式的 Pointer 使用，
// 但是 "go vet" 的沉黙并不保证代码是有效的。
//
// (1) 将 *T1 转换为指向 *T2 的 Pointer。
//
// 假设 T2 不比 T1 大，并且两者共享等效的内存布局，这种转换允许将一种类型的数据重新解释为另一种类型的数据。例如，math.Float64bits 的实现如下：
//
//	func Float64bits(f float64) uint64 {
//		return *(*uint64)(unsafe.Pointer(&f))
//	}
//
// (2) 将 Pointer 转换为 uintptr（但不再转换回 Pointer）。
//
// 将 Pointer 转换为 uintptr 会将指向的值的内存地址作为整数值返回。通常用途是打印。
//
// 通常情况下，不能将 uintptr 转换回 Pointer。
//
// uintptr 是整数，而不是引用。
// 将 Pointer 转换为 uintptr 会创建一个没有指针语义的整数值。
// 即使 uintptr 持有某个对象的地址，垃圾回收器也不会在对象移动时更新 uintptr 的值，也不会阻止对象被回收。
//
// 剩下的模式列举了从 uintptr 转换为 Pointer 的唯一有效转换。
//
// (3) 将 Pointer 转换为 uintptr 并执行算术操作后再转换回来。
//
// 如果 p 指向一个分配的对象，则可以通过将其转换为 uintptr，添加偏移量，然后再转换回 Pointer 来对该对象进行操作。
//
//	p = unsafe.Pointer(uintptr(p) + offset)
//
// 这种模式的最常见用法是访问结构体的字段或数组的元素：
//
//	// 等同于 f := unsafe.Pointer(&s.f)
//	f := unsafe.Pointer(uintptr(unsafe.Pointer(&s)) + unsafe.Offsetof(s.f))
//
//	// 等同于 e := unsafe.Pointer(&x[i])
//	e := unsafe.Pointer(uintptr(unsafe.Pointer(&x[0])) + i*unsafe.Sizeof(x[0]))
//
// 在这种方式中，从指针中增加或减少偏移量是有效的。
// 也可以使用 &^ 进行指针舍入，通常用于对齐。
// 在所有情况下，结果必须继续指向原始分配的对象。
//
// 不像在 C 中，不可以将指针移动到超出原始分配结构的末尾：
//
//	// 无效：end 指向分配空间之外。
//	var s thing
//	end = unsafe.Pointer(uintptr(unsafe.Pointer(&s)) + unsafe.Sizeof(s))
//
//	// 无效：end 指向分配空间之外。
//	b := make([]byte, n)
//	end = unsafe.Pointer(uintptr(unsafe.Pointer(&b[0])) + uintptr(n))
//
// 请注意，这两个转换必须出现在同一个表达式中，中间只能有算术运算：
//
//	// 无效：uintptr 不能在转换回 Pointer 之前存储在变量中。
//	u := uintptr(p)
//	p = unsafe.Pointer(u + offset)
//
// 请注意，指针必须指向一个已分配的对象，因此不能为 nil。
//
//	// 无效：转换 nil 指针
//	u := unsafe.Pointer(nil)
//	p := unsafe.Pointer(uintptr(u) + offset)
//
// (4) 在调用 syscall.Syscall 时将 Pointer 转换为 uintptr。
//
// 包 syscall 中的 Syscall 函数将其 uintptr 参数直接传递给操作系统，然后根据调用的详细信息，
// 将其中一些重新解释为指针。
// 换句话说，系统调用实现隐式地将某些参数从 uintptr 转换回指针。
//
// 如果指针参数必须转换为 uintptr 以用作参数，那么转换必须出现在调用表达式本身中：
//
//	syscall.Syscall(SYS_READ, uintptr(fd), uintptr(unsafe.Pointer(p)), uintptr(n))
//
// 编译器通过在由汇编实现的函数调用的参数列表中将 Pointer 转换为 uintptr，
// 安排保持所引用的已分配对象，即使从类型上看似乎在调用期间不再需要该对象。
//
// 对于编译器来说，为了识别这种模式，
// 转换必须出现在参数列表中：
//
//	// 无效：uintptr 不能在系统调用期间的 Pointer 隐式转换回来之前存储在变量中。
//	u := uintptr(unsafe.Pointer(p))
//	syscall.Syscall(SYS_READ, uintptr(fd), u, uintptr(n))
//
// (5) 将 reflect.Value.Pointer 或 reflect.Value.UnsafeAddr 的结果从 uintptr 转换为 Pointer。
//
// reflect 包的 Value 方法名为 Pointer 和 UnsafeAddr 返回类型 uintptr 而不是 unsafe.Pointer，
// 以防止调用者在未导入 "unsafe" 的情况下将结果更改为任意类型。但是，这意味着结果是脆弱的，
// 必须在调用后立即将其转换为 Pointer，即在同一表达式中：
//
//	p := (*int)(unsafe.Pointer(reflect.ValueOf(new(int)).Pointer()))
//
// 与上述情况一样，在转换之前不能存储结果：
//
//	// 无效：uintptr 不能在转换回 Pointer 之前存储在变量中。
//	u := reflect.ValueOf(new(int)).Pointer()
//	p := (*int)(unsafe.Pointer(u))
//
// (6) 将 reflect.SliceHeader 或 reflect.StringHeader 的 Data 字段从 uintptr 转换为 Pointer 或相反。
//
// 与前一个情况一样，reflect 数据结构 SliceHeader 和 StringHeader 将 Data 字段声明为 uintptr，
// 以防止调用者在未导入 "unsafe" 的情况下将结果更改为任意类型。但是，这意味着
// SliceHeader 和 StringHeader 仅在解释实际片段或字符串值的内容时才有效。
//
//	var s string
//	hdr := (*reflect.StringHeader)(unsafe.Pointer(&s)) // 情况 1
//	hdr.Data = uintptr(unsafe.Pointer(p))              // 情况 6（此情况）
//	hdr.Len = n
//
// 在这种用法中，hdr.Data 实际上是指向字符串头部中底层指针的另一种方式，而不是一个 uintptr 变量本身。
//
// 通常情况下，reflect.SliceHeader 和 reflect.StringHeader 应该只作为指向实际切片或字符串的 *reflect.SliceHeader 和 *reflect.StringHeader 使用，
// 不应该作为普通结构体使用。
// 程序不应该声明或分配这些结构类型的变量。
//
//	// 无效：直接声明的头部不会保存 Data 作为引用。
//	var hdr reflect.StringHeader
//	hdr.Data = uintptr(unsafe.Pointer(p))
//	hdr.Len = n
//	s := *(*string)(unsafe.Pointer(&hdr))  // p 可能已经丢失
type Pointer *ArbitraryType
```

1. **通用指针**:
   `unsafe.Pointer` 是一个大小固定的指针类型，它可以在不同平台（如 32 位和 64 位）上有不同的大小。在 64 位平台上，它通常是一个 64 位的整数，表示内存地址。
2. **类型转换**:
   `unsafe.Pointer` 可以与其他类型的指针进行相互转换。例如，可以将一个 `*int` 指针转换为 `unsafe.Pointer`，然后再将其转换为 `*string` 指针。这种转换是不安全的，因为编译器不会进行类型检查，如果转换错误，可能导致程序崩溃或数据损坏。
3. **指针运算**:
   `unsafe.Pointer` 支持简单的指针运算，例如加减固定大小的整数。但是，这些运算必须非常小心，因为它们可能导致指针指向无效的内存地址。
4. **内存访问**:
   通过 `unsafe.Pointer`，可以访问和修改指向的内存。这通常需要与 `unsafe.SliceHeader` 和 `unsafe.StringHeader` 等类型一起使用，以便正确地访问和修改切片或字符串。
5. **与 C 语言互操作**:
   `unsafe.Pointer` 在与 C 语言互操作时非常有用，因为 C 语言中的 `void *` 类型可以与 `unsafe.Pointer` 进行转换，使得 Go 代码可以与 C 函数进行通信。



### 示例代码

以下是一些使用 `unsafe.Pointer` 的示例，展示如何进行类型转换和内存访问：

#### 示例 1: 类型转换

```go
package main

import (
	"fmt"
	"unsafe"
)

func main() {
	var x int = 42
	var px *int = &x

	// 将 *int 指针转换为 unsafe.Pointer
	upx := unsafe.Pointer(px)

	// 将 unsafe.Pointer 转换为 *int 指针
	px2 := (*int)(upx)

	fmt.Println(*px2) // 输出 42
}
```

#### 示例 2: 访问切片

```go
package main

import (
	"fmt"
	"reflect"
	"unsafe"
)

func main() {
	s := []int{1, 2, 3, 4, 5}

	// 获取 slice header 的地址
	sh := (*reflect.SliceHeader)(unsafe.Pointer(&s))

	// 从 slice header 中获取数据指针
	data := (*int)(unsafe.Pointer(sh.Data))

	// 访问第一个元素
	fmt.Println(*data) // 输出 1
}
```

### 注意事项

1. **类型安全**:
   使用 `unsafe.Pointer` 会绕过 Go 的类型安全机制。这意味着如果你错误地转换了指针类型，可能会导致程序崩溃或产生未定义的行为。

2. **内存安全**:
   直接操作内存可能导致数据损坏或程序崩溃，尤其是在进行指针运算或访问未初始化的内存时。

3. **性能影响**:
   使用 `unsafe` 包可能会导致编译器无法进行某些优化，因此在性能敏感的代码中应谨慎使用。

4. **最佳实践**:
   通常情况下，应该尽可能避免使用 `unsafe` 包，除非你有充分的理由，并且完全理解其后果。在大多数情况下，使用标准的类型安全特性就足够了。

