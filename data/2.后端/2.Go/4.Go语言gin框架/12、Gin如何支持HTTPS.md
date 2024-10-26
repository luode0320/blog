### Gin如何支持HTTPS

要在 Gin 中支持 HTTPS，你需要生成 SSL 证书和密钥，并使用它们来启动一个安全的 HTTP 服务器。

这里会演示如何生成自签名证书以及如何配置 Gin 来使用 HTTPS。

### 1. 生成自签名证书

如果你还没有 SSL 证书，你可以先生成一个自签名的证书用于开发环境。请注意，在生产环境中，你应该从受信任的证书颁发机构 (CA)
获取证书。

#### 生成自签名证书

使用 OpenSSL 来生成自签名证书：

```sh
# 生成私钥
openssl genpkey -algorithm RSA -out server.key

# 生成证书请求文件
openssl req -new -key server.key -out server.csr

# 使用私钥生成自签名证书
openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt
```

输入命令后，OpenSSL 会要求你填写一些信息，如国家代码、组织名称等。你可以根据实际情况填写，或者直接按回车键接受默认值。

### 2. 配置 Gin 使用 HTTPS

接下来，我们将修改 Gin 应用来使用 HTTPS。

#### 示例代码

```go
package main

import (
	"github.com/gin-gonic/gin"
	"log"
	"net/http"
)

func main() {
	// 创建一个默认的路由引擎实例
	router := gin.Default()

	// 创建一个路由组，前缀为 "/api/v1"
	apiV1 := router.Group("/api/v1")
	{
		apiV1.GET("/", func(c *gin.Context) {
			c.String(http.StatusOK, "Welcome to API v1!")
		})
	}

	// 启动 HTTPS 服务，监听在 443 端口
	err := router.RunTLS(":443", "server.crt", "server.key")
	if err != nil {
		log.Fatalf("Failed to start HTTPS server: %v", err)
	}
}

```

### 说明

1. **生成证书**：使用 OpenSSL 生成自签名证书和私钥。
2. **启动 HTTPS 服务**：使用 `router.RunTLS` 方法启动 HTTPS 服务，并传入证书和密钥的路径。

### 生产环境建议

在生产环境中，建议用nginx配置。