# 什么是分布式锁？Redis实现分布式锁详解

**1.线程锁**

- 主要用来给方法、代码块加锁。
- 当某个方法或代码使用锁，在同一时刻`仅有一个线程`执行该方法或该代码段。
- 线程锁只在**同一JVM**中有效果，因为线程锁的实现在根本上是依靠线程之间共享内存实现的，比如Synchronized、Lock等。

**2.进程锁**

- 为了控制同一操作系统中多个**进程**访问某个共享资源，因为进程具有独立性，各个进程无法访问其他进程的资源，因此无法通过synchronized等线程锁实现进程锁。

**3.分布式锁**

- 当多个进程不在同一个系统中，用**分布式锁**控制多个进程对资源的访问。



1）**同一个JVM里的锁**，比如synchronized和Lock，ReentrantLock等等
2）**跨JVM的分布式锁**，因为服务是集群部署的，单机版的锁不再起作用，资源在不同的服务器之间共享。

## **分布式锁的由来**

- 在传统单机部署的情况下，可以使用Java并发处理相关的API(如`ReentrantLcok`或`synchronized`)进行互斥控制。

- 但是在分布式系统后，由于分布式系统**多线程、多进程**并且分布在**不同机器**上，这将使原单机并发控制锁策略失效，为了解决这个问题就需要一种跨JVM的互斥机制来控制共享资源的访问，这就是分布式锁的由来。

- 当多个进程不在同一个系统中，就需要用分布式锁控制**多个进程对资源的访问**。

## **分布式锁的具体实现**

**分布式锁一般有三种实现方式：**

1. 数据库乐观锁；

2. 基于ZooKeeper的分布式锁;
3. 基于Redis的分布式锁；

**Redis实现分布式锁**

- 基于Redis命令：SET key value NX EX max-lock-time
  - set k v NX EX 超时时间

- 这里补充下： 从2.6.12版本后, 就可以使用set来获取锁, Lua 脚本来释放锁。
- **setnx是老黄历了**，set命令nx,xx等参数, 是为了实现 setnx 的功能。

**1.加锁**

```Java
public class RedisTool {
    /**
    * 尝试获取分布式锁
    * @param jedis Redis客户端
    * @param lockKey 锁
    * @param requestId 请求标识
    * @param expireTime 超期时间
    * @return 是否获取成功
    */
    public static boolean tryGetDistributedLock(Jedis jedis, String lockKey, String requestId, int expireTime) {
        	String result = jedis.set(lockKey, requestId, "NX", "PX", expireTime);
            if ("OK".equals(result)) {
                return true;
            }
            return false;
        }
}
```

**这个set()方法一共有五个形参：**

- 第一个为key，我们使用key来当锁，因为key是唯一的。

- 第二个为value，我们传的是requestId，很多童鞋可能不明白，有key作为锁不就够了吗，为什么还要用到value？
  - 原因就是可靠性，通过给value赋值为requestId，我们就知道这把锁是哪个请求加的了
    - 一个线程可以有多个不同位置的锁
    - 在解锁的时候就可以有依据。
  - requestId可以使用`UUID.randomUUID().toString()`方法生成。

- 第三个为nxxx，这个参数我们填的是**NX，意思是SET IF NOT EXIST**，即当**key不存在时，我们进行set操作**；
  - 若key已经存在，则不做任何操作；

- 第四个为expx，这个参数我们传的是PX，意思是我们要给这个**key加一个过期的设置**，具体时间由第五个参数决定。

- 第五个为time，与第四个参数相呼应，代表key的过期时间。

总的来说，执行上面的set()方法就只会导致两种结果：

1. 当前没有锁（key不存在），那么**就进行加锁操作，并对锁设置个有效期**，同时value表示加锁的客户端。
2.  已有锁存在，不做任何操作。

**2.解锁**

```JAVA
public class RedisTool {
    private static final Long RELEASE_SUCCESS = 1L;
    /**
    * 释放分布式锁
    * @param jedis Redis客户端
    * @param lockKey 锁
    * @param requestId 请求标识
    * @return 是否释放成功
    */
    public static boolean lck(Jedis jedis, String lockKey, String requestId) {

    	String script = "if redis.call('get', KEYS[1]) == ARGV[1] then return redis.call('del', KEYS[1]) else return 0 end";
        Object result = jedis.eval(script, Collections.singletonList(lockKey),Collections.singletonList(requestId));
        if (RELEASE_SUCCESS.equals(result)) {
            return true;
        }
        return false;
    }
}
```

那么这段Lua代码的功能是什么呢？

- 其实很简单，首先获取锁对应的value值，检查是否与`requestId`相等，如果相等则删除锁（解锁）。

以上就是redis实现分布式锁详解，除此之外，也可以使用Redission(Redis 的客户端)集成进来实现分布式锁，也可以使用数据库等