### Redis 的数据类型

### 1. 字符串（Strings）

字符串是最基本的数据类型，可以用来存储任意二进制数据。字符串类型的键可以存储的最大值大小为 512 MB。

#### 常见命令：

- `SET key value`：设置键 `key` 的值为 `value`。

  ```go
  rdb.Set(ctx, "example_key", "example_value", 0).Err()
  ```

- `GET key`：获取键 `key` 的值。

  ```go
  value, _ := rdb.Get(ctx, "example_key").Result()
  ```

- `INCR key`：将存储在键 `key` 中的整数值加 1。

  ```go
  err := rdb.Incr(ctx, "counter").Err()
  ```

- `DECR key`：将存储在键 `key` 中的整数值减 1。

  ```go
  err := rdb.Decr(ctx, "counter").Err()
  ```

### 2. 哈希表（Hashes）

哈希表是键值对的集合，每个键值对中的键称为字段（field），值可以是任意字符串。哈希表非常适合用来存储对象。

#### 常见命令：

- `HSET key field value`：设置哈希表 `key` 中的字段 `field` 的值为 `value`。

  ```go
  rdb.HSet(ctx, "example_hash", "field1", "value1").Err()
  ```

- `HGET key field`：获取哈希表 `key` 中的字段 `field` 的值。

  ```go
  value, _ := rdb.HGet(ctx, "example_hash", "field1").Result()
  ```

- `HGETALL key`：获取哈希表 `key` 中的所有字段和值。

  ```go
  fields, _ := rdb.HGetAll(ctx, "hash_key").Result()
  ```

- `HDEL key field [field ...]`：删除哈希表 `key` 中的一个或多个字段。

  ```go
  err := rdb.HDel(ctx, "hash_key", "field1", "field2").Err()
  ```

- `HEXISTS key field`：判断哈希表 `key` 中的字段 `field` 是否存在。

  ```go
  exists, _ := rdb.HExists(ctx, "hash_key", "field1").Result()
  ```

### 3. 列表（Lists）

列表是字符串值的链表，可以方便地从两端插入或移除元素。列表非常适合用来实现消息队列等功能。

#### 常见命令：

- `LPUSH key element [element ...]`：将一个或多个元素插入到列表 `key` 的头部。

  ```go
  rdb.LPush(ctx, "example_list", "item1").Err()
  ```

- `RPUSH key element [element ...]`：将一个或多个元素插入到列表 `key` 的尾部。

  ```go
  item, _ := rdb.LPop(ctx, "example_list").Result()
  ```

- `LPOP key`：移除并返回列表 `key` 的第一个元素。

  ```go
  value, _ := rdb.LPop(ctx, "list_key").Result()
  ```

- `RPOP key`：移除并返回列表 `key` 的最后一个元素。

  ```go
  value, _ := rdb.RPop(ctx, "list_key").Result()
  ```

- `LRANGE key start stop`：返回列表 `key` 中指定区间内的元素。

  ```go
  values, _ := rdb.LRange(ctx, "list_key", 0, 10).Result()
  ```

- `LLEN key`：返回列表 `key` 的长度。

  ```go
  length, _ := rdb.LLen(ctx, "list_key").Result()
  ```

### 4. 集合（Sets）

集合是一个无序的字符串集合，集合中的元素是唯一的。

#### 常见命令：

- `SADD key member [member ...]`：将一个或多个成员添加到集合 `key` 中。

  ```go
  rdb.SAdd(ctx, "example_set", "member1").Err()
  ```

- `SMEMBERS key`：返回集合 `key` 中的所有成员(不要去使用这种一下返回所有数据的 API)。

  ```go
  members, _ := rdb.SMembers(ctx, "example_set").Result()
  ```

- `SREM key member [member ...]`：将一个或多个成员从集合 `key` 中移除。

  ```go
  err := rdb.SRem(ctx, "set_key", "member1", "member2").Err()
  ```

- `SCARD key`：返回集合 `key` 中成员的数量。

  ```go
  count, _ := rdb.SCard(ctx, "set_key").Result()
  ```

- `SISMEMBER key member`：判断成员 `member` 是否属于集合 `key`。

  ```go
  exists, _ := rdb.SIsMember(ctx, "set_key", "member1").Result()
  ```

- `SINTER key [key ...]`：返回多个集合的交集。

  ```go
  intersection, _ := rdb.SInter(ctx, []string{"set_key1", "set_key2"}).Result()
  ```

- `SUNION key [key ...]`：返回多个集合的并集。

  ```go
  union, _ := rdb.SUnion(ctx, []string{"set_key1", "set_key2"}).Result()
  ```

### 5. 有序集合（Sorted Sets）

有序集合与集合类似，但每个成员都关联了一个分数，用于排序。有序集合中的成员也是唯一的。

#### 常见命令：

- `ZADD key score member [score member ...]`：将一个或多个成员添加到有序集合 `key` 中，并设置分数。

  ```go
  rdb.ZAdd(ctx, "example_zset", redis.Z{Score: 1.0, Member: "member1"}).Err()
  ```

- `ZRANGE key start stop [WITHSCORES]`：返回有序集合 `key` 中指定区间内的成员。

  ```go
  range, _ := rdb.ZRange(ctx, "example_zset", 0, 10).Result()
  ```

- `ZRANGE key start stop BYSCORE [WITHSCORES]`：返回有序集合 `key` 中指定分数区间内的成员。

  ```go
  members, _ := rdb.ZRangeByScore(ctx, "zset_key").Min("0").Max("10").WithScores(true).Result()
  ```

- `ZREM key member [member ...]`：将一个或多个成员从有序集合 `key` 中移除。

  ```go
  err := rdb.ZRem(ctx, "zset_key", "member1", "member2").Err()
  ```

- `ZCARD key`：返回有序集合 `key` 中成员的数量。

  ```go
  count, _ := rdb.ZCard(ctx, "zset_key").Result()
  ```

- `ZSCORE key member`：返回有序集合 `key` 中成员 `member` 的分数。

  ```go
  score, _ := rdb.ZScore(ctx, "zset_key", "member1").Result()
  ```

- `ZCOUNT key min max`：返回有序集合 `key` 中指定分数区间内的成员数量。

  ```go
  count, _ := rdb.ZCount(ctx, "zset_key", "-inf", "+inf").Result()
  ```

### 6. Bit Fields（位字段）

Bit Fields 是 Redis 3.2 版本引入的新特性，可以用来操作字符串值中的位。Bit Fields 可以用于高效地存储和检索位级别的数据。

高效地存储和操作一些小数值，比如传感器数据、状态位等。

`BITFIELD` 命令支持多种类型的字段，包括 `u8`（无符号 8 位整数）、`i8`（带符号 8 位整数）、`u16`、`i16`、`u32`、`i32`、`u64`
和 `i64`。

#### 常见命令：

- `BITFIELD key`：可以用于设置或获取字符串中的位字段。

  ```go
  	// 设置字段值
  	_, err := rdb.BitField(ctx, "example_bitfield").
  		Set(redis.BitFieldSubcommandArgs{
  			Type:  redis.BitFieldTypeU8,
  			Offset: 0,
  			Value: 123,
  		}).
  		Set(redis.BitFieldSubcommandArgs{
  			Type:  redis.BitFieldTypeU16,
  			Offset: 8,
  			Value: 456,
  		}).
  		Result()
  
  	// 获取字段值: []int64{123, 456}
  	result, err := rdb.BitField(ctx, "example_bitfield").
  		Get(redis.BitFieldSubcommandArgs{
  			Type:  redis.BitFieldTypeU8,
  			Offset: 0,
  		}).
  		Get(redis.BitFieldSubcommandArgs{
  			Type:  redis.BitFieldTypeU16,
  			Offset: 8,
  		}).
  		Result()
  ```

    1. **初始化数据**：
        - 计算所需的键和字段数量。
        - 对于每个键，使用 `BITFIELD` 命令初始化每个字段的值为 0。
    2. **设置存在性标志**：
        - 计算用户 ID 对应的键和字段索引。
        - 使用 `BITFIELD` 命令设置对应位为 1。
    3. **查询存在性**：
        - 使用 `BITFIELD` 命令获取对应位的值。
        - 根据获取的值判断用户是否存在。