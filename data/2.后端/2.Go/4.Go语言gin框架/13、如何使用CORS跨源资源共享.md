### 如何使用CORS（跨源资源共享）

CORS（Cross-Origin Resource Sharing，跨源资源共享）是一种机制，它使用额外的 HTTP 头来告诉浏览器允许一个域上的网页访问另一个域上的资源。

在 Gin 框架中，你可以很容易地添加 CORS 支持。

### 1. 使用 Gin 的内置中间件

Gin 提供了一个内置的中间件来支持 CORS，这个中间件可以通过简单的配置来启用。

#### 示例代码

```go
package main

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

func main() {
	// 创建一个默认的路由引擎实例
	router := gin.Default()

	// 添加 CORS 中间件
	router.Use(corsMiddleware())

	// 创建一个路由，处理 GET 请求
	router.GET("/", func(c *gin.Context) {
		c.String(http.StatusOK, "Hello, World!")
	})

	// 启动 HTTP 服务，监听在 8080 端口
	router.Run(":8080")
}

// CORS 中间件
func corsMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 设置允许的来源
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*") // 或者指定允许的域名
		c.Writer.Header().Set("Access-Control-Allow-Credentials", "true")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}

		c.Next()
	}
}

```

### 说明

1. **创建路由引擎**：使用 `gin.Default()` 创建一个默认的路由引擎实例。
2. 添加 CORS 中间件：通过`corsMiddleware`函数添加 CORS 支持。在这个函数中，我们设置了几个关键的 HTTP 响应头：
    - `Access-Control-Allow-Origin`: 可以设置为 `"*"` 表示允许所有来源，也可以指定一个或多个来源。
    - `Access-Control-Allow-Credentials`: 如果为 `true`，则允许携带 cookie 和 HTTP 认证信息。
    - `Access-Control-Allow-Headers`: 允许的请求头列表。
    - `Access-Control-Allow-Methods`: 允许的请求方法列表。
3. **处理 OPTIONS 请求**：对于 OPTIONS 请求，我们需要立即终止并返回一个 `http.StatusNoContent` （即 204 No Content）响应。
4. **创建路由**：定义一个简单的路由，当收到 GET 请求时返回 “Hello, World!”。