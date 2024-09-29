### 如何在Gin中配置数据库连接

在 Gin 框架中配置数据库连接通常需要几个步骤来实现。

以下是使用 Gin 框架结合 SQLite 数据库的一个简单示例。如果你使用的是其他数据库（如 MySQL、PostgreSQL 等），只需要替换相应的数据库驱动即可。

### 示例代码

#### 1. `db/db.go`

数据库连接模块：

```go
// db/db.go
package db

import (
	"database/sql"
	"log"
	"time"

	_ "github.com/mattn/go-sqlite3"
)

// DB 是全局数据库连接变量
var DB *sql.DB

// Connect 打开 SQLite 数据库连接
func Connect() {
	var err error
	DB, err = sql.Open("sqlite3", "./test.db")
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}

	// 设置最大空闲连接数
	DB.SetMaxIdleConns(5)

	// 设置最大打开连接数
	DB.SetMaxOpenConns(10)

	// 测试数据库连接是否正常
	if err := DB.Ping(); err != nil {
		log.Fatalf("Failed to ping database: %v", err)
	}

	// 定义一个重试机制
	retryConnect := func() {
		for i := 0; i < 5; i++ { // 尝试最多5次
			time.Sleep(1 * time.Second) // 等待1秒后再试
			DB, err = sql.Open("sqlite3", "./test.db")
			if err == nil && DB.Ping() == nil {
				log.Println("Connection re-established.")
				return
			}
		}
		log.Fatalf("Failed to re-establish connection after multiple attempts.")
	}

	go func() {
		ticker := time.NewTicker(30 * time.Second) // 每30秒检查一次
		defer ticker.Stop()
		for range ticker.C {
			if err := DB.Ping(); err != nil {
				log.Printf("Connection lost: %v", err)
				retryConnect()
			}
		}
	}()
}

```

#### 2. `main.go`

主程序：

```go
// main.go
package main

import (
	"log"
	"net/http"
	"path/to/your/db"

	"github.com/gin-gonic/gin"
)

func main() {
	// 初始化数据库连接
	db.Connect()

	r := gin.Default()

	// 在这里注册路由和其他中间件

	// 启动 Gin 服务器
	if err := r.Run(":8080"); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
```

