### 如何实现API版本控制

在 RESTful API 设计中，API 版本控制是一项重要的实践，它帮助开发者在不影响现有客户端的情况下更新 API。

### 方法一：URL 路径版本号

这是最常用的版本控制方法之一，通过在 URL 路径中包含版本号来区分不同的 API 版本。

适用于大多数场景，直观易懂。

#### 示例代码：

```go
router := gin.Default()

// Version 1 endpoints
v1 := router.Group("/api/v1.0")
{
    v1.GET("/users", handleV1Users)
    v1.GET("/posts", handleV1Posts)
}

// Version 2 endpoints
v2 := router.Group("/api/v2.0")
{
    v2.GET("/users", handleV2Users)
    v2.GET("/posts", handleV2Posts)
}

router.Run(":8080")
```

### 方法二：请求头部（Header）

另一种方法是通过请求头部传递版本信息。这种方式可以避免 URL 变得过于冗长。

#### 示例代码：

```go
func getVersionFromHeader(c *gin.Context) string {
    version := c.Request.Header.Get("X-API-Version")
    if version == "" {
        version = "v1" // 默认版本
    }
    return version
}

router := gin.Default()

router.Use(func(c *gin.Context) {
    version := getVersionFromHeader(c)
    c.Set("api_version", version)
    c.Next()
})

router.GET("/users", func(c *gin.Context) {
    version := c.MustGet("api_version").(string)
    switch version {
    case "v1":
        handleV1Users(c)
    case "v2":
        handleV2Users(c)
    default:
        c.JSON(http.StatusNotImplemented, gin.H{"error": "Unsupported API version"})
    }
})

router.Run(":8080")
```

### 方法三：查询参数（Query Parameter）

还可以通过查询参数来指定 API 版本。

#### 示例代码：

```go
router := gin.Default()

router.GET("/users", func(c *gin.Context) {
    version := c.Query("version")
    if version == "" {
        version = "v1" // 默认版本
    }
    switch version {
    case "v1":
        handleV1Users(c)
    case "v2":
        handleV2Users(c)
    default:
        c.JSON(http.StatusNotImplemented, gin.H{"error": "Unsupported API version"})
    }
})

router.Run(":8080")
```

### 方法四：自定义中间件

你可以创建一个自定义的中间件来处理版本控制逻辑，这使得代码更加模块化。

#### 示例代码：

```go
func VersionMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        version := c.Query("version") // 从查询参数获取版本号
        if version == "" {
            version = "v1" // 默认版本
        }
        c.Set("api_version", version)
        c.Next()
    }
}

router := gin.Default()

router.Use(VersionMiddleware())

router.GET("/users", func(c *gin.Context) {
    version := c.MustGet("api_version").(string)
    switch version {
    case "v1":
        handleV1Users(c)
    case "v2":
        handleV2Users(c)
    default:
        c.JSON(http.StatusNotImplemented, gin.H{"error": "Unsupported API version"})
    }
})

router.Run(":8080")
```

### 选择合适的版本控制方法

- **URL 路径**：适用于大多数场景，直观易懂。
- **请求头部**：适用于希望保持 URL 清洁的应用。
- **查询参数**：适合那些不需要经常更改版本的应用，因为这种方法不如其他两种直观。
- **自定义中间件**：提供灵活性，可以在单个位置管理所有的版本逻辑。

