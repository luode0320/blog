### 如何在Gin中设置全局中间件

在 Gin 框架中设置全局中间件非常简单。全局中间件会在每个请求进入路由处理器之前和之后执行，这意味着它们会对所有路由生效。

### 示例代码

1. **创建全局中间件**： 我们将创建一个简单的日志记录中间件，记录每个请求的信息。
2. **注册全局中间件**： 在路由引擎初始化时注册中间件，确保它对所有路由都生效。

```go
package main

import (
	"fmt"
	"github.com/gin-gonic/gin"
)

// 自定义全局中间件
func loggingMiddleware(c *gin.Context) {
	fmt.Println("Before request processing") // 在请求处理之前打印日志

	// 调用后续的处理函数
	c.Next()

	fmt.Println("After request processing") // 在请求处理之后打印日志
}

func main() {
	// 创建一个默认的路由引擎实例
	router := gin.Default()

	// 注册全局中间件
	router.Use(loggingMiddleware)

	// 定义一个 GET 路由，访问路径为 "/"
	router.GET("/", func(c *gin.Context) {
		c.String(200, "Hello, World!")
	})

	// 定义另一个 GET 路由，访问路径为 "/hello/:name"
	router.GET("/hello/:name", func(c *gin.Context) {
		name := c.Param("name")
		c.String(200, "Hello, %s!", name)
	})

	// 启动服务，监听在 8080 端口
	router.Run(":8080")
}
```

