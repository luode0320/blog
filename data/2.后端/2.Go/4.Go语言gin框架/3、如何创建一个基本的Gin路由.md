### 如何创建一个基本的Gin路由

创建一个基本的 Gin 路由非常简单。下面是一个简单的示例，展示如何使用 Gin 创建一个基本的 HTTP 服务器，并定义几个简单的路由。

### 安装

首先，确保你已经安装了 Go 语言环境，并且安装了 Gin 框架。可以通过以下命令安装 Gin：

```sh
go get -u github.com/gin-gonic/gin@v1.7.7
```

### 代码

然后，创建一个新的 Go 文件，例如 `main.go`，并在其中编写如下代码：

```go
package main

import (
	"github.com/gin-gonic/gin"
	"strconv"
)

func main() {
	// 创建一个默认的路由引擎实例
	router := gin.Default()

	// 定义一个 GET 路由，访问路径为 "/"
	router.GET("/get", func(c *gin.Context) {
		// 从查询字符串中获取参数
		name := c.Query("name")
		ageStr := c.Query("age")

		// 将 age 字符串转换为整数
		var age int
		if ageStr != "" {
			var err error
			age, err = strconv.Atoi(ageStr)
			if err != nil {
				c.String(400, "Invalid age parameter")
				return
			}
		}

		// 如果 name 存在，则返回相应的问候语
		if name != "" {
			c.String(200, "Hello, %s! You are %d years old.", name, age)
		} else {
			c.String(200, "Hello, World!")
		}
	})

	// 定义一个带有参数的 GET 路由
	router.GET("/hello/:name", func(c *gin.Context) {
		name := c.Param("name")
		c.String(200, "Hello, %s!", name)
	})

	// 定义一个接收 JSON 的 POST 路由
	router.POST("/post-json", func(c *gin.Context) {
		var jsonData struct {
			Name string `json:"name"`
			Age  int    `json:"age"`
		}

		// 将请求体中的 JSON 数据绑定到 jsonData 结构体
		if err := c.ShouldBindJSON(&jsonData); err == nil {
			c.JSON(200, gin.H{
				"message": "JSON data received",
				"name":    jsonData.Name,
				"age":     jsonData.Age,
			})
		} else {
			c.JSON(400, gin.H{"error": "Failed to parse JSON"})
		}
	})

	// 定义一个接收表单数据的 POST 路由
	router.POST("/post-form", func(c *gin.Context) {
		// 从请求体中获取表单数据
		name := c.PostForm("name")
		ageStr := c.PostForm("age")

		// 将 age 字符串转换为整数
		var age int
		if ageStr != "" {
			var err error
			age, err = strconv.Atoi(ageStr)
			if err != nil {
				c.String(400, "Invalid age parameter")
				return
			}
		}

		// 如果 name 存在，则返回相应的问候语
		if name != "" {
			c.String(200, "Hello, %s! You are %d years old.", name, age)
		} else {
			c.String(200, "Hello, World!")
		}
	})

	// 启动服务，监听在 8080 端口
	router.Run(":8080")
}
```

测试你的路由是否正常工作。

```http
### 拼接参数
GET http://localhost:8080/get?name=luode&age=26
Accept: application/json

### restful
GET http://localhost:8080/hello/luode
Accept: application/json

### json
POST http://localhost:8080/post-json
Content-Type: application/json

{
  "name": "luode",
  "age": 25
}

### 表单
POST http://localhost:8080/post-form
Content-Type: application/x-www-form-urlencoded

name = 罗德 &
age = 24
```

这就是使用 Gin 创建基本路由的基本步骤。你可以在此基础上扩展更多的路由和功能。

