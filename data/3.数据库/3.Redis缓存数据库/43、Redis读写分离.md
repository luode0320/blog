### Redis读写分离

在 Go 中实现 Redis 的读写分离、主从复制机制、哨兵机制以及切片集群（Cluster）的功能，可以利用现有的成熟库来简化开发工作。

### 1. 读写分离 + 主从复制机制

创建主节点和从节点的客户端，并在应用程序层面控制读写操作。

```sh
go get github.com/go-redis/redis/v8
```

```go
package main

import (
	"context"
	"fmt"
	"log"
	"math/rand"
	"time"

	"github.com/go-redis/redis/v8"
)

type RedisClients struct {
	Master *redis.Client
	Slaves []*redis.Client
}

// NewRedisClients 创建 Redis 客户端
func NewRedisClients(masterAddr string, slaveAddrs []string) (*RedisClients, error) {
	masterOpt := &redis.Options{
		Addr:     masterAddr,
		Password: "", // no password set
		DB:       0,  // use default DB
	}

	masterClient := redis.NewClient(masterOpt)

	var slaves []*redis.Client
	if len(slaveAddrs) > 0 {
		for _, addr := range slaveAddrs {
			slaveOpt := &redis.Options{
				Addr:     addr,
				Password: "", // no password set
				DB:       0,  // use default DB
			}
			slaves = append(slaves, redis.NewClient(slaveOpt))
		}
	} else {
		slaves = append(slaves, masterClient)
	}

	return &RedisClients{
		Master: masterClient,
		Slaves: slaves,
	}, nil
}

func main() {
	// 主节点地址
	masterAddr := "192.168.2.22:6379"
	// 从节点地址列表
	slaveAddrs := []string{"192.168.2.22:6380"}

	// 创建 Redis 客户端
	redisClients, err := NewRedisClients(masterAddr, slaveAddrs)
	if err != nil {
		log.Fatalf("Failed to create Redis clients: %v", err)
	}

	// 设置上下文
	ctx := context.Background()

	// 设置键值对
	err = redisClients.Master.Set(ctx, "key", "读写分离", 0).Err()
	if err != nil {
		log.Fatalf("Set error: %v", err)
	}

	// 从从节点获取数据
	val, err := getFromRandomSlave(ctx, redisClients)
	if err != nil {
		log.Fatalf("Get error: %v", err)
	}
	fmt.Println("Value:", val)
}

// 从随机的从节点获取数据
func getFromRandomSlave(ctx context.Context, clients *RedisClients) (string, error) {
	if len(clients.Slaves) == 0 {
		return "", fmt.Errorf("no slave nodes available")
	}

	// 选择一个随机的从节点
	rand.Seed(time.Now().UnixNano())
	slave := clients.Slaves[rand.Intn(len(clients.Slaves))]

	val, err := slave.Get(ctx, "key").Result()
	if err != nil {
		return "", fmt.Errorf("error getting value from slave: %v", err)
	}
	return val, nil
}
```

### 2. 读写分离 + 主从复制 + 哨兵机制

对于简单的读写分离场景，可以使用 `go-redis` 的 `Failover` 功能，它支持主从复制和哨兵机制。

```sh
go get github.com/go-redis/redis/v8
```

```go
package main

import (
	"context"
	"fmt"
	"github.com/go-redis/redis/v8"
	"log"
)

type RedisClients struct {
	Master *redis.Client
	Slave  *redis.Client
}

// NewRedisClients 创建带有哨兵机制的 Redis 客户端
func NewRedisClients(sentinelAddrs []string) (*RedisClients, error) {
	// 配置主节点
	failoverOpts := &redis.FailoverOptions{
		MasterName:    "mymaster", // 哨兵配置的主节点名称
		SentinelAddrs: sentinelAddrs,
		DB:            0, // 使用默认数据库
	}
	masterClient := redis.NewFailoverClient(failoverOpts)

	// 配置从节点
	failoverOpts = &redis.FailoverOptions{
		MasterName:    "mymaster", // 哨兵配置的主节点名称
		SentinelAddrs: sentinelAddrs,
		DB:            0,    // 使用默认数据库
		SlaveOnly:     true, // 使用读节点
	}
	slaveClient := redis.NewFailoverClient(failoverOpts)

	return &RedisClients{
		Master: masterClient,
		Slave:  slaveClient,
	}, nil
}

func main() {
	// 哨兵地址列表
	sentinelAddrs := []string{"192.168.2.22:26379", "192.168.2.22:26380", "192.168.2.22:26381"}

	// 创建 Redis 客户端
	redisClients, err := NewRedisClients(sentinelAddrs)
	if err != nil {
		log.Fatalf("Failed to create Redis clients: %v", err)
	}

	// 设置上下文
	ctx := context.Background()

	// 设置键值对
	err = redisClients.Master.Set(ctx, "key", "value1", 0).Err()
	if err != nil {
		log.Fatalf("Set error: %v", err)
	}

	// 从任意一个 Sentinel 获取数据
	val, err := redisClients.Slave.Get(ctx, "key").Result()
	if err != nil {
		log.Fatalf("Get error: %v", err)
	}
	fmt.Println("Value:", val)
}
```

### 2. 读写分离 + 切片集群机制

`go-redis` 支持集群模式 (`Cluster`) 以及单个节点 (`Failover` 用于哨兵模式) 的连接。

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
)

func main() {
	ctx := context.Background()

	// Redis Cluster 的节点列表
	nodes := []string{
		"192.168.2.22:6379",
		"192.168.2.22:6380",
		"192.168.2.22:6381",
		"192.168.2.22:6382",
		"192.168.2.22:6383",
		"192.168.2.22:6384",
	}

	// 创建集群客户端
	rc := redis.NewClusterClient(&redis.ClusterOptions{
		Addrs:    nodes,
		ReadOnly: true, // 读写分离
	})

	// 设置键值对 (写操作)
	err := rc.Set(ctx, "exampleKey", "exampleValue1", 0).Err()
	if err != nil {
		log.Fatalf("Failed to set key: %v", err)
	}

	// 获取键值对 (读操作)
	val, err := rc.Get(ctx, "exampleKey").Result()
	if err != nil {
		log.Fatalf("Failed to get key: %v", err)
	}
	fmt.Println("Value from cluster:", val)
}
```

