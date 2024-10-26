### 如何在Gin中使用ORM如GORM

在 Gin 中使用 ORM（对象关系映射）工具如 GORM 可以帮助您更方便地管理和操作数据库。

GORM 是一个流行的 ORM，它支持多种数据库，并且提供了丰富的功能，如自动迁移、关联关系管理等。

#### 2. 安装必要的依赖

使用 `go get` 命令安装 Gin 和 GORM，以及所需的数据库驱动（例如 MySQL 或 SQLite）：

```go
go get -u gorm.io/gorm
go get -u gorm.io/driver/mysql
```

#### 3. 配置数据库连接

创建一个 `db` 目录，并在其中创建 `db.go` 文件来配置数据库连接：

```go
// db/db.go
package db

import (
	"fmt"
	"gorm.io/gorm/logger"
	"log"
	"os"
	"time"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

var DB *gorm.DB

// InitDB 初始化数据库连接
func InitDB() {
	newLogger := logger.New(
		log.New(os.Stdout, "\r\n", log.LstdFlags), // io.writer
		logger.Config{
			SlowThreshold:             time.Second,   // 慢 SQL 阈值
			LogLevel:                  logger.Silent, // 日志级别
			IgnoreRecordNotFoundError: true,          // 忽略记录未找到错误
			Colorful:                  false,         // 彩色打印
		},
	)

	dsn := "root:root@tcp(192.168.2.22:3306)/test?charset=utf8mb4&parseTime=True&loc=Local"
	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{
		Logger: newLogger,
	})
	if err != nil {
		fmt.Println("Failed to connect to the database:", err)
		os.Exit(1)
	}

	sqlDB, err := db.DB()
	if err != nil {
		fmt.Println("Failed to get underlying sql.DB instance:", err)
		os.Exit(1)
	}

	// 设置连接池大小
	sqlDB.SetMaxIdleConns(10)           // 空闲连接的最大数量
	sqlDB.SetMaxOpenConns(100)          // 最大打开的连接数
	sqlDB.SetConnMaxLifetime(time.Hour) // 连接的最大可复用时间

	DB = db
	fmt.Println("Connected to the database.")
}

// 自动创建或更新数据库表结构
func Migrate() {
	// 可以传多个
	DB.AutoMigrate(&User{})
	fmt.Println("Database migration completed.")
}

```

#### 4. 控制层

```go
// controllers/user_controller.go
package controllers

import (
	"demo-go/db"
	"demo-go/services"
	"github.com/gin-gonic/gin"
	"net/http"
)

type UserController struct{}

var service = services.UserService{}

func (uc *UserController) GetUsers(c *gin.Context) {
	users := service.GetUsers()
	c.JSON(http.StatusOK, users)
}

func (uc *UserController) GetUser(c *gin.Context) {
	id := c.Param("id")
	user := service.GetUser(id)
	c.JSON(http.StatusOK, user)
}

func (uc *UserController) CreateUser(c *gin.Context) {
	var user db.User
	if err := c.ShouldBindJSON(&user); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	service.CreateUser(&user)
	c.JSON(http.StatusCreated, user)
}
```

#### 5. 实现层

```go
// services/user_service.go
package services

import (
	"demo-go/db"
	_ "github.com/mattn/go-sqlite3"
)

type UserService struct{}

func (uc *UserService) GetUsers() []db.User {
	var users []db.User
	db.DB.Find(&users)
	return users
}

func (uc *UserService) GetUser(id string) db.User {
	var user db.User
	db.DB.First(&user, id)
	return user
}

func (uc *UserService) CreateUser(user *db.User) {
	db.DB.Create(&user)
}

```

### 6. 路由

```go
// routers/router.go
package routers

import (
	"demo-go/controllers"
	"github.com/gin-gonic/gin"
)

func SetupRouter() *gin.Engine {
	router := gin.Default()

	// 注册路由处理器
	userCtrl := &controllers.UserController{}
	// Define routes.
	api := router.Group("/api/v1.0")
	{
		api.GET("/users", userCtrl.GetUsers)
		api.GET("/users/:id", userCtrl.GetUser)
		api.POST("/users", userCtrl.CreateUser)
	}

	return router
}

```

### 7. main

```go
// main.go
package main

import (
	"demo-go/db"
	"demo-go/routers"
)

// Initialize the database
func init() {
	db.InitDB()
	db.Migrate()
}

func main() {
	// Use the default middlewares (logger and recovery middleware).
	router := routers.SetupRouter()

	// Start the server.
	if err := router.Run(":8080"); err != nil {
		panic(err)
	}
}

```

