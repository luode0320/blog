### Redis 做异步队列

Redis 是一个非常灵活的工具，可以用来构建多种应用，包括消息队列系统。

由于 Redis 支持多种数据结构（如 List、Set、Sorted Set 和 Hashes），并且提供了原子操作的能力，使得它非常适合用来作为异步队列的基础组件。

### 使用 List 结构

List 可以用来实现 FIFO（先进先出）队列。通过在列表的一端添加元素，在另一端移除元素，可以实现队列的基本功能。

#### 示例：

```go
package main

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/go-redis/redis/v8"
)

func main() {
	// 创建一个 Redis 客户端实例
	rdb := redis.NewClient(&redis.Options{
		Addr:     "192.168.2.22:6379", // Redis 地址
		Password: "",                  // 密码
		DB:       0,                   // 数据库索引，默认为 0
	})

	// 设置上下文
	ctx := context.Background()

	// 添加任务到队列
	addTaskToQueue(ctx, rdb, "task1")
	addTaskToQueue(ctx, rdb, "task2")
	addTaskToQueue(ctx, rdb, "task3")

	// 从队列中获取任务
	fmt.Println("开始从队列中获取任务...")
	for i := 0; i < 3; i++ {
		task, err := getTaskFromQueue(ctx, rdb)
		if err != nil {
			log.Fatalf("无法从队列获取任务: %v", err)
		}
		fmt.Println("取出任务:", task)
		time.Sleep(1 * time.Second) // 模拟处理任务的时间延迟
	}

	fmt.Println("所有任务处理完毕！")
}

// 将任务添加到队列
func addTaskToQueue(ctx context.Context, rdb *redis.Client, task string) {
	err := rdb.RPush(ctx, "queue:tasks", task).Err()
	if err != nil {
		log.Fatalf("无法添加任务到队列: %v", err)
	}
	fmt.Println("添加任务:", task)
}

// 从队列中获取任务
func getTaskFromQueue(ctx context.Context, rdb *redis.Client) (string, error) {
	//taskInterface, err := rdb.LPop(ctx, "queue:tasks").Result()
	//if err != nil {
	//	if err == redis.Nil {
	//		fmt.Println("队列为空")
	//		return "", nil
	//	}
	//	return "", err
	//}
	//return taskInterface, nil

	// 使用 BLPop 阻塞直到有数据可用, 使用 0 作为超时时间，表示无限期阻塞。
	// BLPop 返回一个包含两个元素的切片，第一个元素是键名，第二个元素是实际的数据
	taskInterface, err := rdb.BLPop(ctx, 0, "queue:tasks").Result()
	if err != nil {
		if err == context.Canceled {
			return "", fmt.Errorf("上下文已取消")
		}
		return "", fmt.Errorf("无法从队列获取任务: %v", err)
	}
	return taskInterface[1], nil
}
```

运行结果:

```sh
添加任务: task1
添加任务: task1
添加任务: task2
添加任务: task3
开始从队列中获取任务...
取出任务: task1
取出任务: task2
取出任务: task3
所有任务处理完毕！
```

### 使用 ZSet 结构

ZSet 可以用来实现带有优先级的任务队列。通过将任务的时间戳或者优先级作为分数存储，可以很容易地管理任务的顺序。

- ZSet的结构不能阻塞获取, 如果没有任何数据, 会返回空

#### 示例：

```go
package main

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/go-redis/redis/v8"
)

func main() {
	// 创建一个 Redis 客户端实例
	rdb := redis.NewClient(&redis.Options{
		Addr:     "192.168.2.22:6379", // Redis 地址
		Password: "",                  // 密码
		DB:       0,                   // 数据库索引，默认为 0
	})

	// 设置上下文
	ctx := context.Background()

	// 添加带优先级的任务到队列: 数字越小, 优先级越高
	addTaskToQueue(ctx, rdb, "task1", 5)
	addTaskToQueue(ctx, rdb, "task2", 3)
	addTaskToQueue(ctx, rdb, "task3", 8)

	// 从队列中获取最优先的任务
	fmt.Println("开始从队列中获取任务...")
	for i := 0; i < 3; i++ {
		task, err := getHighestPriorityTask(ctx, rdb)
		if err != nil {
			log.Fatalf("无法从队列获取任务: %v", err)
		}
		fmt.Println("取出任务:", task)
		time.Sleep(1 * time.Second) // 模拟处理任务的时间延迟
	}

	fmt.Println("所有任务处理完毕！")
}

// 将带有优先级的任务添加到队列
func addTaskToQueue(ctx context.Context, rdb *redis.Client, task string, priority int64) {
	score := float64(priority) // 直接使用优先级数值作为分数
	err := rdb.ZAdd(ctx, "queue:priority", &redis.Z{Score: score, Member: task}).Err()
	if err != nil {
		log.Fatalf("无法添加任务到队列: %v", err)
	}
	fmt.Printf("添加任务 %s 的优先级为 %.0f\n", task, score)
}

// 从队列中获取最优先的任务
func getHighestPriorityTask(ctx context.Context, rdb *redis.Client) (string, error) {
	// 根据指定的分数范围来获取元素及其分数
	tasks, err := rdb.ZRangeByScoreWithScores(ctx, "queue:priority", &redis.ZRangeBy{
		Min:    "-inf",
		Max:    "+inf",
		Offset: 0,
		Count:  1,
	}).Result()
	if err != nil {
		return "", err
	}

	if len(tasks) > 0 {
		// 移除已处理的任务
		err = rdb.ZRem(ctx, "queue:priority", tasks[0].Member).Err()
		if err != nil {
			return "", fmt.Errorf("无法移除任务: %v", err)
		}
		return tasks[0].Member.(string), nil
	}

	return "", fmt.Errorf("队列为空")
}
```

运行结果:

```sh
添加任务 task1 的优先级为 5
添加任务 task2 的优先级为 3
添加任务 task3 的优先级为 8
开始从队列中获取任务...
取出任务: task2
取出任务: task1
取出任务: task3
所有任务处理完毕！
```

### 使用 Pub/Sub 模型

Redis 还支持发布/订阅模式，可以用来实现事件驱动的架构。

- Redis 的发布订阅（Pub/Sub）模式下，**如果在消息发布时没有订阅者，那么这条消息将会丢失**。

- 这是因为 Pub/Sub 模式设计为实时消息传递，消息一旦发布就会立即广播给所有订阅了相应频道的客户端。

- 如果当时没有订阅者，那么消息就不会被任何客户端接收到。

#### 示例：

```go
package main

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/go-redis/redis/v8"
)

func main() {
	go func() {
		Publish()
	}()

	// 创建一个 Redis 客户端实例
	rdb := redis.NewClient(&redis.Options{
		Addr:     "192.168.2.22:6379", // Redis 地址
		Password: "",                  // 密码
		DB:       0,                   // 数据库索引，默认为 0
	})

	// 设置上下文
	ctx := context.Background()

	// 订阅频道 "channel:messages"
	pubsub := rdb.Subscribe(ctx, "channel:messages")

	// 监听频道直到上下文取消
	ctxCancel, cancel := context.WithCancel(ctx)
	defer cancel()

	go func() {
		<-ctxCancel.Done()
	}()

	fmt.Println("开始监听频道...")
	for {
		select {
		case <-ctxCancel.Done():
			return
		default:
			// 没有发布任何消息时，pubsub.ReceiveMessage(ctx) 会阻塞，等待有消息到达。
			msg, err := pubsub.ReceiveMessage(ctx)
			if err != nil {
				log.Fatalf("无法接收消息: %v", err)
			}
			fmt.Println("收到消息:", msg.Payload)
		}
	}
}

func Publish() {
	time.Sleep(2 * time.Second) // 等待一段时间，确保消费者启动
	// 创建一个 Redis 客户端实例
	rdb := redis.NewClient(&redis.Options{
		Addr:     "192.168.2.22:6379", // Redis 地址
		Password: "",                  // 密码
		DB:       0,                   // 数据库索引，默认为 0
	})

	// 设置上下文
	ctx := context.Background()

	// 准备消息
	message := "Hello, world!"

	// 发布消息到频道 "channel:messages"
	err := rdb.Publish(ctx, "channel:messages", message).Err()
	if err != nil {
		log.Fatalf("无法发布消息: %v", err)
	}

	fmt.Println("已发布消息:", message)
	time.Sleep(2 * time.Second) // 等待一段时间，确保消息被接收
}
```

运行结果:

```sh
开始监听频道...
已发布消息: Hello, world!
收到消息: Hello, world!
```

