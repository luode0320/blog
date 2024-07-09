# 作用

在 Go 语言中，`make` 是一个内置函数，用于创建并初始化切片（slices）、映射（maps）和通道（channels）。

`make` 不仅分配内存，而且还会根据类型进行适当的初始化，使得这些数据结构可以立即使用。

# 基本语法

```go
func make(Type, size IntegerType) Type
```

这里的 `type` 是你想要创建的类型（只能是切片、映射或通道），`size` 是类型相关的初始化参数。

# 用法

以下是 `make` 函数在不同类型上的用法：

## 切片（Slices）

创建一个切片，指定长度和容量：

```go
s := make([]int, 5)          // 创建一个长度为 5 的切片，容量也为 5
t := make([]int, 0, 10)      // 创建一个长度为 0 的切片，容量为 10
```

## 映射（Maps）

创建一个空的映射：

```go
m := make(map[string]int)    // 创建一个空的映射
```

## 通道（Channels）

创建一个有缓冲的通道：

```go
c := make(chan int, 10)      // 创建一个缓冲大小为 10 的通道
```

# 示例

下面是一个具体的例子，演示如何使用 `make` 函数创建一个切片和一个映射，并进行一些基本的操作：

```go
package main

import "fmt"

func main() {
    // 创建一个长度为 5 的切片，容量也是 5
    s := make([]int, 5)
    for i := range s {
        s[i] = i * i
    }
    fmt.Println(s) // 输出: [0 1 4 9 16]

    // 创建一个空的映射
    m := make(map[string]int)
    m["apple"] = 100
    m["banana"] = 200
    fmt.Println(m) // 输出: map[apple:100 banana:200]
}
```

在这个例子中，我们使用 `make` 分别创建了一个切片和一个映射，并对它们进行了初始化和填充。

切片 `s` 的每个元素被赋值为其索引的平方，而映射 `m` 被填充了两个键值对。

运行结果:

```go
[0 1 4 9 16]
map[apple:100 banana:200]
```

