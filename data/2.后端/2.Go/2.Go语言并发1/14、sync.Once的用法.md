# 简介

`sync.Once`是Go语言标准库中的一个并发原语，用于执行且仅执行一次特定操作。

`sync.Once`保证在多个Goroutine并发调用`Do`方法时，只有第一次调用会执行`Do`方法中的操作，而后续调用会直接返回而不执行任何操作。



# 使用方法

- Once 可以用来执行且仅仅执行一次动作，常常用于单例对象的初始化场景
- Once 常常用来初始化单例资源，或者并发访问只需初始化一次的共享资源，或者在测试的时候初始化一次测试资源
- sync.Once 只暴露了一个方法 Do，你可以多次调用 Do 方法，但是只有第一次调用 Do 方法时 f 参数才会执行



# 常用用法

`sync.Once`的常用用法包括：

1. **执行且仅执行一次初始化操作**：在需要进行全局初始化工作的场景下，可以使用`sync.Once`确保初始化操作只执行一次。
2. **延迟加载**：可以利用`sync.Once`实现延迟加载，确保某个操作只在首次需要时执行，而后的调用则直接返回结果。



# 示例

```go
package main

import (
	"fmt"
	"sync"
)

var once sync.Once

func initialize() {
	fmt.Println("初始化")
}

func main() {
	once.Do(initialize) // 第一次调用，会触发 initialize
	once.Do(initialize) // 后续调用直接返回结果, 不会打印
}
```

运行结果:

```go
初始化
```

