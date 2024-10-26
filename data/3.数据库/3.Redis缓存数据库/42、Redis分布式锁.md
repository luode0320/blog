### Redis 分布式锁

Redis 分布式锁是一种常用的机制，用于在分布式系统中协调多个节点之间的互斥访问。

这种锁可以防止多个进程同时对共享资源进行修改，从而保证数据的一致性。

Redis 提供了多种方式来实现分布式锁，其中最常用的是基于 `SET` 命令的“加锁”和 `DEL` 命令的“解锁”。

### 基于 SET 命令的 Redis 分布式锁

以下是一个简单的基于 SET 命令的 Redis 分布式锁实现示例：

#### 实现步骤

1. **请求锁**：尝试设置一个带有唯一值（通常是当前线程的 ID 或随机数）的键，并设置一个过期时间，以防持有锁的进程崩溃导致死锁。
2. **释放锁**：在执行完需要互斥的操作后，通过验证锁持有者的唯一值来释放锁。

#### 示例代码

下面是一个使用 Go 语言实现的 Redis 分布式锁示例：

```go
package main

import (
	"context"
	"fmt"
	"time"

	"github.com/go-redis/redis/v8"
)

var lockKey = "distributed-lock"

func main() {
	// 创建一个 Redis 客户端实例
	rdb := redis.NewClient(&redis.Options{
		Addr:     "192.168.2.22:6379", // Redis 地址
		Password: "",                  // 密码
		DB:       0,                   // 数据库索引，默认为 0
	})

	// 设置上下文
	ctx := context.Background()

	uniqueID := fmt.Sprintf("%d", time.Now().UnixNano())
	// 尝试获取锁
	if ok := tryLock(ctx, rdb, uniqueID); ok {
		fmt.Println("成功获取锁")
		// 执行业务
		executeCriticalSection()
		// 释放锁
		unlock(ctx, rdb, uniqueID)
		fmt.Println("成功释放锁")
	} else {
		fmt.Println("未能获取锁")
	}
}

// 尝试获取锁
func tryLock(ctx context.Context, rdb *redis.Client, uniqueID string) bool {
	// 尝试设置带有 NX 和 EX 选项的键
	if _, err := rdb.SetNX(ctx, lockKey, uniqueID, 5*time.Second).Result(); err != nil {
		fmt.Println("设置锁失败:", err)
		return false
	}

	fmt.Println("设置锁成功")
	return true
}

// 使用 Lua 脚本尝试获取锁
func tryLockWithLua(ctx context.Context, rdb *redis.Client, uniqueID string) bool {
	luaScript := `
	local lockKey = KEYS[1]
	local uniqueID = ARGV[1]
	local ttl = tonumber(ARGV[2])
	if redis.call("get", lockKey) == nil then
		redis.call("set", lockKey, uniqueID, "EX", ttl)
		return 1
	else
		return 0
	end
	`

	res := rdb.Eval(ctx, luaScript, []string{lockKey}, uniqueID, (5 * time.Second).Seconds()).Val()
	if res == int64(1) {
		fmt.Println("设置锁成功")
		return true
	}
	fmt.Println("设置锁失败")
	return false
}

// 释放锁
func unlock(ctx context.Context, rdb *redis.Client, uniqueID string) {
	// 获取当前锁的持有者
	holder, err := rdb.Get(ctx, lockKey).Result()
	if err != nil {
		fmt.Println("获取锁持有者失败:", err)
		return
	}

	// 检查当前线程是否持有锁
	if holder == uniqueID {
		// 释放锁
		if err := rdb.Del(ctx, lockKey).Err(); err != nil {
			fmt.Println("释放锁失败:", err)
			return
		}
		fmt.Println("释放锁成功")
	} else {
		fmt.Println("当前线程不持有锁，无法释放")
	}
}

// 执行业务的代码段
func executeCriticalSection() {
	fmt.Println("执行业务操作...")
	time.Sleep(2 * time.Second) // 模拟耗时操作
	fmt.Println("业务操作完成")
}
```

#### 代码解释

1. **尝试获取锁 (`tryLock`)**：
    - 生成一个唯一的 ID（例如当前时间戳）。
    - 使用 `SETNX` 命令尝试设置键，如果键不存在则设置成功，否则失败。
    - 设置键的过期时间为 5 秒，以防止锁持有者崩溃导致死锁。
2. **释放锁 (`unlock`)**：
    - 获取当前锁的持有者。
    - 检查当前线程是否持有锁。
    - 如果当前线程持有锁，则使用 `DEL` 命令释放锁。
3. **执行互斥操作 (`executeCriticalSection`)**：
    - 执行需要互斥访问的代码段。

#### 注意事项

- **锁的超时时间**：设置一个合理的锁超时时间，以防持有锁的进程崩溃导致死锁。
- **锁的唯一性**：每次请求锁时生成一个唯一的 ID，以确保锁的安全性。
- **锁的原子性**：使用 `SETNX` 命令确保锁的设置是原子性的。
- **锁的释放检查**：在释放锁之前检查当前线程是否持有锁，避免误释放其他线程持有的锁。

除了使用 `SETNX` 和 `EX` 选项外，还可以使用 Lua 脚本来实现更安全的锁机制。

Lua 脚本可以确保整个锁操作的原子性，从而避免在某些情况下出现的问题。

### 基于 redsync 分布式锁库

#### 安装 `redsync`

```sh
go get github.com/go-redsync/redsync/v4
```

```go
package main

import (
	"fmt"
	"github.com/go-redis/redis/v8"
	"log"
	"time"

	"github.com/go-redsync/redsync/v4"
	"github.com/go-redsync/redsync/v4/redis/goredis/v8"
)

func main() {
	// 创建 Redis 客户端
	rdb := redis.NewClient(&redis.Options{
		Addr:     "192.168.2.22:6379",
		Password: "", // no password set
		DB:       0,  // use default DB
	})

	// 创建 redsync 实例
	rs := redsync.New(goredis.NewPool(rdb))

	// 定义锁的 key 和 TTL
	lockKey := "distributed-lock"

	// 尝试获取分布式锁
	lock := rs.NewMutex(lockKey)

	if err := lock.Lock(); err != nil {
		log.Fatalf("Failed to acquire lock: %v", err)
	}
	defer lock.Unlock()

	fmt.Println("成功获取锁")
	executeCriticalSection()
	fmt.Println("成功释放锁")
}

// 执行需要互斥操作的代码段
func executeCriticalSection() {
	fmt.Println("执行互斥操作...")
	time.Sleep(2 * time.Second) // 模拟耗时操作
	fmt.Println("互斥操作完成")
}
```

