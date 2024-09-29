### 如何在Gin中使用JWT认证

在 Gin 框架中使用 JSON Web Tokens (JWT) 进行认证通常涉及以下几个步骤：

1. **安装必要的依赖**： 首先确保你已经安装了 Gin 框架和一个 JWT 包，例如 `go-jwt`。可以通过以下命令安装：

   ```sh
   go get -u github.com/gin-gonic/gin
   go get -u github.com/dgrijalva/jwt-go
   ```

2. **创建 JWT 密钥**： 创建一个密钥用于签名和验证 JWT token。

   ```go
   var jwtKey = []byte("your_secret_key")
   ```

3. **定义中间件**： 创建一个中间件来处理 JWT 的验证。当请求带有 JWT token 时，中间件会检查该 token 是否有效。

   ```go
   func AuthMiddleware() gin.HandlerFunc {
       return func(c *gin.Context) {
           // Get the JWT string from the request header
           tokenString := c.GetHeader("Authorization")
   
           // If there is no token attached to the request header, return an error
           if tokenString == "" {
               c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Missing token"})
               return
           }
   
           // Parse the token with the key
           token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
               // Validate the signing method as expected
               if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
                   return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
               }
               return jwtKey, nil
           })
   
           // If there is an error or the token is not valid, return an error
           if err != nil || !token.Valid {
               c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
               return
           }
   
           // Otherwise, set the claims to the context and move on
           if claims, ok := token.Claims.(jwt.MapClaims); ok && token.Valid {
               c.Set("claims", claims)
           }
           c.Next()
       }
   }
   ```

4. **创建 JWT Token**： 创建一个函数来生成 JWT token。

   ```go
   import (
       "github.com/dgrijalva/jwt-go"
       "time"
   )
   
   func GenerateJWT(userId int) (string, error) {
       // Create claims, which contains what the token should communicate
       claims := jwt.MapClaims{
           "userId": userId,
           "exp":    time.Now().Add(time.Hour * 72).Unix(), // Token expires in 72 hours
       }
   
       // Create token object with claims and sign it with the secret key
       token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
       tokenString, err := token.SignedString(jwtKey)
       if err != nil {
           return "", err
       }
       return tokenString, nil
   }
   ```

5. **应用中间件**： 在路由中应用中间件来保护需要鉴权的端点。

   ```go
   router := gin.Default()
   
   // Protected route that requires authentication
   router.GET("/protected", AuthMiddleware(), func(c *gin.Context) {
       claims := c.MustGet("claims").(jwt.MapClaims)
       c.JSON(http.StatusOK, gin.H{"message": "Welcome user!", "userId": claims["userId"]})
   })
   
   // Start the server
   router.Run(":8080")
   ```

### 完整代码

```go
package main

import (
	"fmt"
	"github.com/dgrijalva/jwt-go"
	"github.com/gin-gonic/gin"
	"net/http"
	"time"
)

var jwtKey = []byte("your_secret_key") // 定义用于签名 JWT 的密钥

// 定义一个简单的用户模型用于演示
type User struct {
	Username string `json:"username"` // 用户名
	Password string `json:"password"` // 密码
}

// 定义 JWT token 的 claims 结构
type Claims struct {
	Username           string `json:"username"` // 用户名
	jwt.StandardClaims        // 标准 claims，包含过期时间等
}

// 中间件函数，用于验证 JWT token
func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		tokenString := c.GetHeader("Authorization") // 获取请求头中的 JWT token 字符串
		if tokenString == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "缺少 token"}) // 如果没有找到 token，则返回未授权错误
			return
		}

		token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
			return jwtKey, nil // 提供签名密钥以验证 token
		})

		if err != nil || !token.Valid { // 如果 token 解析失败或无效，则返回未授权错误
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "无效的 token"})
			return
		}

		if claims, ok := token.Claims.(*Claims); ok && token.Valid { // 如果解析成功并且 token 有效，则将用户名设置到上下文中
			c.Set("username", claims.Username)
		}
		c.Next() // 继续处理下一个中间件或路由处理函数
	}
}

// 登录处理函数，用于生成 JWT token
func loginHandler(c *gin.Context) {
	var user User
	if err := c.ShouldBindJSON(&user); err != nil { // 从请求体中绑定 JSON 数据到 user 对象
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()}) // 如果绑定失败，则返回错误
		return
	}

	// 为了简化示例，我们假设用户名和密码是正确的
	if user.Username == "admin" && user.Password == "secret" {
		expirationTime := time.Now().Add(72 * time.Hour) // 设置 token 的过期时间为 72 小时后
		claims := &Claims{                               // 创建 claims 结构
			user.Username,
			jwt.StandardClaims{
				ExpiresAt: expirationTime.Unix(), // 设置过期时间
			},
		}

		token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims) // 使用 HS256 签名算法创建 token
		tokenString, err := token.SignedString(jwtKey)             // 使用密钥签名 token 并获取字符串表示形式
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "创建 token 时出错"}) // 如果签名失败，则返回内部服务器错误
			return
		}

		c.JSON(http.StatusOK, gin.H{ // 如果一切正常，则返回 token
			"token": tokenString,
		})
	} else {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "无效的凭据"}) // 如果用户名或密码错误，则返回未授权错误
	}
}

// 受保护的处理函数，仅允许带有有效 JWT token 的请求访问
func protectedHandler(c *gin.Context) {
	username := c.MustGet("username").(string) // 从上下文中获取用户名
	c.JSON(http.StatusOK, gin.H{               // 返回欢迎信息
		"message": fmt.Sprintf("欢迎 %s!", username),
	})
}

func main() {
	router := gin.Default() // 创建默认的 Gin 路由器实例

	// 登录端点
	router.POST("/login", loginHandler)

	// 受保护的路由组，所有这些路由都需要经过 JWT token 验证
	protectedRoutes := router.Group("/", AuthMiddleware())
	{
		protectedRoutes.GET("/protected", protectedHandler) // 受保护的 GET 请求
	}

	router.Run(":8080") // 启动 HTTP 服务器监听 8080 端口
}
```

