# 简介

在 Go 语言中，理论上 float 类型（`float32` 或 `float64`）可以作为 map 的键（key），但是这通常不是一个好的做法。

- 原因是浮点数在计算机中的表示可能因为精度问题导致意外的结果。
- 即使两个浮点数在数值上看起来相等，它们在内存中的二进制表示也可能不同，这可能会导致在 map 中查找元素时出现错误。
- 尽管如此，从语法上讲，浮点数可以被用作 map 的键。



# 示例

下面是一个示例，展示了如何创建一个以 `float64` 类型为键的 map：

```go
package main

import (
	"fmt"
)

func main() {
	// 创建一个以 float64 为键，int 为值的 map
	floatMap := map[float64]int{}

	// 向 map 中添加元素
	floatMap[1.1] = 1
	floatMap[2.2] = 2
	floatMap[3.3] = 3

	// 输出 map 的内容
	for k, v := range floatMap {
		fmt.Printf("Key: %f, Value: %d\n", k, v)
	}

	// 尝试查找一个可能因为精度问题而找不到的键
	if val, ok := floatMap[1.1000000000000001]; ok {
		fmt.Printf("已找到 value for key 1.1000000000000001: %d\n", val)
	} else {
		fmt.Println("Key 1.1000000000000001 未找到")
	}

	// 尝试查找一个可能因为精度问题而找不到的键
	if val, ok := floatMap[2.2000000000001]; ok {
		fmt.Printf("已找到 value for key 2.2000000000001: %d\n", val)
	} else {
		fmt.Println("Key 2.2000000000001 未找到")
	}
}
```

运行结果:

```go
Key: 3.300000, Value: 3
Key: 1.100000, Value: 1                   
Key: 2.200000, Value: 2                   
已找到 value for key 1.1000000000000001: 1
Key 2.2000000000001 未找到
```

在上面的代码中，我们创建了一个以 `float64` 为键的 map，并向其中添加了一些元素。

- 然后我们迭代并打印了 map 的内容。
- 最后，我们尝试查找一个由于浮点数精度问题而可能不会找到的键。

因此，尽管语法上允许，但通常推荐避免使用浮点数作为 map 的键。如果需要使用数值作为键，建议使用整数类型，或者在使用浮点数时采取一些策略来规避精度问题，比如将浮点数乘以一个大整数后再转换成整数类型使用。