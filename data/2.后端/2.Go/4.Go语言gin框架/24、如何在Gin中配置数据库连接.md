### 如何在Gin中配置数据库连接

在 Gin 框架中配置数据库连接通常需要几个步骤来实现。

以下是使用 Gin 框架结合 SQLite 和 MySQL 数据库的一个简单示例。如果你使用的是其他数据库（如 MySQL、PostgreSQL
等），只需要替换相应的数据库驱动即可。

### SQLite示例

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

### MySQL示例

```go
// db/db.go
package db

import (
	"database/sql"
	"demo-go/config"
	"fmt"
	"github.com/robfig/cron"
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
	// 检查数据库是否存在，如果不存在则创建
	createDB()
	// 连接数据库
	connectDB()
	// 自动创建或更新数据库表结构
	migrate()
	// 数据库连接检查
	connectionCheck()
}

// 检查数据库是否存在，如果不存在则创建
func createDB() {
	// 将yaml配置参数拼接成连接数据库的url
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/?charset=utf8mb4&parseTime=True&loc=Local",
		config.ServiceConfig.Db.UserName,
		config.ServiceConfig.Db.Password,
		config.ServiceConfig.Db.Url,
		config.ServiceConfig.Db.Port,
	)

	// 连接数据库
	dbTemp, err := sql.Open("mysql", dsn)
	if err != nil {
		log.Println("连接系统数据库失败 : %s", err.Error())
		return
	}
	defer dbTemp.Close()

	// 检查数据库是否存在，如果不存在则创建
	_, err = dbTemp.Exec("CREATE DATABASE IF NOT EXISTS " + config.ServiceConfig.Db.DbName)
	if err != nil {
		log.Println("创建系统数据库失败: %s", err.Error())
		return
	}

	log.Printf("===========数据库检查完成==============")
}

// 连接数据库
func connectDB() {
	//将yaml配置参数拼接成连接数据库的url
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=True&loc=Local",
		config.ServiceConfig.Db.UserName,
		config.ServiceConfig.Db.Password,
		config.ServiceConfig.Db.Url,
		config.ServiceConfig.Db.Port,
		config.ServiceConfig.Db.DbName,
	)

	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{
		Logger: logger.New(
			log.New(os.Stdout, "\r\n", log.LstdFlags), // io.writer
			logger.Config{
				SlowThreshold: time.Second,                                       // 慢 SQL 阈值
				LogLevel:      logger.LogLevel(config.ServiceConfig.Db.LogLevel), // 日志级别
			},
		),
	})
	if err != nil {
		log.Println("Failed to connect to the database:", err)
		os.Exit(1)
	}

	sqlDB, err := db.DB()
	if err != nil {
		log.Println("Failed to get underlying sql.DB instance:", err)
		os.Exit(1)
	}

	// 设置连接池大小
	sqlDB.SetMaxIdleConns(config.ServiceConfig.Db.MaxIdleConns) // 空闲连接的最大数量
	sqlDB.SetMaxOpenConns(config.ServiceConfig.Db.MaxOpenConns) // 最大打开的连接数

	DB = db

	log.Printf("===========数据库连接成功==============")
}

// 自动创建或更新数据库表结构
func migrate() {
	// 可以传多个, 逗号拼接
	DB.AutoMigrate(&User{})
	log.Printf("===========数据库表结构检查完成==============")
}

// 数据库连接检查
func connectionCheck() {
	log.Println("===========启动数据库连接检查任务==============")
	go func() {
		c := cron.New()
		_ = c.AddFunc("0/30 * * * * ?", func() {
			Db, _ := DB.DB()
			// 如果ping正常，就返回
			if err := Db.Ping(); err != nil {
				// 检查数据库是否存在，如果不存在则创建
				createDB()
				// 连接数据库
				connectDB()
				// 自动创建或更新数据库表结构
				migrate()
			}
		})
	}()
}
```

```go
func init() {
	db.InitDB()
}

func main() {
    
}
```

