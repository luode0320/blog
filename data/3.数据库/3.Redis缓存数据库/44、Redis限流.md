### Redis限流

Go 中实现 Redis 基础的限流器（如漏桶算法或令牌桶算法）通常涉及使用 Redis 客户端库来存储和检查请求的频率。

下面我将提供一个基于令牌桶算法的简单限流器实现，使用 `redis/go-redis` 库来完成这个功能。

### 基本思想

令牌桶算法的基本思想是系统会以一定的速率向桶中添加令牌，而每个请求都需要消耗一个令牌。

当桶中没有令牌可用时，请求将被拒绝或者等待直到有令牌可用。

下面是使用 `go-redis/redis` 实现的一个简单示例：

```sh
go get github.com/redis/go-redis/v9
```

```go
package main

import (
	"context"
	"fmt"
	"github.com/redis/go-redis/v9"
	"log"
	"time"
)

const (
	// KeyPrefix 是 Redis 中存储限流信息的前缀
	KeyPrefix = "rate_limit:"
	// TokenBucketRate 每毫秒产生的令牌数速率: 1=1毫秒一个 0.1=10毫秒一个 0.01=100毫秒一个 0.001=1秒一个
	TokenBucketRate = 0.001
	// TokenBucketCapacity 是令牌桶的最大容量
	TokenBucketCapacity = 10
	// LUA_SCRIPT 限流lua脚本
	LUA_SCRIPT = `
		local key = KEYS[1] -- 使用的 key
		local capacity = tonumber(ARGV[1]) -- 总容量
		local rate = tonumber(ARGV[2]) -- 每毫秒产生的令牌数速率
		local now = tonumber(ARGV[3]) -- 当前时间戳（毫秒）

		-- 获取当前存储的值
		local storedStr = redis.call('HGET', key, 'stored')
		local lastUpdateTimeStr = redis.call('HGET', key, 'lastUpdateTime')
		local stored = tonumber(storedStr) or capacity
		local lastUpdateTime = tonumber(lastUpdateTimeStr) or now

		-- 计算自上次更新以来经过的时间（毫秒）
		local deltaTime = now - lastUpdateTime

		-- 计算令牌的增长量
		local tokensToAdd = math.floor(deltaTime * rate)  -- 计算令牌数

		-- 更新令牌数
		stored = math.min(capacity, stored + tokensToAdd)

		-- 如果令牌数大于等于 1，则消耗一个令牌并返回 true
		if stored >= 1 then
			-- 消耗一个令牌
			stored = stored - 1
			
			-- 更新存储的值
			redis.call('HSET', key, 'stored', stored)
			redis.call('HSET', key, 'lastUpdateTime', now)
			-- 设置过期时间
			redis.call('PEXPIRE', key, capacity * 1000 / (rate * 1000))
			return 1
		else
			-- 令牌数不足，返回 false
			return 0
		end
`
)

var ctx = context.Background()

func newRedisClient() *redis.Client {
	// 连接到本地 Redis 实例
	rdb := redis.NewClient(&redis.Options{
		Addr:     "192.168.2.22:6379",
		Password: "", // no password set
		DB:       0,  // use default DB
	})
	return rdb
}

// checkLimit 使用 Lua 脚本检查是否超出限流
func checkLimit(client *redis.Client, key string) (bool, error) {
	// Lua 脚本参数
	args := []interface{}{
		TokenBucketCapacity,    // 容量
		TokenBucketRate,        // 速率
		time.Now().UnixMilli(), // 当前时间戳（毫秒）
	}

	// 执行 Lua 脚本
	result, err := client.Eval(ctx, LUA_SCRIPT, []string{key}, args...).Result()
	if err != nil {
		return false, err
	}

	// 解析 Lua 脚本返回的结果
	allowed, ok := result.(int64)
	if !ok {
		return false, fmt.Errorf("Lua脚本中的意外结果类型: %T", result)
	}

	// 将 int64 转换为 bool
	return allowed == 1, nil
}

func main() {
	client := newRedisClient()
	key := KeyPrefix + "example_user"

	for i := 0; i < 1000; i++ {
		time.Sleep(10 * time.Millisecond) // 模拟用户请求间隔
		limitExceeded, err := checkLimit(client, key)
		if err != nil {
			log.Fatalf("错误检查限制: %v", err)
		}
		if limitExceeded {
			log.Printf("请求 %d 通过\n", i)
		}
	}
}
```

我们定义了一个 `checkLimit` 函数来检查用户是否超出了限流阈值。

- 每次成功请求都会减少桶中的令牌数，如果桶为空，则请求将被拒绝。

- 每次请求时计算应该添加多少令牌来更新令牌数量。

每毫秒产生的令牌数速率: 1=1毫秒一个 0.1=10毫秒一个 0.01=100毫秒一个 0.001=1秒一个

这样我们就可以用毫秒来控制限流, 更加的精确