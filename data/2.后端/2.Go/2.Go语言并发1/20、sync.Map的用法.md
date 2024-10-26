# 简介

`sync.Map` 是 Go 语言标准库中的一个线程安全的键值对映射类型，它提供了一个简单的方式来存储和检索键值对，同时保证了并发访问的安全性。

`sync.Map` 适用于那些不需要持久化存储，只需要在程序运行期间存在的键值对集合。

# 基本用法

`sync.Map` 提供了以下主要方法：

- **`Load(key interface{}) (value interface{}, ok bool)`**:
    - 加载给定键对应的值。如果键存在，则返回对应的值和 `true`；如果键不存在，则返回零值和 `false`。
- **`Store(key, value interface{})`**:
    - 将给定的键值对存储在映射中。如果键已经存在，则替换旧值。
- **`Delete(key interface{})`**:
    - 删除给定键对应的值。如果键不存在，则没有效果。
- **`Range(f func(key, value interface{}) bool)`**:
    - 遍历映射中的所有键值对。对于每个键值对，它都会调用函数 `f`。如果 `f` 返回 `false`，则迭代会停止。

# 示例

```go
package main

import (
	"fmt"
	"sync"
)

func main() {
	// 创建一个 sync.Map
	m := sync.Map{}

	// 存储键值对
	m.Store("one", 1)
	m.Store("two", 2)
	m.Store("three", 3)

	// 读取键值对
	if val, ok := m.Load("one"); ok {
		fmt.Printf("'one'的值: %v\n", val)
	} else {
		fmt.Println("键 'one' 未找到")
	}

	// 更新键值对
	m.Store("one", 10)

	// 再次读取
	if val, ok := m.Load("one"); ok {
		fmt.Printf("更新了值 'one': %v\n", val)
	} else {
		fmt.Println("键 'one' 更新后未找到")
	}

	// 删除键值对
	m.Delete("one")

	// 尝试读取已删除的键
	if _, ok := m.Load("one"); !ok {
		fmt.Println("键 'one' 已删除")
	}

	// 遍历所有的键值对
	m.Range(func(k, v interface{}) bool {
		fmt.Printf("Key: %v, Value: %v\n", k, v)
		return true
	})
}
```

运行结果:

```go
'one'的值: 1
更新了值 'one': 10  
键 'one' 已删除     
Key: two, Value: 2  
Key: three, Value: 3
```

