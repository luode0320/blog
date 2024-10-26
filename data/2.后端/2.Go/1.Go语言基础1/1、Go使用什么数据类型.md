# **Basic Types（基本类型）**

- `bool`：布尔类型，表示真或假，取值为 `true` 或 `false`。
- `int8`, `int16`, `int32(int:32位操作系统)`, `int64(int:64位操作系统)`：整型，分别表示不同位数的有符号整数。
- `uint`, `uint8(byte)`, `uint16`, `uint32`, `uint64`, `uintptr`：无符号整型。
- `float32`, `float64`：浮点数类型。
- `complex64`, `complex128`：复数类型。
- `string`：字符串类型。

# **Composite Types（复合类型）**

- `array`：固定长度的序列类型，所有元素类型必须相同。
- `slice`：动态数组，可以看作是数组的一个视图，支持动态增长和缩减。
- `struct`：用户自定义的数据类型，可以包含不同类型的字段。
- `pointer`：指向某个变量的地址，用于操作内存中的直接位置。
- `interface`：定义了一组方法签名的集合，任何实现了这些方法的类型都自动实现了该接口。
- `map`：键值对集合，键必须是可比较的类型，值可以是任意类型。
- `channel`：用于 goroutine 之间通信的管道，可以发送和接收数据。

# **Function Types（函数类型）**

- 函数可以作为参数传递，也可以作为返回值返回。Go 中的函数可以有多个返回值，包括错误类型，这是 Go 的一个特色。





# 源码分析

通过反射包`src/reflect/type.go`得知, 一共有27种类型。

```go
const (
	Invalid Kind = iota
	Bool
	Int
	Int8
	Int16
	Int32
	Int64
	Uint
	Uint8
	Uint16
	Uint32
	Uint64
	Uintptr
	Float32
	Float64
	Complex64
	Complex128
	Array
	Chan
	Func
	Interface
	Map
	Pointer
	Slice
	String
	Struct
	UnsafePointer
)
```

