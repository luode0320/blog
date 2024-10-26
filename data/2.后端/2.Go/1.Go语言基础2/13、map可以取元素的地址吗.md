# 简介

在 Go 语言中，你不能直接获取 map 中单个元素的地址

- 因为 map 的底层实现是基于哈希表的，而哈希表中的元素位置并不是固定的, 也无法直接通过指针访问。
- 当你向 map 添加元素时，Go 运行时会根据键的哈希值将元素放置到相应的 bucket 中
- 但这个 bucket 的位置以及 bucket 内部元素的顺序都不是确定的，因此你无法直接获取一个元素的确切地址。
- 因为一旦发生扩容，key 和 value 的位置就会改变，之前保存的地址也就失效了。



# 错误示例

以下代码不能通过编译：

```golang
package main

import "fmt"

func main() {
    m := make(map[string]int)

    fmt.Println(&m["qcrao"])
}
```

编译报错：

```shell
./main.go:8:14: cannot take the address of m["qcrao"]
```



# 正常使用

你可以获取指向 map 的引用，也就是 map 变量的地址，但这并不是获取单个元素地址的方式。

下面是一个示例，展示如何获取 map 变量的地址：

```go
package main

import (
	"fmt"
)

func main() {
	m := map[string]int{"key": 42}

	// 获取 map 变量的地址
	mapAddr := &m

	// 打印 map 变量的地址
	fmt.Printf("Address of the map variable: %p\n", mapAddr)
}
```

如果你想操作 map 的元素，可以通过键来访问和修改值，而不是通过地址。例如，修改 map 中元素的值：

```go
package main

import (
	"fmt"
)

func main() {
	m := map[string]int{"key": 42}

	// 访问和修改 map 的元素
	m["key"] = 43

	// 打印修改后的值
	fmt.Println("Value at 'key':", m["key"])
}
```

