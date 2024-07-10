# 简介

在 Go 语言中，比较两个 map 是否相等通常不能直接使用 `==` 操作符，因为 map 类型是引用类型，`==` 只会比较两个变量是否引用相同的内存地址。

为了比较两个 map 是否具有相同的键值对，你需要使用更深入的比较方式。



# 错误示例

直接将使用 map1 == map2 是错误的。这种写法只能比较 map 是否为 nil, 但是不能比较两个 map 。

```golang
package main

import "fmt"

func main() {
    var m map[string]int
    var n map[string]int

    fmt.Println(m == nil)
    fmt.Println(n == nil)

    // 不能通过编译
    //fmt.Println(m == n)
}
```

输出结果：

```golang
true
true
```

因此只能是遍历map 的每个元素，比较元素是否都是深度相等。



# 正确示例

最常用的方法是使用 `reflect.DeepEqual` 函数，它提供了深度比较功能，能够递归地检查两个复杂数据结构是否完全相同

包括 map、slice、array、struct 等。

下面是一个示例，展示了如何使用 `reflect.DeepEqual` 来比较两个 map 是否相等：

```go
package main

import (
	"fmt"
	"reflect"
)

func main() {
	m1 := map[string]int{"apple": 1, "cherry": 3, "banana": 2}
	m2 := map[string]int{"apple": 1, "banana": 2, "cherry": 3}
	m3 := map[string]int{"apple": 1, "banana": 2}

	// 使用 reflect.DeepEqual 比较 m1 和 m2
	if reflect.DeepEqual(m1, m2) {
		fmt.Println("m1 and m2 are equal")
	} else {
		fmt.Println("m1 and m2 are not equal")
	}

	// 使用 reflect.DeepEqual 比较 m1 和 m3
	if reflect.DeepEqual(m1, m3) {
		fmt.Println("m1 and m3 are equal")
	} else {
		fmt.Println("m1 and m3 are not equal")
	}
}
```

运行结果:

```go
m1 and m2 are equal
m1 and m3 are not equal
```

