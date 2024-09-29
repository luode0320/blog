### Redis幂等

当然可以！幂等性是指一个操作执行一次和执行多次的效果是一样的。

在分布式系统中，幂等性对于保证操作的一致性和避免重复处理是非常重要的。

假设我们需要实现一个幂等的请求处理功能，比如一个支付确认请求，我们需要确保即使客户端多次发送同样的请求，服务端也只会处理一次。

### 示例背景

假设有一个 HTTP API 接口 `/confirm-payment`，客户端可能会多次发送同一个请求，我们需要确保该请求只被处理一次。

### 实现思路

1. **生成请求的唯一标识**：每个请求都有一个唯一的 ID（例如订单号）。
2. **使用 Redis 作为中间件**：使用 Redis 来存储请求的唯一标识，以确保请求不会被重复处理。
3. **处理请求**：只有当 Redis 中不存在请求的唯一标识时，才处理请求，并将请求标识存入 Redis。
4. **设置过期时间**：为了避免 Redis 中存储过多的数据，可以在请求处理完成后给请求标识设置一个过期时间。

```go
package main

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/redis/go-redis/v9"
)

const (
	// RedisKeyPrefix 是 Redis 中存储幂等请求的前缀
	RedisKeyPrefix = "payment_request:"
	// ExpirationTime 请求标识的过期时间（秒）
	ExpirationTime = 60 * 5 // 5 分钟
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

// handlePaymentRequest 使用 SETNX 命令处理支付确认请求
func handlePaymentRequest(client *redis.Client, requestId string) {
	// 生成请求的唯一标识
	key := RedisKeyPrefix + requestId

	// 使用 SETNX 命令检查请求是否已经被处理过，并设置请求标识
	result, err := client.SetNX(ctx, key, "processed", time.Duration(ExpirationTime)*time.Second).Result()
	if err != nil {
		log.Fatalf("执行 SETNX 命令失败: %v", err)
	}

	if !result {
		fmt.Printf("请求 %s 已经被处理过，忽略此次请求。\n", requestId)
		return
	}

	// 处理请求逻辑
	fmt.Printf("正在处理请求 %s...\n", requestId)
	// 模拟请求处理过程
	time.Sleep(time.Second * 2)
	fmt.Printf("请求 %s 处理完成。\n", requestId)
}

func main() {
	client := newRedisClient()

	// 测试请求
	requestIds := []string{"123456", "123456", "789012", "789012"}

	for _, requestId := range requestIds {
		handlePaymentRequest(client, requestId)
		time.Sleep(time.Second) // 模拟客户端发送请求的间隔时间
	}
}

```

运行结果:

```sh
正在处理请求 123456...
请求 123456 处理完成。
请求 123456 已经被处理过，忽略此次请求。
正在处理请求 789012...
请求 789012 处理完成。
请求 789012 已经被处理过，忽略此次请求。
```

