# 简介

`sync.WaitGroup` 在 Go 中用于等待一组 Goroutine 完成其任务。



# 示例

```go
package main

import (
	"fmt"
	"sync"
)

func main() {
	// 创建一个 sync.WaitGroup 实例。
	var wg sync.WaitGroup

	// 调用 Add 方法来增加等待的 Goroutine 数量
	wg.Add(5)

	for i := 0; i < 5; i++ {
		go func(id int) {
			defer wg.Done() // 在 Goroutine 完成时调用 Done 方法
			fmt.Println("这里放置 Goroutine 的具体逻辑:", id)
		}(i)
	}

	wg.Wait() // 等待所有 Goroutine 完成

	fmt.Println("所有 Goroutine 完成")
}
```

运行结果:

```go
这里放置 Goroutine 的具体逻辑: 4
这里放置 Goroutine 的具体逻辑: 0
这里放置 Goroutine 的具体逻辑: 1
这里放置 Goroutine 的具体逻辑: 2
这里放置 Goroutine 的具体逻辑: 3
所有 Goroutine 完成   
```

