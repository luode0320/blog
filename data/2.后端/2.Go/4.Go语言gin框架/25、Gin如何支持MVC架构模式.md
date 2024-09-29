### Gin如何支持MVC架构模式

在 Gin 框架中实现 MVC（Model-View-Controller）架构模式可以帮助您更好地组织代码，并使其更具可维护性和可扩展性。

虽然 Gin 本身并没有直接提供 MVC 支持，但您可以通过合理组织代码结构来实现类似 MVC 的模式。

下面是一个简单的示例，展示如何在 Gin 中实现 MVC 架构：

### 目录结构

首先，定义一个基本的目录结构：

```sh
.
├── cmd
│   └── main.go
├── controllers
│   └── user_controller.go
├── models
│   └── user_model.go
├── routers
│   └── router.go
├── views
│   └── user.tmpl
├── go.mod
└── go.sum
```

最好使用1.7.7版本的gin

```sh
go get -u github.com/gin-gonic/gin@v1.7.7
```

### 文件内容

#### 1. `cmd/main.go`

主程序：

```go
// cmd/main.go
package main

import (
	"demo-go/routers"
)

func main() {
	router := routers.SetupRouter()

	// 启动服务，监听在 8080 端口
	router.Run(":8080")
}

```

#### 2. `controllers/user_controller.go`

控制器：

```go
// controllers/user_controller.go
package controllers

import (
	"demo-go/models"
	"github.com/gin-gonic/gin"
	"net/http"
	"strconv"
)

type UserController struct{}

func (uc *UserController) ListUsers(ctx *gin.Context) {
	users, err := models.ListUsers()
	if err != nil {
		ctx.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch users"})
		return
	}
	ctx.HTML(http.StatusOK, "user.tmpl", gin.H{"users": users})
}

func (uc *UserController) GetUser(ctx *gin.Context) {
	id, err := strconv.Atoi(ctx.Param("id"))
	if err != nil {
		ctx.AbortWithStatusJSON(http.StatusBadRequest, gin.H{"error": "Invalid ID"})
		return
	}

	user, err := models.GetUser(id)
	if err != nil {
		ctx.AbortWithStatusJSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}
	ctx.JSON(http.StatusOK, user)
}

```

#### 3. `models/user_model.go`

模型：

```go
// models/user_model.go
package models

import (
	"database/sql"
	"errors"
	"log"

	_ "github.com/mattn/go-sqlite3"
)

type User struct {
	ID   int    `json:"id"`
	Name string `json:"name"`
}

func ListUsers() ([]User, error) {
	db, err := sql.Open("sqlite3", "./test.db")
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	rows, err := db.Query("SELECT id, name FROM users")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var users []User
	for rows.Next() {
		var user User
		if err := rows.Scan(&user.ID, &user.Name); err != nil {
			return nil, err
		}
		users = append(users, user)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return users, nil
}

func GetUser(id int) (*User, error) {
	db, err := sql.Open("sqlite3", "./test.db")
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	row := db.QueryRow("SELECT id, name FROM users WHERE id = ?", id)
	var user User
	if err := row.Scan(&user.ID, &user.Name); err != nil {
		if err == sql.ErrNoRows {
			return nil, ErrUserNotFound
		}
		return nil, err
	}
	return &user, nil
}

var ErrUserNotFound = errors.New("user not found")

```

#### 4. `routers/router.go`

路由配置：

```go
// routers/router.go
package routers

import (
	"demo-go/controllers"
	"github.com/gin-gonic/gin"
)

func SetupRouter() *gin.Engine {
	r := gin.Default()

	// 注册路由处理器
	userCtrl := &controllers.UserController{}
	r.GET("/users", userCtrl.ListUsers)
	r.GET("/users/:id", userCtrl.GetUser)

	return r
}

```

### 解释

1. **主程序 (`main.go`)**：
    - 设置路由并启动 Gin 服务器。
2. **控制器 (`user_controller.go`)**：
    - 处理 HTTP 请求并将业务逻辑委托给模型。
    - 列出所有用户和获取单个用户的信息。
3. **模型 (`user_model.go`)**：
    - 与数据库交互，执行 CRUD 操作。
    - 提供列表用户和获取单个用户的方法。
4. **路由配置 (`router.go`)**：
    - 设置路由处理器，并注册路由。
    - 使用会话中间件。